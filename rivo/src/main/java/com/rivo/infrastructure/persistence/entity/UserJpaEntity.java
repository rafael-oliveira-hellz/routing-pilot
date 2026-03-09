package com.rivo.infrastructure.persistence.entity;

import com.rivo.domain.enums.UserRole;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "app_user")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserJpaEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 255, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(name = "vehicle_id", length = 120)
    private String vehicleId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, columnDefinition = "user_role_enum")
    private UserRole role;

    @Column(name = "remember_me_token", length = 512)
    private String rememberMeToken;

    @Column(name = "remember_me_expires_at")
    private Instant rememberMeExpiresAt;

    @Builder.Default
    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (email != null) {
            email = email.trim().toLowerCase();
        }
        if (role == null) {
            role = UserRole.USER;
        }
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    void preUpdate() {
        if (email != null) {
            email = email.trim().toLowerCase();
        }
        updatedAt = Instant.now();
    }
}

