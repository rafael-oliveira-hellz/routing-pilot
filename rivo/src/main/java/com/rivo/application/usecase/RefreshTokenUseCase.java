package com.rivo.application.usecase;

import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.domain.exception.RateLimitExceededException;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import java.time.Duration;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RefreshTokenUseCase {

    private final RefreshTokenRepository refreshTokenRepository;
    private final AuthRateLimitService authRateLimitService;
    private final AuthSessionService authSessionService;
    private final com.rivo.infrastructure.security.TokenSupport tokenSupport;

    @Transactional
    public AuthResponse refresh(String rawRefreshToken) {
        String tokenHash = tokenSupport.sha256(rawRefreshToken);
        if (authRateLimitService.isRateLimited("refresh", tokenHash, 10, Duration.ofMinutes(1))) {
            throw new RateLimitExceededException("Too many refresh attempts", 60);
        }

        RefreshTokenJpaEntity refreshToken = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Refresh token is invalid"));

        if (refreshToken.isRevoked() || refreshToken.getExpiresAt().isBefore(Instant.now())) {
            throw new UnauthorizedException("Refresh token expired or revoked");
        }

        UserJpaEntity user = refreshToken.getUser();
        if (!user.isActive()) {
            throw new UnauthorizedException("User account is inactive");
        }

        refreshToken.setRevoked(true);
        refreshTokenRepository.save(refreshToken);
        return authSessionService.toResponse(authSessionService.issue(user, refreshToken.getSessionId(), null));
    }
}

