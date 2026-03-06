package com.example.routing.domain.entity;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Evento de auditoria da execução de rota.
 * Entidade de domínio: agnóstica a persistência; sem anotações JPA.
 * Identificadores em UUID.
 */
public record ExecutionEvent(
    UUID id,
    Optional<UUID> executionId,
    String eventType,
    Optional<UUID> traceId,
    Optional<UUID> sourceEventId,
    String decision,
    Integer durationMs,
    String payload,
    Instant createdAt
) {
    public static ExecutionEvent of(
            UUID id,
            UUID executionId,
            String eventType,
            UUID traceId,
            UUID sourceEventId,
            String decision,
            Integer durationMs,
            String payload,
            Instant createdAt) {
        return new ExecutionEvent(
            id,
            Optional.ofNullable(executionId),
            eventType,
            Optional.ofNullable(traceId),
            Optional.ofNullable(sourceEventId),
            decision,
            durationMs,
            payload,
            createdAt
        );
    }
}
