package com.rivo.application.usecase;

import com.rivo.api.rest.dto.UpdateUserRequest;
import com.rivo.api.rest.dto.UserResponse;
import com.rivo.domain.enums.UserRole;
import com.rivo.domain.exception.DomainException;
import com.rivo.domain.exception.ForbiddenException;
import com.rivo.domain.exception.ResourceNotFoundException;
import com.rivo.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UpdateUserUseCase {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AuthSessionService authSessionService;

    @Transactional
    public UserResponse update(UUID targetUserId, UpdateUserRequest request, AuthenticatedUser actor) {
        UserJpaEntity target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User", targetUserId));

        boolean self = actor.userId().equals(targetUserId);
        if (!self && !actor.isAdmin()) {
            throw new ForbiddenException("You can only update your own user profile");
        }

        if (request.email() != null) {
            String normalizedEmail = request.email().trim().toLowerCase();
            userRepository.findByEmailIgnoreCase(normalizedEmail)
                    .filter(existing -> !existing.getId().equals(targetUserId))
                    .ifPresent(existing -> {
                        throw new DomainException("A user with this email already exists");
                    });
            target.setEmail(normalizedEmail);
        }

        if (request.name() != null && !request.name().isBlank()) {
            target.setName(request.name().trim());
        }
        if (request.vehicleId() != null) {
            target.setVehicleId(request.vehicleId().isBlank() ? null : request.vehicleId().trim());
        }

        if (request.role() != null) {
            if (!actor.isAdmin()) {
                throw new ForbiddenException("Only administrators can change user roles");
            }
            if (target.getRole() == UserRole.ADMIN && request.role() != UserRole.ADMIN
                    && userRepository.countByRoleAndActiveTrue(UserRole.ADMIN) <= 1) {
                throw new DomainException("The last active administrator cannot be demoted");
            }
            target.setRole(request.role());
        }

        if (request.active() != null) {
            if (!actor.isAdmin()) {
                throw new ForbiddenException("Only administrators can activate or deactivate users");
            }
            if (target.getRole() == UserRole.ADMIN && !request.active()
                    && userRepository.countByRoleAndActiveTrue(UserRole.ADMIN) <= 1) {
                throw new DomainException("The last active administrator cannot be deactivated");
            }
            target.setActive(request.active());
            if (!Boolean.TRUE.equals(request.active())) {
                target.setRememberMeToken(null);
                target.setRememberMeExpiresAt(null);
                List<RefreshTokenJpaEntity> activeTokens = refreshTokenRepository.findByUser_IdAndRevokedFalse(target.getId());
                authSessionService.revoke(activeTokens);
            }
        }

        return UserResponse.fromEntity(userRepository.save(target));
    }
}

