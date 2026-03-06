package com.example.routing.infrastructure.persistence.adapter;

import com.example.routing.application.port.out.ExecutionEventStore;
import com.example.routing.domain.entity.ExecutionEvent;
import com.example.routing.infrastructure.persistence.entity.ExecutionEventJpaEntity;
import com.example.routing.infrastructure.persistence.mapper.ExecutionEventMapper;
import com.example.routing.infrastructure.persistence.repository.ExecutionEventRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Implementação do port de auditoria com JPA/Postgres.
 * Trocar de banco = substituir por outro adapter (ex.: MongoExecutionEventStoreAdapter) sem alterar domain/application.
 */
@Component
public class ExecutionEventStoreAdapter implements ExecutionEventStore {

    private final ExecutionEventRepository jpaRepository;

    public ExecutionEventStoreAdapter(ExecutionEventRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public void save(ExecutionEvent event) {
        ExecutionEventJpaEntity jpa = ExecutionEventMapper.toJpa(event);
        jpaRepository.save(jpa);
    }

    @Override
    public List<ExecutionEvent> findByTraceIdOrderByCreatedAt(UUID traceId) {
        return jpaRepository.findByTraceIdOrderByCreatedAt(traceId).stream()
                .map(ExecutionEventMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<ExecutionEvent> findBySourceEventId(UUID sourceEventId) {
        return jpaRepository.findBySourceEventId(sourceEventId).stream()
                .map(ExecutionEventMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<ExecutionEvent> findByExecutionIdAndDecisionOrderByCreatedAtDesc(UUID executionId, String decision) {
        return jpaRepository.findByExecutionIdAndDecisionOrderByCreatedAtDesc(executionId, decision).stream()
                .map(ExecutionEventMapper::toDomain)
                .collect(Collectors.toList());
    }
}
