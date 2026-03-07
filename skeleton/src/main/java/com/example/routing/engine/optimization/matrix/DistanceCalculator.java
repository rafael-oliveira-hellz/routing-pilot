package com.example.routing.engine.optimization.matrix;

import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.CoordinatesWithDistance;
import com.example.routing.engine.optimization.model.WaypointSequence;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class DistanceCalculator {
    private static final double EARTH_RADIUS_KM = 6371.0;

    private DistanceCalculator() {}

    public static CoordinatesWithDistance getDistanceBetweenTwoPoints(
            Coordinate source, Coordinate destination) {
        if (Objects.equals(source.getLatitude(), destination.getLatitude())
                && Objects.equals(source.getLongitude(), destination.getLongitude())) {
            return new CoordinatesWithDistance(source, destination, 0.0);
        }
        return new CoordinatesWithDistance(source, destination, haversineMeters(source, destination));
    }

    public static double haversineMeters(Coordinate p1, Coordinate p2) {
        double lat1 = Math.toRadians(p1.getLatitude());
        double lon1 = Math.toRadians(p1.getLongitude());
        double lat2 = Math.toRadians(p2.getLatitude());
        double lon2 = Math.toRadians(p2.getLongitude());
        double dLat = lat2 - lat1, dLon = lon2 - lon1;
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 1000;
    }

    public static double haversineKm(Coordinate p1, Coordinate p2) {
        return haversineMeters(p1, p2) / 1000.0;
    }

    public static Double round(double value, int decimals) {
        return Math.round(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
    }

    public static List<CoordinatesWithDistance> calculateDistancesBetweenPoints(
            List<WaypointSequence> waypoints) {
        List<CoordinatesWithDistance> distances = new ArrayList<>(waypoints.size() - 1);
        for (int i = 0; i < waypoints.size() - 1; i++) {
            Coordinate p1 = waypoints.get(i).getWaypoints();
            Coordinate p2 = waypoints.get(i + 1).getWaypoints();
            distances.add(new CoordinatesWithDistance(p1, p2, haversineMeters(p1, p2)));
        }
        return distances;
    }
}
