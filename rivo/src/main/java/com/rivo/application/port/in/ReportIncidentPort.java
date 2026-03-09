package com.rivo.application.port.in;

import com.rivo.domain.event.IncidentReportedEvent;

import java.util.UUID;

public interface ReportIncidentPort {
    UUID handle(IncidentReportedEvent event);
}


