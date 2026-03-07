package com.example.routing.infrastructure.persistence.adapter;

import com.example.routing.application.port.out.PoiQueryPort;
import com.example.routing.api.rest.dto.RouteResultResponse;
import com.example.routing.infrastructure.persistence.entity.OsmPoiEntity;
import com.example.routing.infrastructure.persistence.repository.OsmPoiRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Implementação de {@link PoiQueryPort} usando geo.osm_pois (V004).
 * Semáforos (TRAFFIC_LIGHT) no OSM vêm de highway=traffic_signals em geo.osm_other.
 */
@Component
@RequiredArgsConstructor
public class OsmPoiQueryAdapter implements PoiQueryPort {

    private static final String TYPE_TRAFFIC_LIGHT = "TRAFFIC_LIGHT";

    private final OsmPoiRepository osmPoiRepository;
    private final JdbcTemplate jdbcTemplate;

    @Override
    public List<PoiDto> findByLocationAndType(double lat, double lon, double radiusMeters, String type) {
        if (TYPE_TRAFFIC_LIGHT.equals(type)) {
            return findTrafficSignalsNear(lat, lon, radiusMeters);
        }
        List<OsmPoiEntity> pois = osmPoiRepository.findNearbyByType(lat, lon, radiusMeters, type);
        return pois.stream()
                .map(this::toPoiDto)
                .toList();
    }

    @Override
    public List<RouteResultResponse.LatLonDto> findTrafficLightsInBbox(double minLat, double maxLat, double minLon, double maxLon) {
        return findTrafficSignalsInBbox(minLat, maxLat, minLon, maxLon);
    }

    private List<PoiDto> findTrafficSignalsNear(double lat, double lon, double radiusMeters) {
        String sql = """
            SELECT ST_Y(geom::geometry) as lat, ST_X(geom::geometry) as lon
            FROM geo.osm_other
            WHERE osm_type = 'node'
              AND tags->>'highway' = 'traffic_signals'
              AND geom IS NOT NULL
              AND ST_DWithin(
                geom::geography,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
              )
            """;
        return jdbcTemplate.query(sql, (rs, i) -> {
            double la = rs.getDouble("lat");
            double lo = rs.getDouble("lon");
            return new PoiDto("osm_node_" + lo + "_" + la, la, lo, TYPE_TRAFFIC_LIGHT);
        }, lon, lat, radiusMeters);
    }

    private List<RouteResultResponse.LatLonDto> findTrafficSignalsInBbox(double minLat, double maxLat, double minLon, double maxLon) {
        String sql = """
            SELECT ST_Y(geom::geometry) as lat, ST_X(geom::geometry) as lon
            FROM geo.osm_other
            WHERE osm_type = 'node'
              AND tags->>'highway' = 'traffic_signals'
              AND geom IS NOT NULL
              AND ST_Within(geom, ST_MakeEnvelope(?, ?, ?, ?, 4326))
            """;
        List<RouteResultResponse.LatLonDto> list = jdbcTemplate.query(sql,
                (rs, i) -> new RouteResultResponse.LatLonDto(rs.getDouble("lat"), rs.getDouble("lon")),
                minLon, minLat, maxLon, maxLat);
        return list != null ? list : new ArrayList<>();
    }

    private PoiDto toPoiDto(OsmPoiEntity e) {
        String type = e.getAmenity() != null ? e.getAmenity() : e.getShop() != null ? e.getShop() : e.getTourism();
        double lat = e.getGeom() != null ? e.getGeom().getY() : 0;
        double lon = e.getGeom() != null ? e.getGeom().getX() : 0;
        return new PoiDto(String.valueOf(e.getOsmId()), lat, lon, type != null ? type : "");
    }
}
