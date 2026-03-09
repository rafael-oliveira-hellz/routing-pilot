package com.rivo.application.usecase;

import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.api.rest.dto.UserResponse;
import com.rivo.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.security.AuthProperties;
import com.rivo.infrastructure.security.JwtTokenService;
import com.rivo.infrastructure.security.TokenBlocklistService;
import com.rivo.infrastructure.security.TokenSupport;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthSessionService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenService jwtTokenService;
    private final TokenSupport tokenSupport;
    private final TokenBlocklistService tokenBlocklistService;
    private final AuthProperties authProperties;

    @Transactional
    public AuthSessionTokens issue(UserJpaEntity user, UUID sessionId, String rememberMeToken) {
        UUID effectiveSessionId = sessionId != null ? sessionId : UUID.randomUUID();
        String rawRefreshToken = tokenSupport.generateOpaqueToken();
        String refreshHash = tokenSupport.sha256(rawRefreshToken);
        JwtTokenService.AccessTokenIssue accessTokenIssue = jwtTokenService.issueAccessToken(user, effectiveSessionId);

        RefreshTokenJpaEntity refreshToken = RefreshTokenJpaEntity.builder()
                .user(user)
                .tokenHash(refreshHash)
                .expiresAt(Instant.now().plusSeconds(authProperties.getRefreshTokenTtlSeconds()))
                .revoked(false)
                .sessionId(effectiveSessionId)
                .accessJti(accessTokenIssue.jti())
                .accessExpiresAt(accessTokenIssue.expiresAt())
                .build();
        refreshTokenRepository.save(refreshToken);

        return new AuthSessionTokens(
                accessTokenIssue.token(),
                rawRefreshToken,
                Math.toIntExact(authProperties.getAccessTokenTtlSeconds()),
                accessTokenIssue.jti(),
                accessTokenIssue.expiresAt(),
                effectiveSessionId,
                rememberMeToken,
                UserResponse.fromEntity(user));
    }

    @Transactional
    public void revoke(List<RefreshTokenJpaEntity> refreshTokens) {
        Instant now = Instant.now();
        for (RefreshTokenJpaEntity refreshToken : refreshTokens) {
            if (!refreshToken.isRevoked()) {
                refreshToken.setRevoked(true);
            }
            if (refreshToken.getAccessJti() != null && refreshToken.getAccessExpiresAt() != null && refreshToken.getAccessExpiresAt().isAfter(now)) {
                tokenBlocklistService.revoke(refreshToken.getAccessJti(), refreshToken.getAccessExpiresAt());
            }
        }
        refreshTokenRepository.saveAll(refreshTokens);
    }

    public void revokeCurrentAccessToken(String jti, Instant expiresAt) {
        tokenBlocklistService.revoke(jti, expiresAt);
    }

    public AuthResponse toResponse(AuthSessionTokens tokens) {
        return new AuthResponse(
                tokens.accessToken(),
                tokens.refreshToken(),
                tokens.expiresIn(),
                tokens.user(),
                tokens.rememberMeToken());
    }

    public record AuthSessionTokens(
            String accessToken,
            String refreshToken,
            int expiresIn,
            String accessJti,
            Instant accessExpiresAt,
            UUID sessionId,
            String rememberMeToken,
            UserResponse user
    ) {
    }
}

