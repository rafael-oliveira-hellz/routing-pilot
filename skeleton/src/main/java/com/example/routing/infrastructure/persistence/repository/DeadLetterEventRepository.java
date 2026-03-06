package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.DeadLetterEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DeadLetterEventRepository extends JpaRepository<DeadLetterEventJpaEntity, UUID> {

    List<DeadLetterEventJpaEntity> findByReprocessedFalseOrderByCreatedAt();

    List<DeadLetterEventJpaEntity> findByVehicleIdOrderByCreatedAtDesc(String vehicleId);

    List<DeadLetterEventJpaEntity> findByTraceId(UUID traceId);
}
