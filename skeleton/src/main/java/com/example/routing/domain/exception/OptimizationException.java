package com.example.routing.domain.exception;

public class OptimizationException extends RoutingException {

    public OptimizationException(String message) {
        super("OPTIMIZATION_FAILED", message);
    }

    public OptimizationException(String message, Throwable cause) {
        super("OPTIMIZATION_FAILED", message, cause);
    }
}
