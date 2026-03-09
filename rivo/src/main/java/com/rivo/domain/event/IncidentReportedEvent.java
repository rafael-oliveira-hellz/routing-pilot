package com.rivo.domain.event;

import com.rivo.domain.enums.IncidentSeverity;
import com.rivo.domain.enums.IncidentType;

import java.time.Instant;
import java.util.UUID;

public record IncidentReportedEvent(
    UUID eventId,
    Instant occurredAt,
    double lat,
    double lon,
    IncidentType incidentType,
    IncidentSeverity severity,
    String description,
    UUID reportedBy
) {}


