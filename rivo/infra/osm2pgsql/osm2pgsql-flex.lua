-- infra/osm2pgsql/osm2pgsql-flex.lua
-- Full import: every PBF element is persisted into a typed table or a catch-all table.

local json = require('dkjson')

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

local function tags_to_json(tags)
    return json.encode(tags)
end

local function has_any_tag(tags)
    for _ in pairs(tags) do
        return true
    end
    return false
end

function osm2pgsql.process_way(object)
    local t = object.tags
    if not has_any_tag(t) then
        return
    end

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

    other_ways:insert({
        osm_type = 'way',
        tags     = tags_to_json(t),
        geom     = object:as_linestring()
    })
end

function osm2pgsql.process_node(object)
    local t = object.tags
    if not has_any_tag(t) then
        return
    end

    local matched = false

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

    if not matched then
        other_nodes:insert({
            osm_type = 'node',
            tags     = tags_to_json(t),
            geom     = object:as_point()
        })
    end
end

function osm2pgsql.process_relation(object)
    local t = object.tags
    if not has_any_tag(t) then
        return
    end

    if t.boundary == 'administrative' and t.name then
        boundaries:insert({
            name        = t.name,
            admin_level = tonumber(t.admin_level),
            boundary    = t.boundary,
            geom        = object:as_multipolygon()
        })
        return
    end

    other_rels:insert({
        osm_type = 'relation',
        tags     = tags_to_json(t),
        geom     = object:as_multipolygon()
    })
end