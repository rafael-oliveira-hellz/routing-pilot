package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.LivePositionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LivePositionRepository extends JpaRepository<LivePositionJpaEntity, UUID> {

    List<LivePositionJpaEntity> findTop10ByExecutionIdOrderByRecordedAtDesc(UUID executionId);
}


