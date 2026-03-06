package com.example.routing.application.port.in;

import com.example.routing.domain.event.LocationUpdatedEvent;

public interface ProcessLocationUpdatePort {
    void handle(LocationUpdatedEvent event);
}
