package com.rivo.application.usecase;

import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.RefreshTokenRepository;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ChangePasswordUseCase {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final PasswordPolicy passwordPolicy;
    private final AuthSessionService authSessionService;

    @Transactional
    public void change(AuthenticatedUser currentUser, String currentPassword, String newPassword) {
        UserJpaEntity user = userRepository.findById(currentUser.userId()).orElseThrow();
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new UnauthorizedException("Current password is incorrect");
        }
        passwordPolicy.validate(newPassword);
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setRememberMeToken(null);
        user.setRememberMeExpiresAt(null);
        userRepository.save(user);
        authSessionService.revoke(refreshTokenRepository.findByUser_IdAndRevokedFalse(user.getId()).stream()
                .filter(token -> !currentUser.sessionId().equals(token.getSessionId()))
                .toList());
    }
}

