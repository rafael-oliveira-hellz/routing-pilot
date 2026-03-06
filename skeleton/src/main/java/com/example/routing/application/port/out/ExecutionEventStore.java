package com.example.routing.application.port.out;

import com.example.routing.domain.entity.ExecutionEvent;

import java.util.List;
import java.util.UUID;

/**
 * Port de persistência de eventos de auditoria.
 * Contrato em termos de domínio (ExecutionEvent); implementação na infraestrutura (ex.: JPA/Postgres).
 */
public interface ExecutionEventStore {

    void save(ExecutionEvent event);

    List<ExecutionEvent> findByTraceIdOrderByCreatedAt(UUID traceId);

    List<ExecutionEvent> findBySourceEventId(UUID sourceEventId);

    List<ExecutionEvent> findByExecutionIdAndDecisionOrderByCreatedAtDesc(UUID executionId, String decision);
}
