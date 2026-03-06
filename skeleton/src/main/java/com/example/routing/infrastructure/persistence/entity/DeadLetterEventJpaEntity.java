package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "dead_letter_event")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DeadLetterEventJpaEntity {
    @Id
    private UUID id;

    @Column(nullable = false, length = 60)
    private String stream;

    @Column(nullable = false, length = 200)
    private String subject;

    @Column(name = "raw_payload", nullable = false, columnDefinition = "jsonb")
    private String rawPayload;

    @Column(name = "error_code", nullable = false, length = 40)
    private String errorCode;

    @Column(name = "error_message", columnDefinition = "text")
    private String errorMessage;

    @Column(name = "trace_id")
    private UUID traceId;

    @Column(name = "vehicle_id", length = 120)
    private String vehicleId;

    @Column(name = "occurred_at")
    private Instant occurredAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    private boolean reprocessed;
}
