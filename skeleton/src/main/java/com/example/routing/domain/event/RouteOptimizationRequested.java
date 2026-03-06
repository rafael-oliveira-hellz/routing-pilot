package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record RouteOptimizationRequested(
    UUID eventId,
    UUID routeRequestId,
    Instant occurredAt,
    int pointCount
) {}
