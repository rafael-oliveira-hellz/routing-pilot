package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "live_position")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LivePositionJpaEntity {

    @Id
    private UUID id;

    @Column(name = "execution_id", nullable = false)
    private UUID executionId;

    private double latitude;

    private double longitude;

    /** Velocidade reportada pelo veículo (m/s). Usada no ETA (EWMA); persistida para auditoria e detecção de veículo parado. */
    @Column(name = "speed_mps")
    private double speedMps;

    private double heading;

    @Column(name = "accuracy_m")
    private double accuracyM;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
