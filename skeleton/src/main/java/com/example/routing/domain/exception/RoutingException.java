package com.example.routing.domain.exception;

public abstract class RoutingException extends RuntimeException {

    private final String errorCode;

    protected RoutingException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    protected RoutingException(String errorCode, String message, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }

    public String getErrorCode() { return errorCode; }
}
