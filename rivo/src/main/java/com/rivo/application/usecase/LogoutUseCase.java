package com.rivo.application.usecase;

import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LogoutUseCase {

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final AuthSessionService authSessionService;

    @Transactional
    public void logout(AuthenticatedUser user) {
        authSessionService.revokeCurrentAccessToken(user.jti(), user.expiresAt());
        authSessionService.revoke(refreshTokenRepository.findByUser_IdAndSessionIdAndRevokedFalse(user.userId(), user.sessionId()));
        userRepository.findById(user.userId()).ifPresent(entity -> {
            entity.setRememberMeToken(null);
            entity.setRememberMeExpiresAt(null);
            userRepository.save(entity);
        });
    }
}

