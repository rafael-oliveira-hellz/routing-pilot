package com.rivo.domain.event;

import com.rivo.domain.enums.IncidentType;
import com.rivo.domain.model.RegionTile;

import java.time.Instant;
import java.util.UUID;

public record IncidentExpiredEvent(
    UUID eventId,
    UUID incidentId,
    IncidentType incidentType,
    RegionTile tile,
    Instant occurredAt
) {}


