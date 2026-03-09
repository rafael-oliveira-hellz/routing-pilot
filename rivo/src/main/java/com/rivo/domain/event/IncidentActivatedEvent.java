package com.rivo.domain.event;

import com.rivo.domain.enums.IncidentSeverity;
import com.rivo.domain.enums.IncidentType;

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


