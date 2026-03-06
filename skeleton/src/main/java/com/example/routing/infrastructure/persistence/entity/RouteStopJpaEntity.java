package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "route_stop",
       indexes = @Index(name = "idx_route_stop_request_seq",
                        columnList = "route_request_id, sequence_order"))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RouteStopJpaEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_request_id", nullable = false)
    private RouteRequestJpaEntity routeRequest;

    @Column(nullable = false)
    private String identifier;

    private double latitude;

    private double longitude;

    @Column(name = "sequence_order", nullable = false)
    private int sequenceOrder;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
