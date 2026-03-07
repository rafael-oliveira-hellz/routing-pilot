package com.example.routing.domain.exception;

/**
 * Lançada quando o rate limit é excedido (ex.: POST /api/v1/locations).
 * O handler REST devolve 429 e o header Retry-After (segundos).
 */
public class RateLimitExceededException extends RoutingException {

    private final int retryAfterSeconds;

    public RateLimitExceededException(String message) {
        this(message, 60);
    }

    public RateLimitExceededException(String message, int retryAfterSeconds) {
        super("RATE_LIMIT_EXCEEDED", message);
        this.retryAfterSeconds = retryAfterSeconds;
    }

    public int getRetryAfterSeconds() {
        return retryAfterSeconds;
    }
}
