package com.rivo.application.usecase;

import com.rivo.domain.enums.UserRole;
import com.rivo.domain.exception.DomainException;
import com.rivo.domain.exception.ForbiddenException;
import com.rivo.domain.exception.ResourceNotFoundException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DeleteUserUseCase {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AuthSessionService authSessionService;

    @Transactional
    public void delete(UUID targetUserId, AuthenticatedUser actor) {
        if (!actor.isAdmin()) {
            throw new ForbiddenException("Only administrators can delete users");
        }
        if (actor.userId().equals(targetUserId)) {
            throw new ForbiddenException("Administrators cannot delete their own account");
        }

        UserJpaEntity target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User", targetUserId));

        if (target.getRole() == UserRole.ADMIN && userRepository.countByRoleAndActiveTrue(UserRole.ADMIN) <= 1) {
            throw new DomainException("The last active administrator cannot be deleted");
        }

        target.setActive(false);
        target.setRememberMeToken(null);
        target.setRememberMeExpiresAt(null);
        userRepository.save(target);
        authSessionService.revoke(refreshTokenRepository.findByUser_IdAndRevokedFalse(target.getId()));
    }
}

