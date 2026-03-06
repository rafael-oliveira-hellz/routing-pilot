package com.example.routing.api.rest;

import com.example.routing.domain.exception.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ErrorResponse> handleDomain(DomainException e, HttpServletRequest req) {
        log.warn("Domain validation error: {}", e.getMessage());
        if (!e.getViolations().isEmpty()) {
            List<ErrorResponse.FieldError> fieldErrors = e.getViolations().stream()
                    .map(v -> new ErrorResponse.FieldError(null, null, v))
                    .toList();
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(ErrorResponse.withFieldErrors(
                            HttpStatus.UNPROCESSABLE_ENTITY.value(),
                            "DOMAIN_VALIDATION",
                            e.getMessage(),
                            req.getRequestURI(),
                            fieldErrors));
        }
        return response(HttpStatus.UNPROCESSABLE_ENTITY, "DOMAIN_VALIDATION", e.getMessage(), req);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException e, HttpServletRequest req) {
        log.warn("Resource not found: {}", e.getMessage());
        return response(HttpStatus.NOT_FOUND, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(RateLimitExceededException.class)
    public ResponseEntity<ErrorResponse> handleRateLimit(RateLimitExceededException e, HttpServletRequest req) {
        log.warn("Rate limit exceeded: {}", e.getMessage());
        return response(HttpStatus.TOO_MANY_REQUESTS, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(ConcurrencyLimitExceededException.class)
    public ResponseEntity<ErrorResponse> handleConcurrency(ConcurrencyLimitExceededException e, HttpServletRequest req) {
        log.warn("Concurrency limit exceeded: {}", e.getMessage());
        return response(HttpStatus.SERVICE_UNAVAILABLE, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(OptimizationException.class)
    public ResponseEntity<ErrorResponse> handleOptimization(OptimizationException e, HttpServletRequest req) {
        log.error("Optimization failed: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(GraphHopperException.class)
    public ResponseEntity<ErrorResponse> handleGraphHopper(GraphHopperException e, HttpServletRequest req) {
        log.error("GraphHopper error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(VehicleStateException.class)
    public ResponseEntity<ErrorResponse> handleVehicleState(VehicleStateException e, HttpServletRequest req) {
        log.error("Vehicle state error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(IncidentException.class)
    public ResponseEntity<ErrorResponse> handleIncident(IncidentException e, HttpServletRequest req) {
        log.error("Incident error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(CacheException.class)
    public ResponseEntity<ErrorResponse> handleCache(CacheException e, HttpServletRequest req) {
        log.error("Cache error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(EventProcessingException.class)
    public ResponseEntity<ErrorResponse> handleEventProcessing(EventProcessingException e, HttpServletRequest req) {
        log.error("Event processing error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException e, HttpServletRequest req) {
        List<ErrorResponse.FieldError> fieldErrors = e.getBindingResult().getFieldErrors().stream()
                .map(f -> new ErrorResponse.FieldError(
                        f.getField(),
                        f.getRejectedValue(),
                        f.getDefaultMessage()))
                .toList();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.withFieldErrors(
                        HttpStatus.BAD_REQUEST.value(),
                        "VALIDATION_FAILED",
                        "Validation failed for " + fieldErrors.size() + " field(s)",
                        req.getRequestURI(),
                        fieldErrors));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleBadBody(HttpMessageNotReadableException e, HttpServletRequest req) {
        return response(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST", "Request body is malformed or missing", req);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingParam(MissingServletRequestParameterException e, HttpServletRequest req) {
        return response(HttpStatus.BAD_REQUEST, "MISSING_PARAMETER", e.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException e, HttpServletRequest req) {
        String msg = "Parameter '" + e.getName() + "' must be of type " + (e.getRequiredType() != null ? e.getRequiredType().getSimpleName() : "unknown");
        return response(HttpStatus.BAD_REQUEST, "TYPE_MISMATCH", msg, req);
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ErrorResponse> handleDataAccess(DataAccessException e, HttpServletRequest req) {
        log.error("Database error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, "DATABASE_ERROR", "A database error occurred", req);
    }

    @ExceptionHandler(RoutingException.class)
    public ResponseEntity<ErrorResponse> handleRouting(RoutingException e, HttpServletRequest req) {
        log.error("Routing error [{}]: {}", e.getErrorCode(), e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, e.getErrorCode(), e.getMessage(), req);
    }

    @ExceptionHandler(Throwable.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Throwable e, HttpServletRequest req) {
        log.error("Unexpected error: {}", e.getMessage(), e);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "An unexpected error occurred", req);
    }

    private ResponseEntity<ErrorResponse> response(HttpStatus status, String errorCode, String message, HttpServletRequest req) {
        return ResponseEntity.status(status)
                .body(ErrorResponse.of(status.value(), errorCode, message, req.getRequestURI()));
    }
}
