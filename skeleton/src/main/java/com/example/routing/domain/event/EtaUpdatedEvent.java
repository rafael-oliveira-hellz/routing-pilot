package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record EtaUpdatedEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    long remainingSeconds,
    double confidence,
    boolean degraded,
    double distanceRemainingMeters
) {}
