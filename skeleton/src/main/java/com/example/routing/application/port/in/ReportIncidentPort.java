package com.example.routing.application.port.in;

import com.example.routing.domain.event.IncidentReportedEvent;

import java.util.UUID;

public interface ReportIncidentPort {
    UUID handle(IncidentReportedEvent event);
}
