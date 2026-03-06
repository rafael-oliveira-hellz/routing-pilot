package com.example.routing.engine.optimization;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class DistanceMatrixCache {

    private final ConcurrentHashMap<String, CacheEntry> l1 = new ConcurrentHashMap<>();
    private final RedisTemplate<String, byte[]> redisTemplate;
    private final long l1TtlMs;
    private final long l2TtlSeconds;

    public DistanceMatrixCache(
            RedisTemplate<String, byte[]> redisTemplate,
            @Value("${routing.optimization.cache.l1-ttl-ms:300000}") long l1TtlMs,
            @Value("${routing.optimization.cache.l2-ttl-seconds:900}") long l2TtlSeconds) {
        this.redisTemplate = redisTemplate;
        this.l1TtlMs = l1TtlMs;
        this.l2TtlSeconds = l2TtlSeconds;
    }

    public Optional<double[][]> get(List<Coordinate> points) {
        String key = computeKey(points);

        var l1Entry = l1.get(key);
        if (l1Entry != null && !l1Entry.isExpired()) {
            log.debug("Distance matrix cache L1 HIT: {}", key);
            return Optional.of(l1Entry.matrix);
        }

        try {
            byte[] data = redisTemplate.opsForValue().get("distmatrix:" + key);
            if (data != null) {
                double[][] matrix = deserialize(data, points.size());
                l1.put(key, new CacheEntry(matrix, System.currentTimeMillis() + l1TtlMs));
                log.debug("Distance matrix cache L2 HIT: {}", key);
                return Optional.of(matrix);
            }
        } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
            log.warn("Redis L2 cache connection failed: {}", e.getMessage());
        } catch (org.springframework.data.redis.RedisSystemException e) {
            log.warn("Redis L2 cache system error: {}", e.getMessage());
        }

        return Optional.empty();
    }

    public void put(List<Coordinate> points, double[][] matrix) {
        String key = computeKey(points);

        l1.put(key, new CacheEntry(matrix, System.currentTimeMillis() + l1TtlMs));

        try {
            byte[] data = serialize(matrix);
            redisTemplate.opsForValue().set("distmatrix:" + key, data, Duration.ofSeconds(l2TtlSeconds));
        } catch (org.springframework.data.redis.RedisConnectionFailureException | org.springframework.data.redis.RedisSystemException e) {
            log.warn("Redis L2 cache write failed: {}", e.getMessage());
        }
    }

    public Optional<Double> getDepotDistance(UUID depotId, UUID pointId) {
        String key = "depot:" + depotId + ":" + pointId;

        var l1Entry = l1.get(key);
        if (l1Entry != null && !l1Entry.isExpired() && l1Entry.matrix.length > 0) {
            return Optional.of(l1Entry.matrix[0][0]);
        }

        try {
            byte[] data = redisTemplate.opsForValue().get("distmatrix:depot:" + depotId + ":" + pointId);
            if (data != null) {
                double dist = ByteBuffer.wrap(data).getDouble();
                return Optional.of(dist);
            }
        } catch (org.springframework.data.redis.RedisConnectionFailureException | org.springframework.data.redis.RedisSystemException e) {
            log.warn("Redis L3 depot cache read failed: {}", e.getMessage());
        }

        return Optional.empty();
    }

    public void putDepotDistance(UUID depotId, UUID pointId, double distance) {
        try {
            byte[] data = ByteBuffer.allocate(8).putDouble(distance).array();
            redisTemplate.opsForValue().set(
                "distmatrix:depot:" + depotId + ":" + pointId,
                data, Duration.ofHours(24));
        } catch (org.springframework.data.redis.RedisConnectionFailureException | org.springframework.data.redis.RedisSystemException e) {
            log.warn("Redis L3 depot cache write failed: {}", e.getMessage());
        }
    }

    public void evictL1() {
        long now = System.currentTimeMillis();
        l1.entrySet().removeIf(e -> e.getValue().isExpired());
    }

    private String computeKey(List<Coordinate> points) {
        try {
            List<String> ids = points.stream()
                    .map(p -> p.getId().toString())
                    .sorted()
                    .toList();
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            for (String id : ids) md.update(id.getBytes());
            return HexFormat.of().formatHex(md.digest()).substring(0, 16);
        } catch (java.security.NoSuchAlgorithmException e) {
            return String.valueOf(points.hashCode());
        }
    }

    private byte[] serialize(double[][] matrix) {
        int n = matrix.length;
        ByteBuffer buf = ByteBuffer.allocate(4 + n * n * 8);
        buf.putInt(n);
        for (double[] row : matrix)
            for (double v : row)
                buf.putDouble(v);
        return buf.array();
    }

    private double[][] deserialize(byte[] data, int expectedN) {
        ByteBuffer buf = ByteBuffer.wrap(data);
        int n = buf.getInt();
        double[][] matrix = new double[n][n];
        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++)
                matrix[i][j] = buf.getDouble();
        return matrix;
    }

    private record CacheEntry(double[][] matrix, long expiresAt) {
        boolean isExpired() { return System.currentTimeMillis() > expiresAt; }
    }
}
