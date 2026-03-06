package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "route_execution")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteExecutionJpaEntity {

    @Id
    private UUID id;

    @Column(name = "optimization_id", nullable = false)
    private UUID optimizationId;

    @Column(name = "vehicle_id", nullable = false)
    private String vehicleId;

    @Column(nullable = false, length = 30)
    private String status;

    @Column(name = "route_version")
    private int routeVersion;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
        if (createdAt == null) createdAt = Instant.now();
    }
}
