package com.example.routing.domain.event;

import com.example.routing.domain.enums.IncidentSeverity;
import com.example.routing.domain.enums.IncidentType;

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
