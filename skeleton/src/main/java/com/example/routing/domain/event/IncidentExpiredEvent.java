package com.example.routing.domain.event;

import com.example.routing.domain.enums.IncidentType;
import com.example.routing.domain.model.RegionTile;

import java.time.Instant;
import java.util.UUID;

public record IncidentExpiredEvent(
    UUID eventId,
    UUID incidentId,
    IncidentType incidentType,
    RegionTile tile,
    Instant occurredAt
) {}
