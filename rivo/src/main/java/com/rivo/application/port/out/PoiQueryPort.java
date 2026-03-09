package com.rivo.application.port.out;

import com.rivo.api.rest.dto.RouteResultResponse;

import java.util.List;

/** Port para consultar POIs (ex.: sem??foros). Usado no GET result (trafficLightsAlongRoute) e GET /api/v1/pois. */
public interface PoiQueryPort {

    /**
     * POIs por tipo em ??rea (lat/lon + raio em metros). Ex.: type=TRAFFIC_LIGHT.
     */
    List<PoiDto> findByLocationAndType(double lat, double lon, double radiusMeters, String type);

    /**
     * Sem??foros dentro da bbox (para preencher trafficLightsAlongRoute no resultado da rota).
     */
    List<RouteResultResponse.LatLonDto> findTrafficLightsInBbox(double minLat, double maxLat, double minLon, double maxLon);

    record PoiDto(String id, double lat, double lon, String type) {}
}


