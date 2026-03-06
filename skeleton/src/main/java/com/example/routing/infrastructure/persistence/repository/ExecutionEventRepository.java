package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.ExecutionEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ExecutionEventRepository extends JpaRepository<ExecutionEventJpaEntity, UUID> {

    List<ExecutionEventJpaEntity> findByTraceIdOrderByCreatedAt(UUID traceId);

    List<ExecutionEventJpaEntity> findBySourceEventId(UUID sourceEventId);

    List<ExecutionEventJpaEntity> findByExecutionIdAndDecisionOrderByCreatedAtDesc(
            UUID executionId, String decision);
}
