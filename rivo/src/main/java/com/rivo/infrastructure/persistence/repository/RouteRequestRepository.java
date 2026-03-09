package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.RouteRequestJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface RouteRequestRepository extends JpaRepository<RouteRequestJpaEntity, UUID> {
}


