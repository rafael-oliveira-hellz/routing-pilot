package com.example.routing.domain.model;

import com.example.routing.domain.enums.VehicleStatus;

import java.time.Instant;

public record VehicleState(
    String vehicleId,
    GeoPoint currentPosition,
    double heading,
    double speedMps,
    VehicleStatus status,
    EtaState eta,
    RouteProgress routeProgress,
    Instant lastRecalculationAt,
    int recalcCountLastMinute,
    Instant lastProcessedAt
) {
    public VehicleState withPosition(GeoPoint pos, double heading, double speed, Instant now) {
        return new VehicleState(vehicleId, pos, heading, speed, status, eta,
                routeProgress, lastRecalculationAt, recalcCountLastMinute, now);
    }

    public VehicleState withEta(EtaState newEta) {
        return new VehicleState(vehicleId, currentPosition, heading, speedMps, status,
                newEta, routeProgress, lastRecalculationAt, recalcCountLastMinute, lastProcessedAt);
    }

    public VehicleState withStatus(VehicleStatus newStatus) {
        return new VehicleState(vehicleId, currentPosition, heading, speedMps, newStatus,
                eta, routeProgress, lastRecalculationAt, recalcCountLastMinute, lastProcessedAt);
    }

    public VehicleState withRecalculation(Instant now) {
        return new VehicleState(vehicleId, currentPosition, heading, speedMps,
                VehicleStatus.RECALCULATING, eta, routeProgress, now,
                recalcCountLastMinute + 1, lastProcessedAt);
    }
}
