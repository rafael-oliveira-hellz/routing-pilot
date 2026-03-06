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
