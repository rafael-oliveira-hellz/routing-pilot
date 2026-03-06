package com.example.routing.infrastructure.config;

import com.example.routing.application.port.out.RateLimitPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Implementação do port de rate limit com Redis.
 * Trocar por Memcached/etc. = nova implementação de {@link RateLimitPort}.
 */
@Component
public class RateLimitConfig implements RateLimitPort {

    private final StringRedisTemplate redis;
    private final int maxPerVehiclePerSecond;
    private final int incidentMaxPerMinute;

    public RateLimitConfig(
            StringRedisTemplate redis,
            @Value("${routing.ingestion.rate-limit-per-vehicle-per-second:20}") int maxPerVehiclePerSecond,
            @Value("${routing.incident.rate-limit-per-minute:5}") int incidentMaxPerMinute) {
        this.redis = redis;
        this.maxPerVehiclePerSecond = maxPerVehiclePerSecond;
        this.incidentMaxPerMinute = incidentMaxPerMinute;
    }

    /**
     * Returns true if the request should be rate-limited (rejected).
     */
    public boolean isLocationRateLimited(String vehicleId) {
        String key = "ratelimit:loc:" + vehicleId;
        return checkAndIncrement(key, Duration.ofSeconds(1), maxPerVehiclePerSecond);
    }

    /**
     * Returns true if the incident report should be rate-limited (rejected).
     */
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
