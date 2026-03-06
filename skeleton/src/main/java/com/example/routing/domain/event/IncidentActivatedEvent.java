package com.example.routing.domain.event;

import com.example.routing.domain.enums.IncidentSeverity;
import com.example.routing.domain.enums.IncidentType;

import java.time.Instant;
import java.util.UUID;

public record IncidentActivatedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID incidentId,
    IncidentType incidentType,
    IncidentSeverity severity,
    double lat,
    double lon,
    int radiusMeters,
    long regionTileX,
    long regionTileY,
    Instant expiresAt
) {}
