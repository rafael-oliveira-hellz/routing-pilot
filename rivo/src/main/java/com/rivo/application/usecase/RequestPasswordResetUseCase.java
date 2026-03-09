package com.rivo.application.usecase;

import com.rivo.api.rest.dto.ForgotPasswordRequest;
import com.rivo.infrastructure.persistence.entity.PasswordResetTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.PasswordResetTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthProperties;
import com.rivo.infrastructure.security.TokenSupport;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class RequestPasswordResetUseCase {

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final TokenSupport tokenSupport;
    private final AuthProperties authProperties;

    @Transactional
    public void request(ForgotPasswordRequest request) {
        userRepository.findByEmailIgnoreCase(request.email().trim().toLowerCase())
                .filter(UserJpaEntity::isActive)
                .ifPresent(user -> {
                    String rawToken = tokenSupport.generateOpaqueToken();
                    PasswordResetTokenJpaEntity resetToken = PasswordResetTokenJpaEntity.builder()
                            .user(user)
                            .tokenHash(tokenSupport.sha256(rawToken))
                            .expiresAt(Instant.now().plusSeconds(authProperties.getPasswordResetTtlSeconds()))
                            .build();
                    passwordResetTokenRepository.save(resetToken);
                    log.info("Password reset token issued for email={} token={}", user.getEmail(), rawToken);
                });
    }
}

