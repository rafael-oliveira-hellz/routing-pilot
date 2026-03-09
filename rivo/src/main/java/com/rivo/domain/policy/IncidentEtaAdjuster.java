package com.rivo.domain.policy;

import com.rivo.domain.enums.IncidentSeverity;
import com.rivo.domain.model.ActiveIncident;
import com.rivo.domain.model.GeoPoint;
import com.rivo.domain.model.RouteProgress;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class IncidentEtaAdjuster {

    private static final Map<IncidentSeverity, Double> PENALTY = Map.of(
        IncidentSeverity.LOW, 1.05,
        IncidentSeverity.MEDIUM, 1.15,
        IncidentSeverity.HIGH, 1.30,
        IncidentSeverity.CRITICAL, 1.50
    );

    /**
     * Computes the worst-case ETA penalty factor based on active incidents
     * near the vehicle's current position. Uses spatial radius check.
     */
    public double computeIncidentFactor(GeoPoint vehiclePosition, List<ActiveIncident> incidents) {
        if (incidents == null || incidents.isEmpty()) return 1.0;

        double maxFactor = 1.0;
        for (ActiveIncident incident : incidents) {
            if (incident.isWithinRadius(vehiclePosition)) {
                double f = PENALTY.getOrDefault(incident.severity(), 1.0);
                maxFactor = Math.max(maxFactor, f);
            }
        }
        return maxFactor;
    }

    /**
     * Overload that accepts RouteProgress for backward compatibility.
     * Requires vehicle position to be passed separately.
     */
    public double computeIncidentFactor(RouteProgress progress, GeoPoint vehiclePosition,
                                        List<ActiveIncident> incidents) {
        return computeIncidentFactor(vehiclePosition, incidents);
    }
}


