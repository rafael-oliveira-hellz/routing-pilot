package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

public record SignalRecoveredEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    Instant occurredAt,
    long offlineDurationSeconds
) {}
