-- Permite eventos de auditoria sem execução (ex.: signal lost antes de ter execution).
ALTER TABLE execution_event
    ALTER COLUMN execution_id DROP NOT NULL;
