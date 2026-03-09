package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.RouteSegmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteSegmentRepository extends JpaRepository<RouteSegmentJpaEntity, UUID> {

    List<RouteSegmentJpaEntity> findByResultIdOrderBySegmentOrder(UUID resultId);
}


