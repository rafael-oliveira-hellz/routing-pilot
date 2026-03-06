package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "route_request")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteRequestJpaEntity {

    @Id
    private UUID id;

    @Column(name = "departure_at")
    private Instant departureAt;

    @Column(name = "optimization_strategy", length = 20)
    private String optimizationStrategy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @OneToMany(mappedBy = "routeRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<RoutePointJpaEntity> points = new ArrayList<>();

    @OneToMany(mappedBy = "routeRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<RouteStopJpaEntity> stops = new ArrayList<>();

    @OneToOne(mappedBy = "routeRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    private RouteConstraintJpaEntity constraint;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
        if (createdAt == null) createdAt = Instant.now();
    }
}
