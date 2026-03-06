package com.example.routing.domain.exception;

public class ResourceNotFoundException extends RoutingException {

    public ResourceNotFoundException(String resource, Object id) {
        super("NOT_FOUND", resource + " not found: " + id);
    }
}
