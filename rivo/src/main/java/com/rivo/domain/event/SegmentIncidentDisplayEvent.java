package com.rivo.domain.event;

import com.rivo.domain.enums.IncidentSeverity;
import com.rivo.domain.enums.IncidentType;

import java.time.Instant;
import java.util.UUID;

public record SegmentIncidentDisplayEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int segmentOrder,
    UUID incidentId,
    IncidentType incidentType,
    IncidentSeverity severity,
    double lat,
    double lon,
    String description,
    int voteCount,
    Instant expiresAt
) {}


