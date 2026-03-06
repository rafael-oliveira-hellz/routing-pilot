package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.RouteSegmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteSegmentRepository extends JpaRepository<RouteSegmentJpaEntity, UUID> {

    List<RouteSegmentJpaEntity> findByResultIdOrderByFromPoint(UUID resultId);
}
