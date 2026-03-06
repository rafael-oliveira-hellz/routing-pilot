package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "execution_event")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ExecutionEventJpaEntity {
    @Id
    private UUID id;

    @Column(name = "execution_id")
    private UUID executionId;

    @Column(name = "event_type", nullable = false, length = 60)
    private String eventType;

    @Column(name = "trace_id")
    private UUID traceId;

    @Column(name = "source_event_id")
    private UUID sourceEventId;

    @Column(length = 30)
    private String decision;

    @Column(name = "duration_ms")
    private Integer durationMs;

    @Column(columnDefinition = "jsonb")
    private String payload;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
