package com.rivo.infrastructure.persistence.repository;

import com.rivo.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefreshTokenRepository extends JpaRepository<RefreshTokenJpaEntity, UUID> {

    Optional<RefreshTokenJpaEntity> findByTokenHash(String tokenHash);

    List<RefreshTokenJpaEntity> findByUser_IdAndRevokedFalse(UUID userId);

    List<RefreshTokenJpaEntity> findByUser_IdAndSessionIdAndRevokedFalse(UUID userId, UUID sessionId);

    List<RefreshTokenJpaEntity> findByUser_IdAndSessionId(UUID userId, UUID sessionId);
}

