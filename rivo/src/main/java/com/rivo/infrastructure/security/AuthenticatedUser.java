package com.rivo.infrastructure.security;

import com.rivo.domain.enums.UserRole;
import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;
import org.springframework.security.core.AuthenticatedPrincipal;

public record AuthenticatedUser(
        UUID userId,
        String email,
        String vehicleId,
        UserRole role,
        String jti,
        UUID sessionId,
        Instant expiresAt
) implements AuthenticatedPrincipal, Serializable {

    @Override
    public String getName() {
        return userId.toString();
    }

    public boolean isAdmin() {
        return role == UserRole.ADMIN;
    }
}

