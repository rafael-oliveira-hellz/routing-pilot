package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.RouteResultJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RouteResultRepository extends JpaRepository<RouteResultJpaEntity, UUID> {

    Optional<RouteResultJpaEntity> findByOptimizationId(UUID optimizationId);
}


