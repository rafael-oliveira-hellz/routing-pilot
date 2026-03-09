package com.rivo.domain.exception;

public class ConcurrencyLimitExceededException extends RoutingException {

    public ConcurrencyLimitExceededException(String message) {
        super("CONCURRENCY_LIMIT_EXCEEDED", message);
    }
}


