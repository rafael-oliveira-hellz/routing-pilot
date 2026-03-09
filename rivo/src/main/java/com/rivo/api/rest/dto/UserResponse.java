package com.rivo.api.rest.dto;

import com.rivo.domain.enums.UserRole;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import java.time.Instant;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String email,
        String name,
        String vehicleId,
        UserRole role,
        boolean active,
        Instant createdAt,
        Instant updatedAt
) {
    public static UserResponse fromEntity(UserJpaEntity user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getVehicleId(),
                user.getRole(),
                user.isActive(),
                user.getCreatedAt(),
                user.getUpdatedAt());
    }
}

