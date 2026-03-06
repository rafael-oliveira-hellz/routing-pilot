package com.example.routing.domain.policy;

import com.example.routing.domain.enums.IncidentSeverity;
import com.example.routing.domain.model.ActiveIncident;
import com.example.routing.domain.model.GeoPoint;
import com.example.routing.domain.model.PolicyDecision;
import com.example.routing.domain.model.RouteProgress;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class IncidentImpactPolicy {

    public PolicyDecision evaluate(RouteProgress progress, GeoPoint vehiclePosition,
                                   List<ActiveIncident> incidents) {
        double factor = computeIncidentFactor(vehiclePosition, incidents);
        if (factor >= 1.4) {
            return PolicyDecision.RECALCULATE;
        }
        return PolicyDecision.ETA_ONLY;
    }

    public double computeIncidentFactor(GeoPoint vehiclePosition, List<ActiveIncident> incidents) {
        if (incidents == null || incidents.isEmpty()) return 1.0;
        return incidents.stream()
                .filter(i -> i.isWithinRadius(vehiclePosition))
                .mapToDouble(i -> severityToFactor(i.severity()))
                .max()
                .orElse(1.0);
    }

    private double severityToFactor(IncidentSeverity severity) {
        return switch (severity) {
            case LOW -> 1.05;
            case MEDIUM -> 1.15;
            case HIGH -> 1.35;
            case CRITICAL -> 1.60;
        };
    }
}
