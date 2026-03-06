package com.example.routing.domain.event;

import com.example.routing.domain.enums.RecalcReason;

import java.time.Instant;
import java.util.UUID;

public record RecalculateRouteRequested(
    UUID eventId,
    String vehicleId,
    String routeId,
    Instant occurredAt,
    RecalcReason reason,
    double distanceToCorridorMeters
) {}
