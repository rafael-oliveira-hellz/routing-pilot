package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.RouteWaypointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteWaypointRepository extends JpaRepository<RouteWaypointJpaEntity, UUID> {

    List<RouteWaypointJpaEntity> findByResultIdOrderBySequenceOrder(UUID resultId);
}
