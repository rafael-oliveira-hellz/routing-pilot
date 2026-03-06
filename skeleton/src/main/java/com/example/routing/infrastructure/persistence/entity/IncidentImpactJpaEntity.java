package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident_impact")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IncidentImpactJpaEntity {

    @Id
    private UUID id;

    @Column(name = "incident_id", nullable = false)
    private UUID incidentId;

    @Column(name = "affected_route_id", nullable = false)
    private UUID affectedRouteId;

    @Column(name = "penalty_factor")
    private double penaltyFactor;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
        if (createdAt == null) createdAt = Instant.now();
    }
}
