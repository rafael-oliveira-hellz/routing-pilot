package com.rivo.infrastructure.security;

import java.time.Duration;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TokenBlocklistService {

    private static final String KEY_PREFIX = "token_revoked:";

    private final StringRedisTemplate stringRedisTemplate;

    public void revoke(String jti, Instant expiresAt) {
        if (jti == null || jti.isBlank() || expiresAt == null) {
            return;
        }
        Duration ttl = Duration.between(Instant.now(), expiresAt);
        if (ttl.isNegative() || ttl.isZero()) {
            return;
        }
        stringRedisTemplate.opsForValue().set(KEY_PREFIX + jti, "1", ttl);
    }

    public boolean isRevoked(String jti) {
        if (jti == null || jti.isBlank()) {
            return false;
        }
        Boolean present = stringRedisTemplate.hasKey(KEY_PREFIX + jti);
        return Boolean.TRUE.equals(present);
    }
}

