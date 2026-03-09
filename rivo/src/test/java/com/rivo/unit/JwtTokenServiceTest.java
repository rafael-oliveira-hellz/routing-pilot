package com.rivo.unit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.domain.enums.UserRole;
import com.rivo.infrastructure.persistence.entity.UserJpaEntity;
import com.rivo.infrastructure.security.AuthProperties;
import com.rivo.infrastructure.security.JwtTokenService;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class JwtTokenServiceTest {

    @Test
    void rejectsMissingPemKeysWhenEphemeralModeIsDisabled() {
        AuthProperties properties = new AuthProperties();
        properties.setAllowEphemeralKeys(false);
        properties.setJwtPublicKeyPem("");
        properties.setJwtPrivateKeyPem("");

        assertThrows(IllegalStateException.class, () -> new JwtTokenService(properties, new ObjectMapper()));
    }

    @Test
    void allowsEphemeralKeysForLocalMode() {
        AuthProperties properties = new AuthProperties();
        properties.setAllowEphemeralKeys(true);
        properties.setJwtPublicKeyPem("");
        properties.setJwtPrivateKeyPem("");

        JwtTokenService service = new JwtTokenService(properties, new ObjectMapper());
        UserJpaEntity user = UserJpaEntity.builder()
                .id(UUID.randomUUID())
                .email("user@example.com")
                .passwordHash("hash")
                .name("Pilot User")
                .role(UserRole.USER)
                .active(true)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        assertDoesNotThrow(() -> service.issueAccessToken(user, UUID.randomUUID()));
    }
}