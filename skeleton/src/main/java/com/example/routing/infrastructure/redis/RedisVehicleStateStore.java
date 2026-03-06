package com.example.routing.infrastructure.redis;

import com.example.routing.application.port.out.VehicleStateStore;
import com.example.routing.domain.model.VehicleState;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import org.springframework.data.redis.core.ScanOptions;

import java.time.Duration;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

@Component
@RequiredArgsConstructor
@Slf4j
public class RedisVehicleStateStore implements VehicleStateStore {

    private static final String PREFIX = "vehicle:state:";
    private static final Duration TTL = Duration.ofHours(24);

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

    @Override
    public Optional<VehicleState> load(String vehicleId) {
        try {
            String json = redis.opsForValue().get(PREFIX + vehicleId);
            if (json == null) return Optional.empty();
            return Optional.of(objectMapper.readValue(json, VehicleState.class));
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.warn("Failed to deserialize vehicle state for {}", vehicleId, e);
            return Optional.empty();
        } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
            log.warn("Redis connection failed loading vehicle state for {}", vehicleId, e);
            return Optional.empty();
        }
    }

    @Override
    public void save(VehicleState state) {
        try {
            String json = objectMapper.writeValueAsString(state);
            redis.opsForValue().set(PREFIX + state.vehicleId(), json, TTL);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Failed to serialize vehicle state for {}", state.vehicleId(), e);
        } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
            log.error("Redis connection failed saving vehicle state for {}", state.vehicleId(), e);
        }
    }

    @Override
    public Set<String> scanActiveVehicleIds() {
        Set<String> ids = new HashSet<>();
        var options = ScanOptions.scanOptions().match(PREFIX + "*").count(200).build();
        try (var cursor = redis.scan(options)) {
            while (cursor.hasNext()) {
                String key = cursor.next();
                ids.add(key.substring(PREFIX.length()));
            }
        }
        return ids;
    }
}
