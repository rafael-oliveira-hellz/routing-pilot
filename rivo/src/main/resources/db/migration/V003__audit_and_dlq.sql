CREATE TYPE processing_error_code_enum AS ENUM (
    'DESERIALIZATION_FAILED',
    'VALIDATION_FAILED',
    'STATE_LOAD_FAILED',
    'STATE_SAVE_FAILED',
    'POLICY_EXCEPTION',
    'PUBLISH_FAILED',
    'TIMEOUT',
    'UNKNOWN'
);

CREATE TYPE decision_enum AS ENUM (
    'ETA_ONLY',
    'RECALCULATE',
    'ARRIVED',
    'DEGRADED',
    'PROCESSING_FAILED'
);

ALTER TABLE execution_event
    ADD COLUMN trace_id UUID,
    ADD COLUMN source_event_id UUID,
    ADD COLUMN decision decision_enum,
    ADD COLUMN duration_ms INTEGER;

CREATE INDEX idx_execution_event_trace ON execution_event (trace_id);
CREATE INDEX idx_execution_event_source ON execution_event (source_event_id);
CREATE INDEX idx_execution_event_decision ON execution_event (decision);

CREATE TABLE dead_letter_event (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream          VARCHAR(60) NOT NULL,
    subject         VARCHAR(200) NOT NULL,
    raw_payload     JSONB NOT NULL,
    error_code      processing_error_code_enum NOT NULL,
    error_message   TEXT,
    trace_id        UUID,
    vehicle_id      VARCHAR(120),
    occurred_at     TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    reprocessed     BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_dlq_vehicle ON dead_letter_event (vehicle_id);
CREATE INDEX idx_dlq_error_code ON dead_letter_event (error_code);
CREATE INDEX idx_dlq_created ON dead_letter_event (created_at);
CREATE INDEX idx_dlq_reprocessed ON dead_letter_event (reprocessed) WHERE reprocessed = FALSE;
CREATE INDEX idx_dlq_trace ON dead_letter_event (trace_id);
