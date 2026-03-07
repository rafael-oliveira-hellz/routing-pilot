package com.example.routing.api.rest.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.UUID;

/** Resposta do GET /api/v1/route-requests/{id}/result. Consumido pelo app (mapa: trafficLevel, trafficLightsAlongRoute). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record RouteResultResponse(
    double totalDistanceMeters,
    double totalDurationSeconds,
    List<SegmentDto> segments,
    List<LatLonDto> trafficLightsAlongRoute
) {
    public record SegmentDto(
        UUID id,
        UUID fromPoint,
        UUID toPoint,
        double distanceMeters,
        double travelTimeSeconds,
        String trafficLevel
    ) {}

    public record LatLonDto(double lat, double lon) {}
}
