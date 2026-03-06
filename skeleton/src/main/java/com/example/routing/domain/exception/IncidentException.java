package com.example.routing.domain.exception;

public class IncidentException extends RoutingException {

    public IncidentException(String message) {
        super("INCIDENT_ERROR", message);
    }

    public IncidentException(String message, Throwable cause) {
        super("INCIDENT_ERROR", message, cause);
    }
}
