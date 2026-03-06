package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.RouteRequestJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface RouteRequestRepository extends JpaRepository<RouteRequestJpaEntity, UUID> {
}
