package com.example.routing.domain.model;

public record RouteProgress(
    String routeId,
    int routeVersion,
    int currentSegmentIndex,
    double distanceRemainingMeters,
    double distanceToCorridorMeters,
    double distanceToDestinationMeters
) {}
