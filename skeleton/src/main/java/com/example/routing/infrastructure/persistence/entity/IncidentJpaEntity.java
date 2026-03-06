package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@Builder
public class IncidentJpaEntity {
    @Id
    private UUID id;

    @Column(name = "incident_type", nullable = false, length = 40)
    private String incidentType;

    @Column(nullable = false, length = 20)
    private String severity;

    private double latitude;
    private double longitude;

    @Column(name = "radius_meters")
    private int radiusMeters;

    @Column(name = "region_tile_x")
    private long regionTileX;

    @Column(name = "region_tile_y")
    private long regionTileY;

    @Column(name = "region_zoom")
    private int regionZoom;

    @Column(length = 500)
    private String description;

    @Column(name = "reported_by")
    private UUID reportedBy;

    @Column(name = "vote_count")
    private int voteCount;

    @Column(name = "quorum_reached")
    private boolean quorumReached;

    private boolean active;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
