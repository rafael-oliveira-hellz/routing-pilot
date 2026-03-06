package com.example.routing.domain.validator;

import com.example.routing.domain.exception.DomainException;
import com.example.routing.domain.model.GeoPoint;
import com.example.routing.infrastructure.persistence.entity.RouteRequestJpaEntity;

import java.util.ArrayList;
import java.util.List;

public final class RouteRequestValidator {

    private RouteRequestValidator() {}

    public static void validate(RouteRequestJpaEntity request) {
        List<String> violations = new ArrayList<>();

        var points = request.getPoints();
        if (points.size() != 2) {
            violations.add("Exactly 1 origin and 1 destination required, got " + points.size());
        }

        var stops = request.getStops();
        if (stops.size() > 1000) {
            violations.add("Maximum 1000 stops exceeded: " + stops.size());
        }

        for (int i = 0; i < stops.size(); i++) {
            var stop = stops.get(i);
            try {
                new GeoPoint(stop.getLatitude(), stop.getLongitude());
            } catch (IllegalArgumentException e) {
                violations.add("Stop[" + i + "] invalid coordinates: " + e.getMessage());
            }
        }

        for (int i = 0; i < points.size(); i++) {
            var point = points.get(i);
            try {
                new GeoPoint(point.getLatitude(), point.getLongitude());
            } catch (IllegalArgumentException e) {
                violations.add("Point[" + i + "] invalid coordinates: " + e.getMessage());
            }
        }

        if (request.getDepartureAt() != null
                && request.getCreatedAt() != null
                && request.getDepartureAt().isBefore(request.getCreatedAt())) {
            violations.add("departure_at must be >= created_at");
        }

        if (!violations.isEmpty()) {
            throw new DomainException(
                    "Validation failed with " + violations.size() + " error(s)",
                    violations);
        }
    }
}
