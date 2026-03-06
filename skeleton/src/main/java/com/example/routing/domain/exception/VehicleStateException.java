package com.example.routing.domain.exception;

public class VehicleStateException extends RoutingException {

    public VehicleStateException(String message) {
        super("VEHICLE_STATE_ERROR", message);
    }

    public VehicleStateException(String message, Throwable cause) {
        super("VEHICLE_STATE_ERROR", message, cause);
    }
}
