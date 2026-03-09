package com.rivo.application.usecase;

import com.rivo.api.rest.dto.AuthResponse;
import com.rivo.api.rest.dto.LoginRequest;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthProperties;
import com.rivo.infrastructure.security.TokenSupport;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LoginUseCase {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthSessionService authSessionService;
    private final TokenSupport tokenSupport;
    private final AuthProperties authProperties;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        UserJpaEntity user = userRepository.findByEmailIgnoreCase(request.email().trim().toLowerCase())
                .filter(UserJpaEntity::isActive)
                .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }

        String rememberMeToken = null;
        if (request.rememberMe()) {
            rememberMeToken = tokenSupport.generateOpaqueToken();
            user.setRememberMeToken(tokenSupport.sha256(rememberMeToken));
            user.setRememberMeExpiresAt(Instant.now().plusSeconds(authProperties.getRememberMeTtlSeconds()));
            userRepository.save(user);
        }

        return authSessionService.toResponse(authSessionService.issue(user, null, rememberMeToken));
    }
}

