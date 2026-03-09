package com.rivo.infrastructure.redis;

import com.rivo.application.port.out.LocationDedupPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

/**
 * Implementa????o do port de dedup com Redis.
 * Trocar por Memcached/etc. = nova implementa????o de {@link LocationDedupPort}.
 */
@Component
public class RedisLocationDedup implements LocationDedupPort {

    private final StringRedisTemplate redis;
    private final Duration window;

    public RedisLocationDedup(
            StringRedisTemplate redis,
            @Value("${routing.ingestion.dedup-window-minutes:2}") long windowMinutes) {
        this.redis = redis;
        this.window = Duration.ofMinutes(windowMinutes);
    }

    public boolean isDuplicate(String vehicleId, Instant occurredAt) {
        String key = "dedup:" + vehicleId + ":" + occurredAt.toEpochMilli();
        Boolean wasAbsent = redis.opsForValue().setIfAbsent(key, "1", window);
        return wasAbsent == null || !wasAbsent;
    }
}


