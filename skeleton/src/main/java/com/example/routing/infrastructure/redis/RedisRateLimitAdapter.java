package com.example.routing.infrastructure.redis;

import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import com.example.routing.application.port.out.RateLimitPort;

/**
 * Implementação de {@link RateLimitPort} com Redis.
 * Backend de rate limit é escolhido por {@code routing.rate-limit.backend} (ex.: redis, memcached).
 * Para trocar para Memcached: defina {@code routing.rate-limit.backend=memcached} e registre um adapter Memcached.
 */
@Component
@ConditionalOnProperty(name = "routing.rate-limit.backend", havingValue = "redis", matchIfMissing = true)
public class RedisRateLimitAdapter implements RateLimitPort {

    private final StringRedisTemplate redis;
    private final int maxPerVehiclePerSecond;
    private final int incidentMaxPerMinute;

    public RedisRateLimitAdapter(
            StringRedisTemplate redis,
            @Value("${routing.ingestion.rate-limit-per-vehicle-per-second:20}") int maxPerVehiclePerSecond,
            @Value("${routing.incident.rate-limit-per-minute:5}") int incidentMaxPerMinute) {
        this.redis = redis;
        this.maxPerVehiclePerSecond = maxPerVehiclePerSecond;
        this.incidentMaxPerMinute = incidentMaxPerMinute;
    }

    @Override
    public boolean isLocationRateLimited(String vehicleId) {
        String key = "ratelimit:loc:" + vehicleId;
        return checkAndIncrement(key, Duration.ofSeconds(1), maxPerVehiclePerSecond);
    }

    @Override
    public boolean isIncidentRateLimited(String userId) {
        String key = "ratelimit:incident:" + userId;
        return checkAndIncrement(key, Duration.ofMinutes(1), incidentMaxPerMinute);
    }

    private boolean checkAndIncrement(String key, Duration window, int maxCount) {
        Long count = redis.opsForValue().increment(key);
        if (count != null && count == 1) {
            redis.expire(key, window);
        }
        return count != null && count > maxCount;
    }
}
