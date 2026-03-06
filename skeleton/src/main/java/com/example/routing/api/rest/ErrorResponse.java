package com.example.routing.api.rest;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(
    Instant timestamp,
    int status,
    String errorCode,
    String message,
    String path,
    String traceId,
    List<FieldError> errors
) {
    public record FieldError(
        String field,
        Object rejectedValue,
        String message
    ) {}

    public static ErrorResponse of(int status, String errorCode, String message, String path) {
        String traceId = org.slf4j.MDC.get("traceId");
        return new ErrorResponse(Instant.now(), status, errorCode, message, path, traceId, null);
    }

    public static ErrorResponse withFieldErrors(int status, String errorCode, String message,
                                                String path, List<FieldError> errors) {
        String traceId = org.slf4j.MDC.get("traceId");
        return new ErrorResponse(Instant.now(), status, errorCode, message, path, traceId, errors);
    }
}
