package com.example.routing.domain.policy;

import com.example.routing.domain.model.RouteProgress;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class DestinationArrivalPolicy {

    private final double arrivalRadiusMeters;

    public DestinationArrivalPolicy(@Value("${routing.arrival.radius-meters:20}") double arrivalRadiusMeters) {
        this.arrivalRadiusMeters = arrivalRadiusMeters;
    }

    public boolean hasArrived(RouteProgress progress) {
        return progress.distanceToDestinationMeters() < arrivalRadiusMeters;
    }
}
