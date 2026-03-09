package com.rivo.application.port.in;

import com.rivo.domain.event.LocationUpdatedEvent;

public interface ProcessLocationUpdatePort {
    void handle(LocationUpdatedEvent event);
}


