package com.rivo.application.usecase;

import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthProperties;
import com.rivo.infrastructure.security.TokenSupport;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RememberMeLoginUseCase {

    private final UserRepository userRepository;
    private final TokenSupport tokenSupport;
    private final AuthProperties authProperties;
    private final AuthSessionService authSessionService;

    @Transactional
    public AuthResponse login(String rememberMeToken) {
        UserJpaEntity user = userRepository.findByRememberMeTokenAndActiveTrue(tokenSupport.sha256(rememberMeToken))
                .orElseThrow(() -> new UnauthorizedException("Remember-me token is invalid"));

        if (user.getRememberMeExpiresAt() == null || user.getRememberMeExpiresAt().isBefore(Instant.now())) {
            throw new UnauthorizedException("Remember-me token expired");
        }

        String rotatedRememberMe = tokenSupport.generateOpaqueToken();
        user.setRememberMeToken(tokenSupport.sha256(rotatedRememberMe));
        user.setRememberMeExpiresAt(Instant.now().plusSeconds(authProperties.getRememberMeTtlSeconds()));
        userRepository.save(user);
        return authSessionService.toResponse(authSessionService.issue(user, null, rotatedRememberMe));
    }
}

