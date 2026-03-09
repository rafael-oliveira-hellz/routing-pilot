package com.rivo.application.usecase;

import com.rivo.domain.enums.UserRole;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.persistence.repository.UserRepository;
import com.rivo.infrastructure.security.AuthProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class BootstrapAdminInitializer implements ApplicationRunner {

    private final AuthProperties authProperties;
    private final UserRepository userRepository;
    private final PasswordPolicy passwordPolicy;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(ApplicationArguments args) {
        AuthProperties.BootstrapAdmin bootstrapAdmin = authProperties.getBootstrapAdmin();
        if (!bootstrapAdmin.isEnabled()) {
            return;
        }
        if (userRepository.countByRoleAndActiveTrue(UserRole.ADMIN) > 0) {
            return;
        }

        passwordPolicy.validate(bootstrapAdmin.getPassword());
        UserJpaEntity admin = UserJpaEntity.builder()
                .email(bootstrapAdmin.getEmail().trim().toLowerCase())
                .passwordHash(passwordEncoder.encode(bootstrapAdmin.getPassword()))
                .name(bootstrapAdmin.getName().trim())
                .vehicleId(bootstrapAdmin.getVehicleId())
                .role(UserRole.ADMIN)
                .active(true)
                .build();
        userRepository.save(admin);
        log.warn("Bootstrap admin created with email={}. Rotate the configured password immediately after first login.", admin.getEmail());
    }
}

