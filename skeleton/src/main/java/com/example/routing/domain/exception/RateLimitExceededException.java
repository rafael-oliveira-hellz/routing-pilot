package com.example.routing.domain.exception;

public class RateLimitExceededException extends RoutingException {

    public RateLimitExceededException(String message) {
        super("RATE_LIMIT_EXCEEDED", message);
    }
}
