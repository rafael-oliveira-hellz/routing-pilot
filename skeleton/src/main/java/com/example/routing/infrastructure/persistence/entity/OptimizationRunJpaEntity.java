package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "optimization_run")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OptimizationRunJpaEntity {

    @Id
    private UUID id;

    @Column(name = "optimization_id", nullable = false)
    private UUID optimizationId;

    @Column(name = "algorithm_version", length = 50)
    private String algorithmVersion;

    @Column(name = "solver_name", length = 100)
    private String solverName;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "finished_at")
    private Instant finishedAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
    }
}
