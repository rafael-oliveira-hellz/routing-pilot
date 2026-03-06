package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record EtaDegradedEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    long extrapolatedRemainingSeconds,
    double lastKnownSpeedMps,
    long offlineSeconds
) {}
