package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.RouteStopJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteStopRepository extends JpaRepository<RouteStopJpaEntity, UUID> {

    List<RouteStopJpaEntity> findByRouteRequestIdOrderBySequenceOrder(UUID routeRequestId);
}


