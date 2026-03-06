package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

import java.util.UUID;

@Entity
@Table(name = "route_waypoint")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteWaypointJpaEntity {

    @Id
    private UUID id;

    @Column(name = "result_id", nullable = false)
    private UUID resultId;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point location;

    @Column(name = "sequence_order", nullable = false)
    private int sequenceOrder;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
