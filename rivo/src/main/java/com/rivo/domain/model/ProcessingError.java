package com.rivo.domain.model;

import com.rivo.domain.enums.ProcessingErrorCode;

import java.time.Instant;
import java.util.UUID;

public record ProcessingError(
    UUID traceId,
    UUID eventId,
    String vehicleId,
    ProcessingErrorCode errorCode,
    String message,
    String rawPayload,
    Instant occurredAt,
    int attemptNumber
) {}


