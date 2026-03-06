package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record OptimizationFailedEvent(
    UUID eventId,
    UUID routeRequestId,
    Instant occurredAt,
    String reason
) {}
