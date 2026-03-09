package com.rivo.infrastructure.persistence.mapper;

import com.rivo.domain.entity.ExecutionEvent;
import com.rivo.infrastructure.persistence.entity.ExecutionEventJpaEntity;

import java.util.Optional;

/**
 * Mapeia entre entidade de dom??nio (agn??stica a banco) e entidade JPA.
 * Trocar de Postgres para outro banco = nova entidade de persist??ncia + novo mapper; dom??nio inalterado.
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


