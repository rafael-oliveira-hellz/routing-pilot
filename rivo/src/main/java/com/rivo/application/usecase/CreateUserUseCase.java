package com.rivo.application.usecase;

import com.rivo.api.rest.dto.CreateUserRequest;
import com.rivo.api.rest.dto.UserResponse;
import com.rivo.domain.enums.UserRole;
import com.rivo.domain.exception.DomainException;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthenticatedUser;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CreateUserUseCase {

    private final UserRepository userRepository;
    private final PasswordPolicy passwordPolicy;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserResponse create(CreateUserRequest request, Optional<AuthenticatedUser> actor) {
        String normalizedEmail = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(normalizedEmail)) {
            throw new DomainException("A user with this email already exists");
        }
        passwordPolicy.validate(request.password());

        UserRole role = UserRole.USER;
        if (request.role() != null && actor.isPresent() && actor.get().isAdmin()) {
            role = request.role();
        }

        UserJpaEntity user = UserJpaEntity.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.password()))
                .name(request.name().trim())
                .vehicleId(blankToNull(request.vehicleId()))
                .role(role)
                .active(true)
                .build();

        return UserResponse.fromEntity(userRepository.save(user));
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase();
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}

