package com.rivo.domain.exception;

public class ForbiddenException extends RoutingException {

    public ForbiddenException(String message) {
        super("FORBIDDEN", message);
    }
}

