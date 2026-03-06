package com.example.routing.domain.exception;

public class GraphHopperException extends RoutingException {

    public GraphHopperException(String message) {
        super("GRAPHHOPPER_ERROR", message);
    }

    public GraphHopperException(String message, Throwable cause) {
        super("GRAPHHOPPER_ERROR", message, cause);
    }
}
