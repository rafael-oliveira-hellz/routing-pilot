ALTER TABLE refresh_token
    ADD COLUMN IF NOT EXISTS session_id UUID DEFAULT gen_random_uuid();

UPDATE refresh_token
SET session_id = gen_random_uuid()
WHERE session_id IS NULL;

ALTER TABLE refresh_token
    ALTER COLUMN session_id SET NOT NULL;

ALTER TABLE refresh_token
    ADD COLUMN IF NOT EXISTS access_jti VARCHAR(64);

ALTER TABLE refresh_token
    ADD COLUMN IF NOT EXISTS access_expires_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_refresh_token_session ON refresh_token (user_id, session_id);
CREATE INDEX IF NOT EXISTS idx_refresh_token_access_jti ON refresh_token (access_jti) WHERE access_jti IS NOT NULL;
