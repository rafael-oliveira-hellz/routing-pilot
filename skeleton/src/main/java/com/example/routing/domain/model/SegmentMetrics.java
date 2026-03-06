package com.example.routing.domain.model;

public record SegmentMetrics(
    double distanceMeters,
    double durationSeconds,
    double speedMps
) {
    public SegmentMetrics {
        if (distanceMeters < 0) throw new IllegalArgumentException("distanceMeters must be >= 0");
        if (durationSeconds < 0) throw new IllegalArgumentException("durationSeconds must be >= 0");
    }
}
