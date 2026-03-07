# 04C - Base Geográfica Própria (PostGIS + OSM)

> Importar dados do OpenStreetMap (.osm.pbf) para PostgreSQL/PostGIS,
> criando uma base geográfica própria para enriquecer rotas, geocoding reverso,
> nomes de ruas, POIs, limites de velocidade, e mais.
>
> **Não substitui o GraphHopper** (que continua fazendo roteamento em memória).
> É **complementar**: GraphHopper roteia, PostGIS enriquece.

---

## 1. Arquitetura: GraphHopper + PostGIS

```text
┌─────────────────────────────────────────────────────────┐
│                    .osm.pbf (Brasil)                    │
└────────────┬─────────────────────────┬──────────────────┘
             │                         │
      GraphHopper import          osm2pgsql import
             │                         │
             ▼                         ▼
┌────────────────────┐    ┌──────────────────────────────┐
│  Grafo CH (memória) │    │   PostgreSQL / PostGIS       │
│  → Roteamento       │    │   → Nomes de ruas            │
│  → Matrix API       │    │   → POIs (postos, etc.)      │
│  → Routing API      │    │   → Limites de velocidade    │
│                     │    │   → Geocoding reverso         │
│                     │    │   → Áreas de restrição        │
│                     │    │   → Enriquecer incidentes     │
└────────────────────┘    └──────────────────────────────┘
```

| Responsabilidade | Quem faz |
|-----------------|----------|
| Roteamento (A→B, matrix, geometry) | **GraphHopper** (grafo CH em memória) |
| Nomes de ruas no trajeto | **PostGIS** (`SELECT name FROM osm_roads WHERE ST_Intersects(...)`) |
| POIs próximos à rota | **PostGIS** (query espacial) |
| Limites de velocidade por trecho | **PostGIS** (`maxspeed` tag) |
| Geocoding reverso (lat/lon → endereço) | **PostGIS** (Nominatim ou query direta) |
| Áreas de restrição (ZPA, zonas) | **PostGIS** (polygons) |
| Enriquecer incidentes com nome da via | **PostGIS** |
| Dashboard com mapa de cobertura | **PostGIS** (tiles, heatmaps) |

---

## 2. Ferramenta: osm2pgsql

**osm2pgsql** é a ferramenta padrão para importar dados OSM no PostgreSQL/PostGIS. Open-source, maduro, usado pelo próprio openstreetmap.org.

- **Site**: [osm2pgsql.org](https://osm2pgsql.org/)
- **Instalação**: `apt install osm2pgsql` (Ubuntu/Debian) ou `brew install osm2pgsql` (macOS)
- **Modos**:
  - `create` — import completo (primeira vez)
  - `append` — atualização incremental (diffs `.osc`)

---

## 3. Schema PostGIS (o que importar)

### 3.1 Estratégia: importar TUDO (sem filtro)

Importamos **todos** os dados do PBF para não perder nada que possa ser útil no futuro. As tabelas são separadas por tipo de dado, mas nenhuma tag é descartada.

| Camada | Tags OSM | Tabela PostGIS | Uso atual / futuro | Tamanho estimado (Brasil) |
|--------|----------|---------------|-------------------|---------------------------|
| Rede viária | `highway=*` | `osm_roads` | Nomes, velocidade, tipo de via | ~15-20 GB |
| POIs | `amenity=*`, `shop=*`, `tourism=*` | `osm_pois` | Postos, restaurantes, hospitais | ~2-3 GB |
| Endereços | `addr:*` | `osm_addresses` | Geocoding reverso | ~3-5 GB |
| Limites administrativos | `boundary=administrative` | `osm_boundaries` | Município, estado, bairro | ~500 MB |
| Edifícios | `building=*` | `osm_buildings` | Footprint de prédios, entregas | ~15-25 GB |
| Uso do solo | `landuse=*`, `natural=*` | `osm_landuse` | Áreas verdes, industriais, rurais | ~3-5 GB |
| Hidrografia | `waterway=*`, `natural=water` | `osm_water` | Rios, lagos, represas | ~1-2 GB |
| Ferrovias | `railway=*` | `osm_railways` | Cruzamentos, passagens de nível | ~500 MB |
| Outros (catch-all) | Qualquer tag não mapeada acima | `osm_other` | Reserva para uso futuro | ~5-10 GB |
| **Total (sem filtro)** | | | | **~50-80 GB** |

### 3.2 Formato real do .osm.pbf → mapeamento para tabelas

O PBF contém 3 primitivos (Node, Way, Relation) com tags livres `chave=valor`. O mapeamento para tabelas é:

```text
OSM Way  + tag highway=*         →  geo.osm_roads     (LineString)
OSM Node + tag amenity/shop/...  →  geo.osm_pois      (Point)
OSM Node + tag addr:housenumber  →  geo.osm_addresses  (Point)
OSM Relation + tag boundary=adm  →  geo.osm_boundaries (MultiPolygon)
```

Tags são **strings** no OSM (inclusive `maxspeed`, `lanes`). O Lua transform converte para os tipos SQL corretos. Tags ausentes viram `NULL`.

### 3.3 Flyway migration (criar schema antes do import)

```sql
-- V004__create_osm_geographic_tables.sql

CREATE SCHEMA IF NOT EXISTS geo;

-- Rede viária (OSM Ways com tag highway=*)
-- Tags fonte: highway, name, ref, maxspeed, oneway, surface, lanes, bridge, tunnel, toll, access
CREATE TABLE geo.osm_roads (
    osm_id       BIGINT PRIMARY KEY,
    name         TEXT,                -- tag 'name' (~70% preenchido)
    highway      TEXT NOT NULL,       -- motorway, trunk, primary, secondary, tertiary, residential, ...
    ref          TEXT,                -- tag 'ref': BR-101, SP-280 (~20% rodovias)
    maxspeed     SMALLINT,           -- tag 'maxspeed' convertida p/ int (km/h, ~15% preenchido)
    oneway       BOOLEAN DEFAULT FALSE, -- tag 'oneway': yes→true, -1→true(invertido), no→false
    surface      TEXT,               -- tag 'surface': asphalt, paved, unpaved, gravel, dirt
    lanes        SMALLINT,           -- tag 'lanes' convertida p/ int
    bridge       BOOLEAN DEFAULT FALSE, -- tag 'bridge'=yes
    tunnel       BOOLEAN DEFAULT FALSE, -- tag 'tunnel'=yes
    toll         BOOLEAN DEFAULT FALSE, -- tag 'toll'=yes
    access       TEXT,               -- tag 'access': private, no, destination, customers
    geom         GEOMETRY(LineString, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_roads_geom ON geo.osm_roads USING GIST (geom);
CREATE INDEX idx_osm_roads_highway ON geo.osm_roads (highway);
CREATE INDEX idx_osm_roads_name ON geo.osm_roads USING GIN (name gin_trgm_ops);
CREATE INDEX idx_osm_roads_ref ON geo.osm_roads (ref) WHERE ref IS NOT NULL;

-- POIs (OSM Nodes com tag amenity, shop ou tourism)
-- Tags fonte: amenity, shop, tourism, name, brand, phone, opening_hours, website
CREATE TABLE geo.osm_pois (
    osm_id        BIGINT PRIMARY KEY,
    name          TEXT,
    amenity       TEXT,               -- fuel, restaurant, hospital, pharmacy, bank, school, police, parking
    shop          TEXT,               -- supermarket, convenience, bakery, butcher
    tourism       TEXT,               -- hotel, motel, hostel, attraction
    brand         TEXT,               -- Shell, Petrobras, BR, Ipiranga, Drogasil
    phone         TEXT,
    website       TEXT,
    opening_hours TEXT,               -- formato OSM: "Mo-Fr 08:00-18:00; Sa 08:00-12:00"
    geom          GEOMETRY(Point, 4326) NOT NULL,
    updated_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_pois_geom ON geo.osm_pois USING GIST (geom);
CREATE INDEX idx_osm_pois_amenity ON geo.osm_pois (amenity) WHERE amenity IS NOT NULL;
CREATE INDEX idx_osm_pois_brand ON geo.osm_pois (brand) WHERE brand IS NOT NULL;

-- Endereços (OSM Nodes com tag addr:housenumber)
-- Tags fonte: addr:housenumber, addr:street, addr:suburb, addr:city, addr:postcode, addr:state
CREATE TABLE geo.osm_addresses (
    osm_id       BIGINT PRIMARY KEY,
    housenumber  TEXT,               -- tag 'addr:housenumber': "1500", "123A"
    street       TEXT,               -- tag 'addr:street'
    suburb       TEXT,               -- tag 'addr:suburb' (bairro no Brasil)
    city         TEXT,               -- tag 'addr:city'
    postcode     TEXT,               -- tag 'addr:postcode': "01001-000"
    state        TEXT,               -- tag 'addr:state': "SP", "RJ"
    geom         GEOMETRY(Point, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_addresses_geom ON geo.osm_addresses USING GIST (geom);
CREATE INDEX idx_osm_addresses_street ON geo.osm_addresses USING GIN (street gin_trgm_ops);
CREATE INDEX idx_osm_addresses_postcode ON geo.osm_addresses (postcode) WHERE postcode IS NOT NULL;

-- Limites administrativos (OSM Relations com tag boundary=administrative)
-- Tags fonte: boundary, admin_level, name
-- admin_level: 2=país, 4=estado, 6=mesorregião, 8=município
CREATE TABLE geo.osm_boundaries (
    osm_id       BIGINT PRIMARY KEY,
    name         TEXT NOT NULL,
    admin_level  SMALLINT,
    boundary     TEXT,
    geom         GEOMETRY(MultiPolygon, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_boundaries_geom ON geo.osm_boundaries USING GIST (geom);
CREATE INDEX idx_osm_boundaries_level ON geo.osm_boundaries (admin_level);

-- Edifícios (OSM Ways com tag building=*)
-- Tags fonte: building, name, addr:*, height, building:levels
CREATE TABLE geo.osm_buildings (
    osm_id           BIGINT PRIMARY KEY,
    name             TEXT,
    building         TEXT NOT NULL,      -- yes, residential, commercial, industrial, church, school
    housenumber      TEXT,               -- tag 'addr:housenumber'
    street           TEXT,               -- tag 'addr:street'
    height           TEXT,               -- tag 'height': "12", "15 m"
    building_levels  SMALLINT,           -- tag 'building:levels'
    geom             GEOMETRY(Polygon, 4326) NOT NULL,
    updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_buildings_geom ON geo.osm_buildings USING GIST (geom);
CREATE INDEX idx_osm_buildings_type ON geo.osm_buildings (building);

-- Uso do solo (OSM Ways/Relations com tag landuse=* ou natural=*)
-- Tags fonte: landuse, natural, name, leisure
CREATE TABLE geo.osm_landuse (
    osm_id       BIGINT PRIMARY KEY,
    name         TEXT,
    landuse      TEXT,                -- residential, industrial, commercial, farmland, forest, meadow
    "natural"    TEXT,                -- wood, scrub, grassland, wetland, beach
    leisure      TEXT,                -- park, garden, pitch, playground
    geom         GEOMETRY(Geometry, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_landuse_geom ON geo.osm_landuse USING GIST (geom);

-- Hidrografia (OSM Ways com tag waterway=* ou natural=water)
-- Tags fonte: waterway, natural, name, width
CREATE TABLE geo.osm_water (
    osm_id       BIGINT PRIMARY KEY,
    name         TEXT,
    waterway     TEXT,                -- river, stream, canal, drain, ditch
    "natural"    TEXT,                -- water (lagos, represas)
    water        TEXT,                -- lake, reservoir, pond, river
    geom         GEOMETRY(Geometry, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_water_geom ON geo.osm_water USING GIST (geom);

-- Ferrovias (OSM Ways com tag railway=*)
-- Tags fonte: railway, name, electrified, gauge, service
CREATE TABLE geo.osm_railways (
    osm_id       BIGINT PRIMARY KEY,
    name         TEXT,
    railway      TEXT NOT NULL,       -- rail, subway, tram, light_rail, platform, station
    electrified  TEXT,                -- yes, no, contact_line
    gauge        TEXT,                -- 1000, 1600
    service      TEXT,                -- spur, yard, siding
    bridge       BOOLEAN DEFAULT FALSE,
    tunnel       BOOLEAN DEFAULT FALSE,
    geom         GEOMETRY(Geometry, 4326) NOT NULL,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osm_railways_geom ON geo.osm_railways USING GIST (geom);

-- Catch-all: qualquer Way/Node/Relation com tags não capturadas acima
-- Armazena tags como JSONB para não perder nada
CREATE TABLE geo.osm_other (
    osm_id       BIGINT NOT NULL,
    osm_type     TEXT NOT NULL,       -- 'node', 'way', 'relation'
    tags         JSONB NOT NULL,      -- todas as tags do elemento
    geom         GEOMETRY(Geometry, 4326),
    updated_at   TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (osm_id, osm_type)
);

CREATE INDEX idx_osm_other_geom ON geo.osm_other USING GIST (geom) WHERE geom IS NOT NULL;
CREATE INDEX idx_osm_other_tags ON geo.osm_other USING GIN (tags);

-- Controle de importação
CREATE TABLE geo.osm_import_log (
    id           BIGSERIAL PRIMARY KEY,
    source_file  TEXT NOT NULL,
    import_type  TEXT NOT NULL,       -- 'full' ou 'diff'
    started_at   TIMESTAMPTZ NOT NULL,
    finished_at  TIMESTAMPTZ,
    rows_roads   INTEGER,
    rows_pois    INTEGER,
    rows_addr    INTEGER,
    status       TEXT DEFAULT 'running'  -- running, success, failed
);
```

### 3.4 Lua transform — importação COMPLETA (sem filtro, sem perder nada)

Cada elemento OSM cai na tabela **mais específica** que couber. Se não couber em nenhuma, vai para `osm_other` com todas as tags em **JSONB** — assim nada é descartado.

```lua
-- infra/osm2pgsql/osm2pgsql-flex.lua
-- Import COMPLETO: todo elemento do PBF é salvo em alguma tabela.
-- Tabelas tipadas: roads, pois, addresses, boundaries, buildings, landuse, water, railways
-- Catch-all: osm_other (tags em JSONB)

local json = require('dkjson')  -- osm2pgsql inclui dkjson

-- ========== DEFINIÇÃO DAS TABELAS ==========

local roads = osm2pgsql.define_way_table('osm_roads', {
    { column = 'name',     type = 'text' },
    { column = 'highway',  type = 'text', not_null = true },
    { column = 'ref',      type = 'text' },
    { column = 'maxspeed', type = 'int' },
    { column = 'oneway',   type = 'bool' },
    { column = 'surface',  type = 'text' },
    { column = 'lanes',    type = 'int' },
    { column = 'bridge',   type = 'bool' },
    { column = 'tunnel',   type = 'bool' },
    { column = 'toll',     type = 'bool' },
    { column = 'access',   type = 'text' },
    { column = 'geom',     type = 'linestring', srid = 4326 },
}, { schema = 'geo' })

local buildings = osm2pgsql.define_way_table('osm_buildings', {
    { column = 'name',            type = 'text' },
    { column = 'building',        type = 'text', not_null = true },
    { column = 'housenumber',     type = 'text' },
    { column = 'street',          type = 'text' },
    { column = 'height',          type = 'text' },
    { column = 'building_levels', type = 'int' },
    { column = 'geom',            type = 'polygon', srid = 4326 },
}, { schema = 'geo' })

local landuse = osm2pgsql.define_way_table('osm_landuse', {
    { column = 'name',    type = 'text' },
    { column = 'landuse', type = 'text' },
    { column = 'natural', type = 'text' },
    { column = 'leisure', type = 'text' },
    { column = 'geom',    type = 'geometry', srid = 4326 },
}, { schema = 'geo' })

local water = osm2pgsql.define_way_table('osm_water', {
    { column = 'name',     type = 'text' },
    { column = 'waterway', type = 'text' },
    { column = 'natural',  type = 'text' },
    { column = 'water',    type = 'text' },
    { column = 'geom',     type = 'geometry', srid = 4326 },
}, { schema = 'geo' })

local railways = osm2pgsql.define_way_table('osm_railways', {
    { column = 'name',        type = 'text' },
    { column = 'railway',     type = 'text', not_null = true },
    { column = 'electrified', type = 'text' },
    { column = 'gauge',       type = 'text' },
    { column = 'service',     type = 'text' },
    { column = 'bridge',      type = 'bool' },
    { column = 'tunnel',      type = 'bool' },
    { column = 'geom',        type = 'geometry', srid = 4326 },
}, { schema = 'geo' })

local pois = osm2pgsql.define_node_table('osm_pois', {
    { column = 'name',          type = 'text' },
    { column = 'amenity',       type = 'text' },
    { column = 'shop',          type = 'text' },
    { column = 'tourism',       type = 'text' },
    { column = 'brand',         type = 'text' },
    { column = 'phone',         type = 'text' },
    { column = 'website',       type = 'text' },
    { column = 'opening_hours', type = 'text' },
    { column = 'geom',          type = 'point', srid = 4326 },
}, { schema = 'geo' })

local addresses = osm2pgsql.define_node_table('osm_addresses', {
    { column = 'housenumber', type = 'text' },
    { column = 'street',      type = 'text' },
    { column = 'suburb',      type = 'text' },
    { column = 'city',        type = 'text' },
    { column = 'postcode',    type = 'text' },
    { column = 'state',       type = 'text' },
    { column = 'geom',        type = 'point', srid = 4326 },
}, { schema = 'geo' })

local boundaries = osm2pgsql.define_relation_table('osm_boundaries', {
    { column = 'name',        type = 'text', not_null = true },
    { column = 'admin_level', type = 'int' },
    { column = 'boundary',    type = 'text' },
    { column = 'geom',        type = 'multipolygon', srid = 4326 },
}, { schema = 'geo' })

-- Catch-all: tudo que não couber nas tabelas acima
local other_nodes = osm2pgsql.define_node_table('osm_other', {
    { column = 'osm_type', type = 'text', not_null = true },
    { column = 'tags',     type = 'jsonb', not_null = true },
    { column = 'geom',     type = 'point', srid = 4326 },
}, { schema = 'geo' })

local other_ways = osm2pgsql.define_way_table('osm_other_ways', {
    { column = 'osm_type', type = 'text', not_null = true },
    { column = 'tags',     type = 'jsonb', not_null = true },
    { column = 'geom',     type = 'geometry', srid = 4326 },
}, { schema = 'geo' })

local other_rels = osm2pgsql.define_relation_table('osm_other_rels', {
    { column = 'osm_type', type = 'text', not_null = true },
    { column = 'tags',     type = 'jsonb', not_null = true },
    { column = 'geom',     type = 'geometry', srid = 4326 },
}, { schema = 'geo' })

-- ========== HELPERS ==========

local function tags_to_json(tags)
    return json.encode(tags)
end

local function has_any_tag(tags)
    for _ in pairs(tags) do return true end
    return false
end

-- ========== PROCESS WAY ==========

function osm2pgsql.process_way(object)
    local t = object.tags
    if not has_any_tag(t) then return end

    -- Rodovia
    if t.highway then
        local oneway_tag = t.oneway
        roads:insert({
            name     = t.name,
            highway  = t.highway,
            ref      = t.ref,
            maxspeed = tonumber(t.maxspeed),
            oneway   = (oneway_tag == 'yes' or oneway_tag == '-1'),
            surface  = t.surface,
            lanes    = tonumber(t.lanes),
            bridge   = t.bridge == 'yes',
            tunnel   = t.tunnel == 'yes',
            toll     = t.toll == 'yes',
            access   = t.access,
            geom     = object:as_linestring()
        })
        return
    end

    -- Edifício
    if t.building then
        buildings:insert({
            name            = t.name,
            building        = t.building,
            housenumber     = t['addr:housenumber'],
            street          = t['addr:street'],
            height          = t.height,
            building_levels = tonumber(t['building:levels']),
            geom            = object:as_polygon()
        })
        return
    end

    -- Ferrovia
    if t.railway then
        railways:insert({
            name        = t.name,
            railway     = t.railway,
            electrified = t.electrified,
            gauge       = t.gauge,
            service     = t.service,
            bridge      = t.bridge == 'yes',
            tunnel      = t.tunnel == 'yes',
            geom        = object:as_linestring()
        })
        return
    end

    -- Hidrografia
    if t.waterway or (t['natural'] == 'water') then
        water:insert({
            name     = t.name,
            waterway = t.waterway,
            natural  = t['natural'],
            water    = t.water,
            geom     = object:as_linestring()
        })
        return
    end

    -- Uso do solo
    if t.landuse or t['natural'] or t.leisure then
        landuse:insert({
            name    = t.name,
            landuse = t.landuse,
            natural = t['natural'],
            leisure = t.leisure,
            geom    = object:as_polygon()
        })
        return
    end

    -- Catch-all: Way não classificada
    other_ways:insert({
        osm_type = 'way',
        tags     = tags_to_json(t),
        geom     = object:as_linestring()
    })
end

-- ========== PROCESS NODE ==========

function osm2pgsql.process_node(object)
    local t = object.tags
    if not has_any_tag(t) then return end

    local matched = false

    -- POI
    if t.amenity or t.shop or t.tourism then
        pois:insert({
            name          = t.name,
            amenity       = t.amenity,
            shop          = t.shop,
            tourism       = t.tourism,
            brand         = t.brand,
            phone         = t.phone,
            website       = t.website,
            opening_hours = t.opening_hours,
            geom          = object:as_point()
        })
        matched = true
    end

    -- Endereço (um Node pode ser POI E endereço ao mesmo tempo)
    if t['addr:housenumber'] then
        addresses:insert({
            housenumber = t['addr:housenumber'],
            street      = t['addr:street'],
            suburb      = t['addr:suburb'],
            city        = t['addr:city'],
            postcode    = t['addr:postcode'],
            state       = t['addr:state'],
            geom        = object:as_point()
        })
        matched = true
    end

    -- Catch-all: Node não classificado
    if not matched then
        other_nodes:insert({
            osm_type = 'node',
            tags     = tags_to_json(t),
            geom     = object:as_point()
        })
    end
end

-- ========== PROCESS RELATION ==========

function osm2pgsql.process_relation(object)
    local t = object.tags
    if not has_any_tag(t) then return end

    -- Limites administrativos
    if t.boundary == 'administrative' and t.name then
        boundaries:insert({
            name        = t.name,
            admin_level = tonumber(t.admin_level),
            boundary    = t.boundary,
            geom        = object:as_multipolygon()
        })
        return
    end

    -- Catch-all: Relation não classificada
    other_rels:insert({
        osm_type = 'relation',
        tags     = tags_to_json(t),
        geom     = object:as_multipolygon()
    })
end
```

---

## 4. Processo de importação

### 4.1 Import completo (primeira vez) — RDS PostgreSQL

```bash
# 1. Habilitar extensões no RDS (conectar via psql ou bastion)
#    PostGIS já vem disponível no RDS, só precisa ativar:
PGPASSWORD="$DB_PASS" psql -h routing-db.xxxxx.sa-east-1.rds.amazonaws.com \
  -U routing_app -d routing -c "
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
  "

# 2. Rodar Flyway migration (criar schema + tabelas)
./mvnw flyway:migrate

# 3. O import é feito pelo CodeBuild dentro da VPC (ver seção 5)
#    Para import manual (dev/teste), conectar via bastion ou VPN:
osm2pgsql \
  --create \
  --output=flex \
  --style=osm2pgsql-flex.lua \
  --database=routing \
  --host=routing-db.xxxxx.sa-east-1.rds.amazonaws.com \
  --port=5432 \
  --user=routing_app \
  --cache=4096 \
  --number-processes=4 \
  --log-progress=true \
  brazil-latest.osm.pbf
```

**Tempo estimado (Brasil, sem filtro, dentro da VPC)**: ~60-120 min | **RAM**: ~8 GB | **Disco RDS**: ~60-95 GB (filtrado)

### 4.2 Atualização incremental (diffs semanais)

O Geofabrik publica **diffs** (`.osc.gz`) que contêm apenas as mudanças desde o último export. O osm2pgsql aplica esses diffs sem reimportar tudo.

Em produção, isso é feito automaticamente pelo **GitHub Actions + CodeBuild** (ver seção 5.6).

**Tempo**: ~10-20 min dentro da VPC | **RAM**: ~4 GB

---

## 5. Pipeline para AWS RDS PostgreSQL

### 5.1 Por que não rodar osm2pgsql direto do GitHub Actions

O import gera ~60-95 GB de dados no RDS. Se o GitHub Actions runner (fora da AWS) conectar direto no RDS:
- **RDS teria que ser público** (inseguro).
- **Latência de rede** entre GitHub e AWS tornaria o import ~5-10× mais lento.
- **Timeout do runner** (6h) pode não bastar para import completo via internet.

### 5.2 Arquitetura: GitHub Actions → S3 → CodeBuild (dentro da VPC)

```text
GitHub Actions                          AWS (sua VPC)
┌──────────────┐                       ┌────────────────────────────────┐
│ 1. Baixa .pbf│                       │                                │
│    Geofabrik  │                       │  ┌──────────────┐             │
│ 2. Upload S3 ─┼──── .pbf ──────────►│  │  CodeBuild    │             │
│ 3. Trigger   ─┼──── start-build ───►│  │  (osm2pgsql)  │             │
│    CodeBuild  │                       │  │              ─┼──► RDS PG  │
│ 4. Poll status│◄──── status ────────│  └──────────────┘             │
└──────────────┘                       │     (mesma VPC, rede interna)  │
                                       └────────────────────────────────┘
```

**CodeBuild** roda **dentro da VPC**, com acesso direto ao RDS via rede interna (sem expor o RDS à internet). GitHub Actions só orquestra.

### 5.3 Pré-requisitos AWS (criar uma vez)

#### a) Bucket S3

```bash
aws s3 mb s3://routing-data --region sa-east-1
```

#### b) CodeBuild Project (Terraform ou CLI)

```bash
aws codebuild create-project \
  --name osm-postgis-import \
  --source '{"type":"NO_SOURCE","buildspec":"version: 0.2\nphases:\n  build:\n    commands:\n      - echo see buildspec in S3"}' \
  --artifacts '{"type":"NO_ARTIFACTS"}' \
  --environment '{
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
    "computeType": "BUILD_GENERAL1_LARGE",
    "privilegedMode": false,
    "environmentVariables": [
      {"name":"DB_HOST","value":"/routing/rds/host","type":"PARAMETER_STORE"},
      {"name":"DB_NAME","value":"/routing/rds/dbname","type":"PARAMETER_STORE"},
      {"name":"DB_USER","value":"/routing/rds/user","type":"PARAMETER_STORE"},
      {"name":"DB_PASS","value":"/routing/rds/password","type":"PARAMETER_STORE"}
    ]
  }' \
  --service-role arn:aws:iam::ACCOUNT_ID:role/codebuild-routing-role \
  --vpc-config '{
    "vpcId": "vpc-XXXXXXXX",
    "subnets": ["subnet-XXXXXXXX"],
    "securityGroupIds": ["sg-XXXXXXXX"]
  }' \
  --timeout-in-minutes 180 \
  --region sa-east-1
```

**Pontos importantes**:
- `computeType: BUILD_GENERAL1_LARGE` → 8 vCPU, 15 GB RAM (suficiente para osm2pgsql).
- `vpc-config` → mesmo VPC e subnets do RDS (acesso direto, sem internet).
- Credenciais do RDS via **Parameter Store** (seguro, sem secrets no código).
- `timeout: 180 min` → suficiente para import completo.

#### c) IAM Role para CodeBuild

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::routing-data", "arn:aws:s3:::routing-data/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["ssm:GetParameters", "ssm:GetParameter"],
      "Resource": "arn:aws:ssm:sa-east-1:ACCOUNT_ID:parameter/routing/rds/*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces",
                  "ec2:DeleteNetworkInterface", "ec2:DescribeSubnets",
                  "ec2:DescribeSecurityGroups", "ec2:DescribeVpcs"],
      "Resource": "*"
    }
  ]
}
```

#### d) Parameter Store (credenciais do RDS)

```bash
aws ssm put-parameter --name /routing/rds/host     --value "routing-db.xxxxxxx.sa-east-1.rds.amazonaws.com" --type SecureString
aws ssm put-parameter --name /routing/rds/dbname   --value "routing" --type String
aws ssm put-parameter --name /routing/rds/user     --value "routing_app" --type String
aws ssm put-parameter --name /routing/rds/password  --value "SENHA_SEGURA" --type SecureString
```

#### e) Security Group do RDS

O SG do RDS precisa permitir ingress na porta 5432 vindo do SG do CodeBuild:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-RDS_SG_ID \
  --protocol tcp --port 5432 \
  --source-group sg-CODEBUILD_SG_ID
```

### 5.4 Buildspec (o que o CodeBuild executa)

```yaml
# infra/codebuild/osm-import-buildspec.yml
version: 0.2

env:
  parameter-store:
    DB_HOST: /routing/rds/host
    DB_NAME: /routing/rds/dbname
    DB_USER: /routing/rds/user
    DB_PASS: /routing/rds/password

phases:
  install:
    runtime-versions:
      python: 3.12
    commands:
      - yum install -y osm2pgsql postgresql15
      - pip install osmium

  pre_build:
    commands:
      - echo "Downloading files from S3..."
      - aws s3 cp s3://routing-data/osm/brazil-latest.osm.pbf /tmp/brazil.osm.pbf
      - aws s3 cp s3://routing-data/osm/osm2pgsql-flex.lua /tmp/osm2pgsql-flex.lua
      - ls -lh /tmp/brazil.osm.pbf
      - echo "Testing RDS connectivity..."
      - PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;"

  build:
    commands:
      - echo "Starting import at $(date)"
      - |
        if [ "$IMPORT_TYPE" = "full" ]; then
          echo "=== FULL IMPORT ==="
          PGPASSWORD="$DB_PASS" osm2pgsql \
            --create \
            --output=flex \
            --style=/tmp/osm2pgsql-flex.lua \
            --database="$DB_NAME" \
            --host="$DB_HOST" \
            --user="$DB_USER" \
            --cache=8192 \
            --number-processes=6 \
            --log-progress=true \
            /tmp/brazil.osm.pbf
        else
          echo "=== DIFF UPDATE ==="
          aws s3 cp s3://routing-data/osm/brazil-diff.osc.gz /tmp/brazil-diff.osc.gz
          PGPASSWORD="$DB_PASS" osm2pgsql \
            --append \
            --output=flex \
            --style=/tmp/osm2pgsql-flex.lua \
            --database="$DB_NAME" \
            --host="$DB_HOST" \
            --user="$DB_USER" \
            --cache=4096 \
            /tmp/brazil-diff.osc.gz
        fi

  post_build:
    commands:
      - echo "Running ANALYZE..."
      - |
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "
          ANALYZE geo.osm_roads;
          ANALYZE geo.osm_pois;
          ANALYZE geo.osm_addresses;
          ANALYZE geo.osm_boundaries;
          ANALYZE geo.osm_buildings;
          ANALYZE geo.osm_landuse;
          ANALYZE geo.osm_water;
          ANALYZE geo.osm_railways;
        "
      - |
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "
          INSERT INTO geo.osm_import_log
            (source_file, import_type, started_at, finished_at, status)
          VALUES
            ('$SOURCE_FILE', '$IMPORT_TYPE', now() - interval '2 hours', now(), 'success');
        "
      - echo "Import finished at $(date)"
```

### 5.5 GitHub Actions — Orquestrador (import completo mensal)

```yaml
# .github/workflows/osm-postgis-full-import.yml
name: OSM Full Import to RDS PostGIS

on:
  schedule:
    - cron: '0 5 1 * *'   # dia 1 de cada mês às 05:00 UTC
  workflow_dispatch:

env:
  S3_BUCKET: routing-data
  GEOFABRIK_URL: https://download.geofabrik.de/south-america/brazil-latest.osm.pbf
  AWS_REGION: sa-east-1
  CODEBUILD_PROJECT: osm-postgis-import

jobs:
  upload-and-import:
    runs-on: ubuntu-latest
    timeout-minutes: 240

    steps:
      - name: Checkout (Lua transform + buildspec)
        uses: actions/checkout@v4
        with:
          sparse-checkout: |
            infra/osm2pgsql
            infra/codebuild

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Download .osm.pbf from Geofabrik
        run: |
          curl -L -o /tmp/brazil.osm.pbf "$GEOFABRIK_URL"
          ls -lh /tmp/brazil.osm.pbf

      - name: Upload .pbf + Lua transform to S3
        run: |
          aws s3 cp /tmp/brazil.osm.pbf s3://$S3_BUCKET/osm/brazil-latest.osm.pbf
          aws s3 cp infra/osm2pgsql/osm2pgsql-flex.lua s3://$S3_BUCKET/osm/osm2pgsql-flex.lua
          echo "Upload completo"

      - name: Trigger CodeBuild (import dentro da VPC)
        id: codebuild
        run: |
          BUILD_ID=$(aws codebuild start-build \
            --project-name "$CODEBUILD_PROJECT" \
            --buildspec-override "$(cat infra/codebuild/osm-import-buildspec.yml)" \
            --environment-variables-override \
              "name=IMPORT_TYPE,value=full,type=PLAINTEXT" \
              "name=SOURCE_FILE,value=brazil-latest.osm.pbf,type=PLAINTEXT" \
            --query 'build.id' --output text)
          echo "build_id=$BUILD_ID" >> "$GITHUB_OUTPUT"
          echo "CodeBuild started: $BUILD_ID"

      - name: Wait for CodeBuild to finish
        run: |
          BUILD_ID="${{ steps.codebuild.outputs.build_id }}"
          echo "Polling build $BUILD_ID..."
          while true; do
            STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" \
              --query 'builds[0].buildStatus' --output text)
            echo "$(date): Status = $STATUS"
            if [ "$STATUS" = "SUCCEEDED" ]; then
              echo "Build succeeded!"
              break
            elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ] || [ "$STATUS" = "TIMED_OUT" ]; then
              echo "Build failed with status: $STATUS"
              aws codebuild batch-get-builds --ids "$BUILD_ID" \
                --query 'builds[0].phases[?phaseStatus!=`SUCCEEDED`]' --output table
              exit 1
            fi
            sleep 60
          done

      - name: Cleanup S3
        if: always()
        run: |
          aws s3 rm s3://$S3_BUCKET/osm/brazil-latest.osm.pbf
          rm -f /tmp/brazil.osm.pbf
```

### 5.6 GitHub Actions — Orquestrador (diff semanal)

```yaml
# .github/workflows/osm-postgis-diff.yml
name: OSM Diff Update RDS PostGIS

on:
  schedule:
    - cron: '0 5 * * 0'   # todo domingo às 05:00 UTC
  workflow_dispatch:

env:
  S3_BUCKET: routing-data
  AWS_REGION: sa-east-1
  CODEBUILD_PROJECT: osm-postgis-import

jobs:
  diff-update:
    runs-on: ubuntu-latest
    timeout-minutes: 60

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          sparse-checkout: |
            infra/osm2pgsql
            infra/codebuild

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Download latest diff from Geofabrik
        run: |
          pip install osmium
          python3 -c "
          import urllib.request
          state_url = 'https://download.geofabrik.de/south-america/brazil-updates/state.txt'
          resp = urllib.request.urlopen(state_url).read().decode()
          seq = int([l for l in resp.split('\n') if l.startswith('sequenceNumber')][0].split('=')[1])
          path = f'{seq // 1000000:03d}/{(seq // 1000) % 1000:03d}/{seq % 1000:03d}'
          url = f'https://download.geofabrik.de/south-america/brazil-updates/{path}.osc.gz'
          print(f'Downloading: {url}')
          urllib.request.urlretrieve(url, '/tmp/brazil-diff.osc.gz')
          with open('/tmp/diff-name.txt', 'w') as f: f.write(f'{path}.osc.gz')
          "

      - name: Upload diff + Lua to S3
        run: |
          aws s3 cp /tmp/brazil-diff.osc.gz s3://$S3_BUCKET/osm/brazil-diff.osc.gz
          aws s3 cp infra/osm2pgsql/osm2pgsql-flex.lua s3://$S3_BUCKET/osm/osm2pgsql-flex.lua

      - name: Trigger CodeBuild (diff dentro da VPC)
        id: codebuild
        run: |
          DIFF_NAME=$(cat /tmp/diff-name.txt)
          BUILD_ID=$(aws codebuild start-build \
            --project-name "$CODEBUILD_PROJECT" \
            --buildspec-override "$(cat infra/codebuild/osm-import-buildspec.yml)" \
            --environment-variables-override \
              "name=IMPORT_TYPE,value=diff,type=PLAINTEXT" \
              "name=SOURCE_FILE,value=$DIFF_NAME,type=PLAINTEXT" \
            --query 'build.id' --output text)
          echo "build_id=$BUILD_ID" >> "$GITHUB_OUTPUT"
          echo "CodeBuild started: $BUILD_ID"

      - name: Wait for CodeBuild
        run: |
          BUILD_ID="${{ steps.codebuild.outputs.build_id }}"
          while true; do
            STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" \
              --query 'builds[0].buildStatus' --output text)
            echo "$(date): Status = $STATUS"
            if [ "$STATUS" = "SUCCEEDED" ]; then break; fi
            if [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ]; then
              echo "Build failed: $STATUS"; exit 1
            fi
            sleep 30
          done

      - name: Cleanup S3
        if: always()
        run: aws s3 rm s3://$S3_BUCKET/osm/brazil-diff.osc.gz
```

### 5.7 Secrets e variáveis no GitHub

| Secret / Variable | Valor | Onde |
|-------------------|-------|------|
| `AWS_ACCESS_KEY_ID` | Access key da IAM user/role | GitHub Secrets |
| `AWS_SECRET_ACCESS_KEY` | Secret key | GitHub Secrets |
| `AWS_REGION` | `sa-east-1` | GitHub Variables |

As credenciais do RDS **não ficam no GitHub** — ficam no **AWS Parameter Store** e são lidas pelo CodeBuild dentro da VPC.

---

## 6. Queries úteis (exemplos de enriquecimento)

### Nome da rua de um ponto GPS

```sql
SELECT name, highway, ref, maxspeed
FROM geo.osm_roads
WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326), 0.0005)
ORDER BY ST_Distance(geom, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326))
LIMIT 1;
```

### POIs num raio de 500m de um ponto

```sql
SELECT name, amenity, shop,
       ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography) AS dist_m
FROM geo.osm_pois
WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography, 500)
ORDER BY dist_m;
```

### Limite de velocidade de um segmento da rota

```sql
SELECT name, maxspeed, highway
FROM geo.osm_roads
WHERE ST_Intersects(geom, ST_GeomFromGeoJSON(:route_segment_geojson))
  AND maxspeed IS NOT NULL;
```

### Geocoding reverso (lat/lon → endereço)

```sql
SELECT housenumber, street, city, postcode
FROM geo.osm_addresses
WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 50)
ORDER BY ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography)
LIMIT 1;
```

### Município de um ponto

```sql
SELECT name
FROM geo.osm_boundaries
WHERE admin_level = 8
  AND ST_Contains(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326));
```

### Enriquecer incidente com nome da via

```sql
SELECT r.name, r.highway, r.ref
FROM geo.osm_roads r
WHERE ST_DWithin(r.geom, ST_SetSRID(ST_MakePoint(:incident_lon, :incident_lat), 4326), 0.0003)
ORDER BY ST_Distance(r.geom, ST_SetSRID(ST_MakePoint(:incident_lon, :incident_lat), 4326))
LIMIT 1;
```

---

## 7. Integração com o routing-engine (Spring Boot)

### Repository (Spring Data JPA + PostGIS)

```java
package com.example.routing.infrastructure.persistence.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface OsmRoadRepository extends JpaRepository<OsmRoadEntity, Long> {

    @Query(value = """
        SELECT * FROM geo.osm_roads
        WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), 0.0005)
        ORDER BY ST_Distance(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
        LIMIT 1
        """, nativeQuery = true)
    Optional<OsmRoadEntity> findNearestRoad(@Param("lat") double lat, @Param("lon") double lon);

    @Query(value = """
        SELECT * FROM geo.osm_roads
        WHERE ST_Intersects(geom, ST_GeomFromText(:wkt, 4326))
          AND maxspeed IS NOT NULL
        """, nativeQuery = true)
    List<OsmRoadEntity> findRoadsWithSpeedLimit(@Param("wkt") String routeWkt);
}
```

### Casos de uso no pipeline

| Momento | O que consultar | Latência |
|---------|----------------|----------|
| Após gerar rota (Fase 2) | Nomes das ruas de cada segmento | ~5-10 ms (GIST index) |
| Ao reportar incidente | Nome da via + município | ~2-5 ms |
| ETA display no frontend | Próximas ruas, próximo POI (posto) | ~5 ms |
| Chegada no destino | Endereço (geocoding reverso) | ~2-5 ms |

---

## 8. Sizing e manutenção

| Métrica | Valor (Brasil, import completo sem filtro) |
|---------|---------------------------------------------|
| Disco ocupado (dados) | ~50-80 GB |
| Disco ocupado (índices GIST + GIN) | ~10-15 GB |
| **Disco total** | **~60-95 GB** |
| Import completo | ~60-120 min |
| Diff semanal | ~10-20 min |
| Crescimento mensal | ~1-2% (OSM é estável) |
| RAM recomendada (shared_buffers) | ~8 GB |

### Configuração PostgreSQL recomendada (import completo)

```
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 512MB
maintenance_work_mem = 4GB          # para ANALYZE e index rebuild (tabelas grandes)
max_parallel_workers_per_gather = 4 # parallel seq scan em tabelas grandes
max_wal_size = 4GB                  # evita checkpoints frequentes durante import
```

---

## 9. Cronograma das pipelines

```text
Domingo 04:00 UTC  →  GitHub Actions: graphhopper-build.yml
                      (baixa .pbf, gera grafo CH, upload S3)

Domingo 05:00 UTC  →  GitHub Actions: osm-postgis-diff.yml
                      (baixa diff, upload S3, trigger CodeBuild na VPC → aplica no RDS)

Dia 1 do mês 05:00 →  GitHub Actions: osm-postgis-full-import.yml
                      (baixa .pbf, upload S3, trigger CodeBuild na VPC → reimport completo no RDS)
```

**Separação de responsabilidades**:
- **GitHub Actions** → orquestração (download, upload S3, trigger, polling).
- **CodeBuild (VPC)** → execução pesada (osm2pgsql contra o RDS, rede interna).
- **RDS** → nunca exposto à internet; só acessível pelo CodeBuild e pelos serviços na VPC.
- **Credenciais do RDS** → AWS Parameter Store (não ficam no GitHub).

---

## 10. Estrutura de arquivos no repositório

- **Módulo skeleton:** código em `skeleton/src/main/java/com/example/routing/`; migrations em `skeleton/src/main/resources/db/migration/`.
- **Módulo pilot:** código em `pilot/src/main/java/com/infocaltechnologies/pilot/`; migrations em `pilot/src/main/resources/db/migration/`.

```text
infra/
├── osm2pgsql/
│   └── osm2pgsql-flex.lua              # Lua transform (import completo, sem filtro)
├── codebuild/
│   └── osm-import-buildspec.yml        # Buildspec do CodeBuild (osm2pgsql → RDS)
├── graphhopper/
│   └── config.yml                      # Config do GraphHopper (profiles, CH)
├── iam/
│   └── codebuild-routing-policy.json   # IAM policy para CodeBuild (S3, SSM, VPC)
.github/
├── workflows/
│   ├── graphhopper-build.yml           # Build grafo CH → S3 (semanal)
│   ├── osm-postgis-full-import.yml     # Orquestrador: .pbf → S3 → CodeBuild → RDS (mensal)
│   └── osm-postgis-diff.yml            # Orquestrador: diff → S3 → CodeBuild → RDS (semanal)
skeleton/src/main/resources/db/migration/
│   └── V004__create_osm_geographic_tables.sql
pilot/src/main/resources/db/migration/
│   └── (migrations do pilot, se houver)
```
