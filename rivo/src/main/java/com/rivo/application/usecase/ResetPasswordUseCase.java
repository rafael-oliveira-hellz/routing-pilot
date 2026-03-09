package com.rivo.application.usecase;

import com.rivo.domain.exception.DomainException;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.PasswordResetTokenJpaEntity;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.PasswordResetTokenRepository;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.TokenSupport;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ResetPasswordUseCase {

    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final PasswordPolicy passwordPolicy;
    private final PasswordEncoder passwordEncoder;
    private final TokenSupport tokenSupport;
    private final AuthSessionService authSessionService;

    @Transactional
    public void reset(String token, String newPassword) {
        passwordPolicy.validate(newPassword);
        PasswordResetTokenJpaEntity resetToken = passwordResetTokenRepository.findByTokenHashAndUsedAtIsNull(tokenSupport.sha256(token))
                .orElseThrow(() -> new UnauthorizedException("Password reset token is invalid"));

        if (resetToken.getExpiresAt().isBefore(Instant.now())) {
            throw new UnauthorizedException("Password reset token expired");
        }

        UserJpaEntity user = resetToken.getUser();
        if (!user.isActive()) {
            throw new DomainException("User account is inactive");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setRememberMeToken(null);
        user.setRememberMeExpiresAt(null);
        userRepository.save(user);

        resetToken.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(resetToken);
        authSessionService.revoke(refreshTokenRepository.findByUser_IdAndRevokedFalse(user.getId()));
    }
}

