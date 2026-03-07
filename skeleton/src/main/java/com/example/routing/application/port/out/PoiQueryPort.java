package com.example.routing.application.port.out;

import com.example.routing.api.rest.dto.RouteResultResponse;

import java.util.List;

/** Port para consultar POIs (ex.: semáforos). Usado no GET result (trafficLightsAlongRoute) e GET /api/v1/pois. */
public interface PoiQueryPort {

    /**
     * POIs por tipo em área (lat/lon + raio em metros). Ex.: type=TRAFFIC_LIGHT.
     */
    List<PoiDto> findByLocationAndType(double lat, double lon, double radiusMeters, String type);

    /**
     * Semáforos dentro da bbox (para preencher trafficLightsAlongRoute no resultado da rota).
     */
    List<RouteResultResponse.LatLonDto> findTrafficLightsInBbox(double minLat, double maxLat, double minLon, double maxLon);

    record PoiDto(String id, double lat, double lon, String type) {}
}
