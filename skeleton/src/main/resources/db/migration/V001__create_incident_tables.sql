CREATE EXTENSION IF NOT EXISTS postgis;

-- PostgreSQL ENUMs
CREATE TYPE incident_type_enum AS ENUM (
    'BLITZ', 'ACCIDENT', 'HEAVY_TRAFFIC', 'WET_ROAD', 'FLOOD',
    'ROAD_WORK', 'BROKEN_TRAFFIC_LIGHT', 'ANIMAL_ON_ROAD',
    'VEHICLE_STOPPED', 'LANDSLIDE', 'FOG', 'OTHER'
);

CREATE TYPE incident_severity_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

CREATE TYPE vote_type_enum AS ENUM ('CONFIRM', 'DENY', 'GONE');

CREATE TABLE incident (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_type   incident_type_enum NOT NULL,
    severity        incident_severity_enum NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location        GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (
                        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                    ) STORED,
    radius_meters   INTEGER NOT NULL DEFAULT 200,
    region_tile_x   BIGINT NOT NULL,
    region_tile_y   BIGINT NOT NULL,
    region_zoom     INTEGER NOT NULL DEFAULT 14,
    description     VARCHAR(500),
    reported_by     UUID NOT NULL,
    vote_count      INTEGER NOT NULL DEFAULT 1,
    quorum_reached  BOOLEAN NOT NULL DEFAULT FALSE,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_incident_tile ON incident (region_tile_x, region_tile_y, region_zoom) WHERE active = TRUE;
CREATE INDEX idx_incident_location ON incident USING GIST (location) WHERE active = TRUE;
CREATE INDEX idx_incident_expires ON incident (expires_at) WHERE active = TRUE;

CREATE TABLE incident_vote (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES incident(id) ON DELETE CASCADE,
    voter_id    UUID NOT NULL,
    vote_type   vote_type_enum NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE (incident_id, voter_id)
);
