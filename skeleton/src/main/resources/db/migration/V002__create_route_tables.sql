-- PostgreSQL ENUMs para todas as colunas que representam valores fixos
CREATE TYPE optimization_strategy_enum AS ENUM ('FASTEST', 'NO_TOLL', 'ECO_FUEL', 'SHORTEST');
CREATE TYPE optimization_status_enum AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED');
CREATE TYPE execution_status_enum AS ENUM ('IN_PROGRESS', 'DEGRADED_ESTIMATE', 'RECALCULATING', 'ARRIVED', 'FAILED');
CREATE TYPE route_point_role_enum AS ENUM ('ORIGIN', 'DESTINATION');
CREATE TYPE improve_for_enum AS ENUM ('DISTANCE', 'TIME');
CREATE TYPE traffic_enum AS ENUM ('ENABLED', 'DISABLED');
CREATE TYPE vehicle_enum AS ENUM ('TRUCK', 'CAR', 'MOTORCYCLE', 'VAN', 'BICYCLE');
CREATE TYPE tunnel_category_enum AS ENUM ('B', 'C', 'D', 'E', 'F');
CREATE TYPE execution_event_type_enum AS ENUM (
    'ETA_UPDATED', 'ROUTE_RECALCULATED', 'DEVIATION_DETECTED',
    'DESTINATION_REACHED', 'SIGNAL_LOST', 'SIGNAL_RECOVERED',
    'INCIDENT_IMPACT', 'MANUAL_REROUTE'
);
CREATE TYPE ws_push_type_enum AS ENUM ('ETA_UPDATE', 'ROUTE_CHANGED', 'INCIDENT_ALERT', 'ARRIVAL');

CREATE TABLE route_request (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    departure_at            TIMESTAMP WITH TIME ZONE,
    optimization_strategy   optimization_strategy_enum NOT NULL DEFAULT 'FASTEST',
    improve_for             improve_for_enum NOT NULL DEFAULT 'TIME',
    traffic                 traffic_enum NOT NULL DEFAULT 'ENABLED',
    vehicle                 vehicle_enum NOT NULL DEFAULT 'TRUCK',
    tunnel_category         tunnel_category_enum,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX idx_route_request_strategy ON route_request (optimization_strategy);

CREATE TABLE route_point (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_request_id        UUID NOT NULL REFERENCES route_request(id) ON DELETE CASCADE,
    role                    route_point_role_enum NOT NULL,
    identifier              VARCHAR(120),
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    location                GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (
                                ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                            ) STORED,
    loading_duration_ms     INTEGER DEFAULT 0,
    unloading_duration_ms   INTEGER DEFAULT 0
);
CREATE INDEX idx_route_point_request ON route_point (route_request_id);
CREATE INDEX idx_route_point_location ON route_point USING GIST (location);

CREATE TABLE route_stop (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_request_id        UUID NOT NULL REFERENCES route_request(id) ON DELETE CASCADE,
    identifier              VARCHAR(120),
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    location                GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (
                                ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                            ) STORED,
    sequence_order          INTEGER NOT NULL,
    CONSTRAINT chk_max_stops CHECK (sequence_order BETWEEN 1 AND 1000)
);
CREATE INDEX idx_route_stop_request ON route_stop (route_request_id);
CREATE INDEX idx_route_stop_sequence ON route_stop (route_request_id, sequence_order);
CREATE INDEX idx_route_stop_location ON route_stop USING GIST (location);

CREATE TABLE route_constraint (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_request_id            UUID NOT NULL REFERENCES route_request(id) ON DELETE CASCADE,
    max_vehicle_count           INTEGER,
    max_route_duration_seconds  INTEGER,
    max_route_distance_meters   INTEGER,
    avoid_tolls                 BOOLEAN DEFAULT FALSE,
    avoid_tunnels               BOOLEAN DEFAULT FALSE
);
CREATE INDEX idx_route_constraint_request ON route_constraint (route_request_id);

CREATE TABLE route_optimization (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_request_id    UUID NOT NULL REFERENCES route_request(id),
    status              optimization_status_enum NOT NULL DEFAULT 'PENDING',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX idx_route_optimization_request ON route_optimization (route_request_id);
CREATE INDEX idx_route_optimization_status ON route_optimization (status);

CREATE TABLE optimization_run (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    optimization_id     UUID NOT NULL REFERENCES route_optimization(id) ON DELETE CASCADE,
    algorithm_version   VARCHAR(80),
    solver_name         VARCHAR(80),
    started_at          TIMESTAMP WITH TIME ZONE,
    finished_at         TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_optimization_run ON optimization_run (optimization_id);

CREATE TABLE route_result (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    optimization_id         UUID NOT NULL REFERENCES route_optimization(id) ON DELETE CASCADE,
    total_distance_meters   INTEGER,
    total_duration_seconds  INTEGER
);
CREATE INDEX idx_route_result_optimization ON route_result (optimization_id);

CREATE TABLE route_segment (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    result_id               UUID NOT NULL REFERENCES route_result(id) ON DELETE CASCADE,
    from_point              UUID,
    to_point                UUID,
    segment_order           INTEGER NOT NULL,
    distance_meters         NUMERIC(12,2),
    travel_time_seconds     NUMERIC(12,2),
    path_geometry           GEOGRAPHY(LINESTRING, 4326),
    active_incident_ids     UUID[]
);
CREATE INDEX idx_route_segment_result ON route_segment (result_id);
CREATE INDEX idx_route_segment_order ON route_segment (result_id, segment_order);
CREATE INDEX idx_route_segment_geometry ON route_segment USING GIST (path_geometry);

CREATE TABLE route_waypoint (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    result_id       UUID NOT NULL REFERENCES route_result(id) ON DELETE CASCADE,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location        GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (
                        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                    ) STORED,
    sequence_order  INTEGER NOT NULL
);
CREATE INDEX idx_route_waypoint_result ON route_waypoint (result_id);
CREATE INDEX idx_route_waypoint_sequence ON route_waypoint (result_id, sequence_order);

CREATE TABLE route_execution (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    optimization_id     UUID NOT NULL REFERENCES route_optimization(id),
    vehicle_id          VARCHAR(120) NOT NULL,
    status              execution_status_enum NOT NULL DEFAULT 'IN_PROGRESS',
    route_version       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_route_execution_optimization ON route_execution (optimization_id);
CREATE INDEX idx_route_execution_vehicle ON route_execution (vehicle_id);
CREATE INDEX idx_route_execution_status ON route_execution (status);

-- Telemetria de posição em tempo real (speed_mps = velocidade do veículo, usada no ETA/EWMA)
CREATE TABLE live_position (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id    UUID NOT NULL REFERENCES route_execution(id) ON DELETE CASCADE,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location        GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (
                        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                    ) STORED,
    speed_mps       DOUBLE PRECISION,
    heading         DOUBLE PRECISION,
    accuracy_m      DOUBLE PRECISION,
    recorded_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX idx_live_position_execution ON live_position (execution_id);
CREATE INDEX idx_live_position_recorded ON live_position (recorded_at);
CREATE INDEX idx_live_position_location ON live_position USING GIST (location);

CREATE TABLE execution_event (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id    UUID NOT NULL REFERENCES route_execution(id) ON DELETE CASCADE,
    event_type      execution_event_type_enum NOT NULL,
    payload         JSONB,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX idx_execution_event_execution ON execution_event (execution_id);
CREATE INDEX idx_execution_event_type ON execution_event (event_type);
CREATE INDEX idx_execution_event_created ON execution_event (created_at);

-- Tabela para dados de incidentes visíveis por segmento (display em tela)
CREATE TABLE segment_incident_display (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_id      UUID NOT NULL REFERENCES route_segment(id) ON DELETE CASCADE,
    incident_id     UUID NOT NULL REFERENCES incident(id) ON DELETE CASCADE,
    incident_type   incident_type_enum NOT NULL,
    severity        incident_severity_enum NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    description     VARCHAR(500),
    vote_count      INTEGER NOT NULL DEFAULT 1,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    UNIQUE (segment_id, incident_id)
);
CREATE INDEX idx_segment_incident_segment ON segment_incident_display (segment_id) WHERE active = TRUE;

-- Tabela para vehicle_profile (referência cruzada)
CREATE TABLE vehicle_profile (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_type            vehicle_enum NOT NULL,
    tunnel_category         tunnel_category_enum,
    max_payload_kg          INTEGER,
    fuel_efficiency_km_l    NUMERIC(8,3)
);
CREATE INDEX idx_vehicle_profile_type ON vehicle_profile (vehicle_type);
