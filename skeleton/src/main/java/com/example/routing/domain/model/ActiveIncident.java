package com.example.routing.domain.model;

import com.example.routing.domain.enums.IncidentSeverity;
import com.example.routing.domain.enums.IncidentType;

import java.time.Instant;
import java.util.UUID;

public record ActiveIncident(
    UUID incidentId,
    IncidentType incidentType,
    IncidentSeverity severity,
    GeoPoint location,
    int radiusMeters,
    RegionTile tile,
    Instant expiresAt
) {
    /**
     * Checks if a given position is within the incident's radius of influence.
     */
    public boolean isWithinRadius(GeoPoint position) {
        double dist = haversineMeters(
                location.latitude(), location.longitude(),
                position.latitude(), position.longitude());
        return dist <= radiusMeters;
    }

    /**
     * Checks if a given route segment (defined by two endpoints) passes through the incident zone.
     */
    public boolean affectsSegment(GeoPoint segStart, GeoPoint segEnd) {
        double distToStart = haversineMeters(location.latitude(), location.longitude(),
                segStart.latitude(), segStart.longitude());
        double distToEnd = haversineMeters(location.latitude(), location.longitude(),
                segEnd.latitude(), segEnd.longitude());
        double segLen = haversineMeters(segStart.latitude(), segStart.longitude(),
                segEnd.latitude(), segEnd.longitude());

        if (distToStart <= radiusMeters || distToEnd <= radiusMeters) return true;

        if (segLen < 1.0) return false;
        double t = Math.max(0, Math.min(1,
                dotProduct(segStart, segEnd, location) / (segLen * segLen)));
        double projLat = segStart.latitude() + t * (segEnd.latitude() - segStart.latitude());
        double projLon = segStart.longitude() + t * (segEnd.longitude() - segStart.longitude());
        double distToProj = haversineMeters(location.latitude(), location.longitude(), projLat, projLon);
        return distToProj <= radiusMeters;
    }

    private static double dotProduct(GeoPoint a, GeoPoint b, GeoPoint p) {
        return (p.latitude() - a.latitude()) * (b.latitude() - a.latitude())
             + (p.longitude() - a.longitude()) * (b.longitude() - a.longitude());
    }

    private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371000;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
