package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.LineString;

import java.util.UUID;

@Entity
@Table(name = "route_segment")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteSegmentJpaEntity {

    @Id
    private UUID id;

    @Column(name = "result_id", nullable = false)
    private UUID resultId;

    @Column(name = "from_point", nullable = false)
    private UUID fromPoint;

    @Column(name = "to_point", nullable = false)
    private UUID toPoint;

    @Column(name = "distance_meters")
    private double distanceMeters;

    @Column(name = "travel_time_seconds")
    private double travelTimeSeconds;

    @Column(name = "path_geometry", columnDefinition = "geometry(LineString,4326)")
    private LineString pathGeometry;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
