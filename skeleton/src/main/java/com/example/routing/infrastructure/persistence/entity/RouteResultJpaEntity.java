package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "route_result")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteResultJpaEntity {

    @Id
    private UUID id;

    @Column(name = "optimization_id", nullable = false)
    private UUID optimizationId;

    @Column(name = "total_distance_meters")
    private double totalDistanceMeters;

    @Column(name = "total_duration_seconds")
    private double totalDurationSeconds;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
