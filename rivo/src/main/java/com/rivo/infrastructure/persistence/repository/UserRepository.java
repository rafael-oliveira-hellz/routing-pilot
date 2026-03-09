package com.rivo.infrastructure.persistence.repository;

import com.rivo.domain.enums.UserRole;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserJpaEntity, UUID> {

    Optional<UserJpaEntity> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    Optional<UserJpaEntity> findByRememberMeTokenAndActiveTrue(String rememberMeToken);

    long countByRoleAndActiveTrue(UserRole role);

    List<UserJpaEntity> findAllByOrderByCreatedAtAsc();
}

