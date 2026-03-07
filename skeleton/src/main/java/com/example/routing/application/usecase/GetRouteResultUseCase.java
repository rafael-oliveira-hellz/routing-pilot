package com.example.routing.application.usecase;

import com.example.routing.application.port.in.GetRouteResultPort;
import com.example.routing.application.port.out.PoiQueryPort;
import com.example.routing.api.rest.dto.RouteResultResponse;
import com.example.routing.domain.enums.OptimizationStatus;
import com.example.routing.infrastructure.persistence.entity.RouteOptimizationJpaEntity;
import com.example.routing.infrastructure.persistence.entity.RouteResultJpaEntity;
import com.example.routing.infrastructure.persistence.entity.RouteSegmentJpaEntity;
import com.example.routing.infrastructure.persistence.entity.RouteWaypointJpaEntity;
import com.example.routing.infrastructure.persistence.repository.RouteOptimizationRepository;
import com.example.routing.infrastructure.persistence.repository.RouteResultRepository;
import com.example.routing.infrastructure.persistence.repository.RouteSegmentRepository;
import com.example.routing.infrastructure.persistence.repository.RouteWaypointRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GetRouteResultUseCase implements GetRouteResultPort {

    private final RouteOptimizationRepository optimizationRepo;
    private final RouteResultRepository resultRepo;
    private final RouteSegmentRepository segmentRepo;
    private final RouteWaypointRepository waypointRepo;
    private final PoiQueryPort poiQueryPort;
    private final JdbcTemplate jdbcTemplate;

    @Override
    public Optional<RouteResultResponse> getByRouteRequestId(UUID routeRequestId) {
        var optimizations = optimizationRepo.findByRouteRequestId(routeRequestId);
        Optional<RouteResultJpaEntity> resultOpt = optimizations.stream()
                .filter(o -> OptimizationStatus.COMPLETED.name().equals(o.getStatus()))
                .max(Comparator.comparing(RouteOptimizationJpaEntity::getCreatedAt))
                .flatMap(o -> resultRepo.findByOptimizationId(o.getId()));

        if (resultOpt.isEmpty()) {
            return Optional.empty();
        }

        RouteResultJpaEntity result = resultOpt.get();
        List<RouteSegmentJpaEntity> segments = segmentRepo.findByResultIdOrderBySegmentOrder(result.getId());

        // Por enquanto: trafficLevel com base nos incidentes (HEAVY_TRAFFIC ou severidade alta) — checklist Sprint 3
        Set<UUID> segmentIdsWithHeavyTraffic = segmentIdsWithHeavyTrafficFromIncidents(
                segments.stream().map(RouteSegmentJpaEntity::getId).toList());

        List<RouteResultResponse.SegmentDto> segmentDtos = segments.stream()
                .map(s -> {
                    String trafficLevel = s.getTrafficLevel();
                    if (trafficLevel == null && segmentIdsWithHeavyTraffic.contains(s.getId())) {
                        trafficLevel = "HEAVY";
                    }
                    if (trafficLevel == null) {
                        trafficLevel = "NORMAL";
                    }
                    return new RouteResultResponse.SegmentDto(
                            s.getId(),
                            s.getFromPoint(),
                            s.getToPoint(),
                            s.getDistanceMeters(),
                            s.getTravelTimeSeconds(),
                            trafficLevel
                    );
                })
                .collect(Collectors.toList());

        List<RouteWaypointJpaEntity> waypoints = waypointRepo.findByResultIdOrderBySequenceOrder(result.getId());
        double minLat = Double.MAX_VALUE, maxLat = -Double.MAX_VALUE, minLon = Double.MAX_VALUE, maxLon = -Double.MAX_VALUE;
        for (RouteWaypointJpaEntity wp : waypoints) {
            if (wp.getLocation() != null) {
                double lat = wp.getLocation().getY();
                double lon = wp.getLocation().getX();
                minLat = Math.min(minLat, lat); maxLat = Math.max(maxLat, lat);
                minLon = Math.min(minLon, lon); maxLon = Math.max(maxLon, lon);
            }
        }
        List<RouteResultResponse.LatLonDto> trafficLights = (minLat <= maxLat && minLon <= maxLon)
                ? poiQueryPort.findTrafficLightsInBbox(minLat, maxLat, minLon, maxLon)
                : List.of();

        return Optional.of(new RouteResultResponse(
                result.getTotalDistanceMeters(),
                result.getTotalDurationSeconds(),
                segmentDtos,
                trafficLights.isEmpty() ? null : trafficLights
        ));
    }

    /** Segmentos com incidente ativo do tipo HEAVY_TRAFFIC ou severidade HIGH/CRITICAL (tabela segment_incident_display). */
    private Set<UUID> segmentIdsWithHeavyTrafficFromIncidents(List<UUID> segmentIds) {
        if (segmentIds.isEmpty()) {
            return Set.of();
        }
        String inClause = segmentIds.stream().map(id -> "?::uuid").collect(Collectors.joining(","));
        String sql = """
            SELECT DISTINCT segment_id FROM segment_incident_display
            WHERE active = TRUE
              AND (incident_type = 'HEAVY_TRAFFIC' OR severity IN ('HIGH', 'CRITICAL'))
              AND segment_id IN (""" + inClause + ")
            ";
        List<UUID> list = jdbcTemplate.query(sql,
                (rs, i) -> UUID.fromString(rs.getString("segment_id")),
                segmentIds.toArray());
        return list != null ? Set.copyOf(list) : Set.of();
    }
}
