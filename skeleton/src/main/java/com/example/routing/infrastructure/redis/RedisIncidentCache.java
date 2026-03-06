package com.example.routing.infrastructure.redis;

import com.example.routing.domain.model.ActiveIncident;
import com.example.routing.domain.model.RegionTile;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Collections;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class RedisIncidentCache {

    private static final Duration TTL = Duration.ofMinutes(5);
    private static final String PREFIX = "incidents:tile:";

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

    public List<ActiveIncident> getByTile(RegionTile tile) {
        try {
            String key = tileKey(tile);
            String json = redis.opsForValue().get(key);
            if (json == null) return null;
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.warn("Redis incident cache deserialization failed: {}", e.getMessage());
            return null;
        } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
            log.warn("Redis incident cache connection failed: {}", e.getMessage());
            return null;
        }
    }

    public void putByTile(RegionTile tile, List<ActiveIncident> incidents) {
        try {
            String key = tileKey(tile);
            String json = objectMapper.writeValueAsString(incidents);
            redis.opsForValue().set(key, json, TTL);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.warn("Redis incident cache serialization failed: {}", e.getMessage());
        } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
            log.warn("Redis incident cache write connection failed: {}", e.getMessage());
        }
    }

    public void invalidateTile(RegionTile tile) {
        redis.delete(tileKey(tile));
    }

    public void invalidateNearby(RegionTile tile) {
        for (long dx = -1; dx <= 1; dx++) {
            for (long dy = -1; dy <= 1; dy++) {
                invalidateTile(new RegionTile(tile.zoomLevel(), tile.tileX() + dx, tile.tileY() + dy));
            }
        }
    }

    private String tileKey(RegionTile tile) {
        return PREFIX + tile.zoomLevel() + ":" + tile.tileX() + ":" + tile.tileY();
    }
}
