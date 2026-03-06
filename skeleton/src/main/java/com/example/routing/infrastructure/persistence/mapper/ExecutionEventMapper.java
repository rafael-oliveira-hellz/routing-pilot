package com.example.routing.infrastructure.persistence.mapper;

import com.example.routing.domain.entity.ExecutionEvent;
import com.example.routing.infrastructure.persistence.entity.ExecutionEventJpaEntity;

import java.util.Optional;

/**
 * Mapeia entre entidade de domínio (agnóstica a banco) e entidade JPA.
 * Trocar de Postgres para outro banco = nova entidade de persistência + novo mapper; domínio inalterado.
 */
public final class ExecutionEventMapper {

    private ExecutionEventMapper() {}

    public static ExecutionEventJpaEntity toJpa(ExecutionEvent domain) {
        ExecutionEventJpaEntity e = new ExecutionEventJpaEntity();
        e.setId(domain.id());
        e.setExecutionId(domain.executionId().orElse(null));
        e.setEventType(domain.eventType());
        e.setTraceId(domain.traceId().orElse(null));
        e.setSourceEventId(domain.sourceEventId().orElse(null));
        e.setDecision(domain.decision());
        e.setDurationMs(domain.durationMs());
        e.setPayload(domain.payload());
        e.setCreatedAt(domain.createdAt());
        return e;
    }

    public static ExecutionEvent toDomain(ExecutionEventJpaEntity jpa) {
        return new ExecutionEvent(
            jpa.getId(),
            Optional.ofNullable(jpa.getExecutionId()),
            jpa.getEventType(),
            Optional.ofNullable(jpa.getTraceId()),
            Optional.ofNullable(jpa.getSourceEventId()),
            jpa.getDecision(),
            jpa.getDurationMs(),
            jpa.getPayload(),
            jpa.getCreatedAt()
        );
    }
}
