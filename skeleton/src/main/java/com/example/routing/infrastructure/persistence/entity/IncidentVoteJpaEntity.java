package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident_vote",
       uniqueConstraints = @UniqueConstraint(columnNames = {"incident_id", "voter_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IncidentVoteJpaEntity {

    @Id
    private UUID id;

    @Column(name = "incident_id", nullable = false)
    private UUID incidentId;

    @Column(name = "voter_id", nullable = false)
    private UUID voterId;

    @Column(name = "vote_type", nullable = false, length = 10)
    private String voteType;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (id == null) id = UUID.randomUUID();
        if (createdAt == null) createdAt = Instant.now();
    }
}
