package com.example.routing.domain.model;

import java.time.Instant;

public record EtaState(
    long remainingSeconds,
    Instant calculatedAt,
    double confidence,
    double smoothedSpeedMps,
    Instant lastLocationAt,
    boolean degraded
) {
    public static EtaState initial(Instant now) {
        return new EtaState(0, now, 0.0, 0.0, now, true);
    }
}
