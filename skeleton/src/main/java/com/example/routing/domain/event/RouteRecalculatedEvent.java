package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record RouteRecalculatedEvent(
    UUID eventId,
    UUID routeRequestId,
    UUID optimizationId,
    Instant occurredAt,
    double totalDistanceMeters,
    double totalDurationSeconds,
    int waypointCount
) {}
