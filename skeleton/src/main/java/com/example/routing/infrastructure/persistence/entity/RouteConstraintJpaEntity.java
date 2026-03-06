package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "route_constraint")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteConstraintJpaEntity {

    @Id
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_request_id", nullable = false, unique = true)
    private RouteRequestJpaEntity routeRequest;

    @Column(name = "max_vehicle_count")
    private Integer maxVehicleCount;

    @Column(name = "max_duration_s")
    private Integer maxDurationS;

    @Column(name = "max_distance_m")
    private Integer maxDistanceM;

    @Column(name = "avoid_tolls")
    private boolean avoidTolls;

    @Column(name = "avoid_tunnels")
    private boolean avoidTunnels;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
