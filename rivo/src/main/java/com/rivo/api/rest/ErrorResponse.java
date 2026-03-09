package com.rivo.api.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.List;
import org.slf4j.MDC;

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
        return of(status, errorCode, message, path, MDC.get("traceId"));
    }

    public static ErrorResponse of(int status, String errorCode, String message, String path, String traceId) {
        return new ErrorResponse(Instant.now(), status, errorCode, message, path, traceId, null);
    }

    public static ErrorResponse withFieldErrors(int status, String errorCode, String message,
                                                String path, List<FieldError> errors) {
        return new ErrorResponse(Instant.now(), status, errorCode, message, path, MDC.get("traceId"), errors);
    }
}


