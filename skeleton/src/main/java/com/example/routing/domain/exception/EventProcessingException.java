package com.example.routing.domain.exception;

public class EventProcessingException extends RoutingException {

    public EventProcessingException(String message) {
        super("EVENT_PROCESSING_FAILED", message);
    }

    public EventProcessingException(String message, Throwable cause) {
        super("EVENT_PROCESSING_FAILED", message, cause);
    }
}
