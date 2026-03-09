package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.PasswordResetTokenJpaEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetTokenJpaEntity, UUID> {

    Optional<PasswordResetTokenJpaEntity> findByTokenHashAndUsedAtIsNull(String tokenHash);
}

