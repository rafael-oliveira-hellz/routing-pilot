package com.rivo.application.port.out;

import com.rivo.domain.entity.ExecutionEvent;

import java.util.List;
import java.util.UUID;

/**
 * Port de persist??ncia de eventos de auditoria.
 * Contrato em termos de dom??nio (ExecutionEvent); implementa????o na infraestrutura (ex.: JPA/Postgres).
 */
public interface ExecutionEventStore {

    void save(ExecutionEvent event);

    List<ExecutionEvent> findByTraceIdOrderByCreatedAt(UUID traceId);

    List<ExecutionEvent> findBySourceEventId(UUID sourceEventId);

    List<ExecutionEvent> findByExecutionIdAndDecisionOrderByCreatedAtDesc(UUID executionId, String decision);
}


