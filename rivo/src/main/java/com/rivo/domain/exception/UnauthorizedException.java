package com.rivo.domain.exception;

public class UnauthorizedException extends RoutingException {

    public UnauthorizedException(String message) {
        super("UNAUTHORIZED", message);
    }

    public UnauthorizedException(String message, Throwable cause) {
        super("UNAUTHORIZED", message, cause);
    }
}

