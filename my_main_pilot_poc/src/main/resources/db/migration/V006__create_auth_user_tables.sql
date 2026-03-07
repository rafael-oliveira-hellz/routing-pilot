-- Auth e CRUD de usuários: roles USER/ADMIN, app_user, refresh_token, password_reset_token
-- Doc: 14-Checklist-Sprints.md (Sprint 1 - Auth e CRUD de Usuários)

CREATE TYPE user_role_enum AS ENUM ('USER', 'ADMIN');

CREATE TABLE app_user (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email                   VARCHAR(255) NOT NULL,
    password_hash           VARCHAR(255) NOT NULL,
    name                    VARCHAR(255) NOT NULL,
    vehicle_id              VARCHAR(120),
    role                    user_role_enum NOT NULL DEFAULT 'USER',
    remember_me_token       VARCHAR(512),
    remember_me_expires_at  TIMESTAMP WITH TIME ZONE,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT uq_app_user_email UNIQUE (email)
);

CREATE INDEX idx_app_user_email ON app_user (email);
CREATE INDEX idx_app_user_role ON app_user (role) WHERE active = TRUE;
CREATE INDEX idx_app_user_remember_me ON app_user (remember_me_token) WHERE remember_me_token IS NOT NULL;

CREATE TABLE refresh_token (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_refresh_token_user ON refresh_token (user_id);
CREATE INDEX idx_refresh_token_expires ON refresh_token (expires_at) WHERE revoked = FALSE;

CREATE TABLE password_reset_token (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at     TIMESTAMP WITH TIME ZONE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_password_reset_token_user ON password_reset_token (user_id);
CREATE INDEX idx_password_reset_token_expires ON password_reset_token (expires_at) WHERE used_at IS NULL;
