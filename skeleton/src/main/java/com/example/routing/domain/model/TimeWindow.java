package com.example.routing.domain.model;

import java.time.Instant;

public record TimeWindow(Instant start, Instant end) {
    public TimeWindow {
        if (start != null && end != null && end.isBefore(start))
            throw new IllegalArgumentException("TimeWindow end must be >= start");
    }

    public boolean contains(Instant instant) {
        return (start == null || !instant.isBefore(start))
            && (end == null || !instant.isAfter(end));
    }
}
