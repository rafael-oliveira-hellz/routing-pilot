package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.RouteExecutionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RouteExecutionRepository extends JpaRepository<RouteExecutionJpaEntity, UUID> {

    Optional<RouteExecutionJpaEntity> findByVehicleIdAndStatus(String vehicleId, String status);

    Optional<RouteExecutionJpaEntity> findByOptimizationId(UUID optimizationId);
}
