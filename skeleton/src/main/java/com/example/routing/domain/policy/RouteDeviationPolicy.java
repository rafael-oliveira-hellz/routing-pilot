package com.example.routing.domain.policy;

import com.example.routing.domain.model.GeoPoint;
import com.example.routing.domain.model.RouteProgress;
import com.example.routing.infrastructure.persistence.repository.OsmRoadRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
@Slf4j
public class RouteDeviationPolicy {

    private static final Set<String> HIGHWAY_TYPES = Set.of(
            "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link");

    private final double urbanThreshold;
    private final double highwayThreshold;
    private final OsmRoadRepository roadRepo;

    public RouteDeviationPolicy(
            @Value("${routing.deviation.urban-threshold-meters:40}") double urbanThreshold,
            @Value("${routing.deviation.highway-threshold-meters:80}") double highwayThreshold,
            OsmRoadRepository roadRepo) {
        this.urbanThreshold = urbanThreshold;
        this.highwayThreshold = highwayThreshold;
        this.roadRepo = roadRepo;
    }

    public boolean shouldRecalculate(RouteProgress progress, double heading,
                                     double segmentHeading) {
        double threshold = urbanThreshold;
        boolean corridorViolation = progress.distanceToCorridorMeters() > threshold;
        boolean headingMismatch = Math.abs(normalizeAngle(heading - segmentHeading)) > 60;
        return corridorViolation && headingMismatch;
    }

    public boolean shouldRecalculate(RouteProgress progress, GeoPoint vehiclePosition,
                                     double heading, double segmentHeading) {
        double threshold = isHighway(vehiclePosition) ? highwayThreshold : urbanThreshold;
        boolean corridorViolation = progress.distanceToCorridorMeters() > threshold;
        boolean headingMismatch = Math.abs(normalizeAngle(heading - segmentHeading)) > 60;
        return corridorViolation && headingMismatch;
    }

    private boolean isHighway(GeoPoint position) {
        try {
            return roadRepo.findNearestRoad(position.latitude(), position.longitude())
                    .map(road -> HIGHWAY_TYPES.contains(road.getHighway()))
                    .orElse(false);
        } catch (org.springframework.dao.DataAccessException e) {
            log.debug("Failed to query road type at {},{}: {}",
                    position.latitude(), position.longitude(), e.getMessage());
            return false;
        }
    }

    private double normalizeAngle(double angle) {
        angle = angle % 360;
        if (angle > 180) angle -= 360;
        if (angle < -180) angle += 360;
        return angle;
    }
}
