package com.example.routing.domain.policy;

import com.example.routing.domain.model.VehicleState;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

@Component
public class RecalculationThrottlePolicy {

    private final long minIntervalSeconds;
    private final int maxRecalcPerMinute;

    public RecalculationThrottlePolicy(
            @Value("${routing.throttle.min-interval-seconds:30}") long minIntervalSeconds,
            @Value("${routing.throttle.max-recalc-per-minute:2}") int maxRecalcPerMinute) {
        this.minIntervalSeconds = minIntervalSeconds;
        this.maxRecalcPerMinute = maxRecalcPerMinute;
    }

    public boolean canRecalculate(VehicleState state, Instant now) {
        if (state.lastRecalculationAt() == null) return true;
        long elapsed = Duration.between(state.lastRecalculationAt(), now).toSeconds();
        return elapsed >= minIntervalSeconds
                && state.recalcCountLastMinute() < maxRecalcPerMinute;
    }
}
