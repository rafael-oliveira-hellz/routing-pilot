package com.example.routing.engine.eta;

import com.example.routing.domain.model.EtaState;
import com.example.routing.domain.model.RouteProgress;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

@Component
public class EtaEngine {

    private final double minSpeedMps;
    private final double maxSpeedMps;
    private final double alpha;
    private final long signalTimeoutSec;

    public EtaEngine(
            @Value("${routing.eta.min-speed-mps:1.0}") double minSpeedMps,
            @Value("${routing.eta.max-speed-mps:45.0}") double maxSpeedMps,
            @Value("${routing.eta.ewma-alpha:0.25}") double alpha,
            @Value("${routing.eta.signal-timeout-seconds:20}") long signalTimeoutSec) {
        this.minSpeedMps = minSpeedMps;
        this.maxSpeedMps = maxSpeedMps;
        this.alpha = alpha;
        this.signalTimeoutSec = signalTimeoutSec;
    }

    /**
     * Atualiza o ETA com a velocidade observada (reportada pelo veículo).
     *
     * @param observedSpeedMps velocidade em m/s vinda do evento de localização (LocationUpdatedEvent.speedMps).
     *                         Obrigatória: sem ela o ETA não reflete a velocidade real do veículo.
     */
    public EtaState update(EtaState current,
                           RouteProgress progress,
                           double observedSpeedMps,
                           double trafficFactor,
                           double incidentFactor,
                           Instant now) {

        double clipped = clamp(observedSpeedMps, minSpeedMps, maxSpeedMps);
        double smoothed = ewma(current.smoothedSpeedMps(), clipped, alpha);

        double nominalSec = progress.distanceRemainingMeters() / Math.max(smoothed, minSpeedMps);
        double adjustedSec = nominalSec * trafficFactor * incidentFactor;
        long remaining = Math.max(0L, Math.round(adjustedSec));

        double confidence = computeConfidence(
                progress.distanceToCorridorMeters(), now, current.lastLocationAt());
        boolean degraded = Duration.between(current.lastLocationAt(), now).toSeconds() > signalTimeoutSec;

        return new EtaState(remaining, now, confidence, smoothed, now, degraded);
    }

    private static double ewma(double prev, double current, double alpha) {
        if (prev <= 0) return current;
        return alpha * current + (1 - alpha) * prev;
    }

    private static double clamp(double v, double min, double max) {
        return Math.max(min, Math.min(max, v));
    }

    private static double computeConfidence(double corridorDist, Instant now, Instant lastAt) {
        long ageSec = Math.max(0, Duration.between(lastAt, now).toSeconds());
        double c1 = Math.max(0.0, 1.0 - (corridorDist / 200.0));
        double c2 = Math.max(0.0, 1.0 - (ageSec / 60.0));
        return clamp(0.7 * c1 + 0.3 * c2, 0.0, 1.0);
    }
}
