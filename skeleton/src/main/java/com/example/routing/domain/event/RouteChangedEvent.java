package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record RouteChangedEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    double totalDistanceMeters,
    double totalDurationSeconds,
    int waypointCount
) {}
