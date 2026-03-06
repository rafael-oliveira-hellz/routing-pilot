package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "route_optimization")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteOptimizationJpaEntity {

    @Id
    private UUID id;

    @Column(name = "route_request_id", nullable = false)
    private UUID routeRequestId;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
        if (createdAt == null) createdAt = Instant.now();
    }
}
