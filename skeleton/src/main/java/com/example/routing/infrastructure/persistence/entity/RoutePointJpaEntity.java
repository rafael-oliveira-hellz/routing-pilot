package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "route_point")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoutePointJpaEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_request_id", nullable = false)
    private RouteRequestJpaEntity routeRequest;

    @Column(nullable = false)
    private String identifier;

    private double latitude;

    private double longitude;

    @Column(name = "loading_duration_ms")
    private Integer loadingDurationMs;

    @Column(name = "unloading_duration_ms")
    private Integer unloadingDurationMs;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
