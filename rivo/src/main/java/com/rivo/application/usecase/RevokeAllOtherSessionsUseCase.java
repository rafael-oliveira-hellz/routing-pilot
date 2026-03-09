package com.rivo.application.usecase;

import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RevokeAllOtherSessionsUseCase {

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final AuthSessionService authSessionService;

    @Transactional
    public AuthResponse revoke(AuthenticatedUser currentUser) {
        UserJpaEntity user = userRepository.findById(currentUser.userId()).orElseThrow();
        List<RefreshTokenJpaEntity> activeTokens = refreshTokenRepository.findByUser_IdAndRevokedFalse(currentUser.userId());
        List<RefreshTokenJpaEntity> currentSessionTokens = activeTokens.stream()
                .filter(token -> currentUser.sessionId().equals(token.getSessionId()))
                .toList();
        List<RefreshTokenJpaEntity> otherSessionTokens = activeTokens.stream()
                .filter(token -> !currentUser.sessionId().equals(token.getSessionId()))
                .toList();

        authSessionService.revoke(otherSessionTokens);
        authSessionService.revokeCurrentAccessToken(currentUser.jti(), currentUser.expiresAt());
        authSessionService.revoke(currentSessionTokens);

        user.setRememberMeToken(null);
        user.setRememberMeExpiresAt(null);
        userRepository.save(user);

        return authSessionService.toResponse(authSessionService.issue(user, currentUser.sessionId(), null));
    }
}

