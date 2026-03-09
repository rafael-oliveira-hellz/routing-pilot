package com.rivo.application.usecase;

import java.time.Duration;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthRateLimitService {

    private final StringRedisTemplate stringRedisTemplate;

    public boolean isRateLimited(String namespace, String key, long maxRequests, Duration window) {
        String redisKey = "auth:rate:" + namespace + ":" + key;
        Long count = stringRedisTemplate.opsForValue().increment(redisKey);
        if (count == null) {
            return false;
        }
        if (count == 1L) {
            stringRedisTemplate.expire(redisKey, window);
        }
        return count > maxRequests;
    }
}

