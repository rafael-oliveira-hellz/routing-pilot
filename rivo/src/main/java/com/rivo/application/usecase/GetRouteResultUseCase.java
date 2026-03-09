package com.rivo.application.usecase;

import com.rivo.application.port.in.GetRouteResultPort;
import com.rivo.application.port.out.PoiQueryPort;
import com.rivo.api.rest.dto.RouteResultResponse;
import com.rivo.domain.enums.OptimizationStatus;
import com.rivo.infrastructure.persistence.entity.RouteOptimizationJpaEntity;
import com.rivo.infrastructure.persistence.entity.RouteResultJpaEntity;
import com.rivo.infrastructure.persistence.entity.RouteSegmentJpaEntity;
import com.rivo.infrastructure.persistence.entity.RouteWaypointJpaEntity;
import com.rivo.infrastructure.persistence.repository.RouteOptimizationRepository;
import com.rivo.infrastructure.persistence.repository.RouteResultRepository;
import com.rivo.infrastructure.persistence.repository.RouteSegmentRepository;
import com.rivo.infrastructure.persistence.repository.RouteWaypointRepository;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

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
        Set<UUID> segmentIdsWithHeavyTraffic = segmentIdsWithHeavyTrafficFromIncidents(
                segments.stream().map(RouteSegmentJpaEntity::getId).toList());

        List<RouteResultResponse.SegmentDto> segmentDtos = segments.stream()
                .map(segment -> {
                    String trafficLevel = segment.getTrafficLevel();
                    if (trafficLevel == null && segmentIdsWithHeavyTraffic.contains(segment.getId())) {
                        trafficLevel = "HEAVY";
                    }
                    if (trafficLevel == null) {
                        trafficLevel = "NORMAL";
                    }
                    return new RouteResultResponse.SegmentDto(
                            segment.getId(),
                            segment.getFromPoint(),
                            segment.getToPoint(),
                            segment.getDistanceMeters(),
                            segment.getTravelTimeSeconds(),
                            trafficLevel);
                })
                .collect(Collectors.toList());

        List<RouteWaypointJpaEntity> waypoints = waypointRepo.findByResultIdOrderBySequenceOrder(result.getId());
        double minLat = Double.MAX_VALUE;
        double maxLat = -Double.MAX_VALUE;
        double minLon = Double.MAX_VALUE;
        double maxLon = -Double.MAX_VALUE;
        for (RouteWaypointJpaEntity waypoint : waypoints) {
            if (waypoint.getLocation() != null) {
                double lat = waypoint.getLocation().getY();
                double lon = waypoint.getLocation().getX();
                minLat = Math.min(minLat, lat);
                maxLat = Math.max(maxLat, lat);
                minLon = Math.min(minLon, lon);
                maxLon = Math.max(maxLon, lon);
            }
        }
        List<RouteResultResponse.LatLonDto> trafficLights = (minLat <= maxLat && minLon <= maxLon)
                ? poiQueryPort.findTrafficLightsInBbox(minLat, maxLat, minLon, maxLon)
                : List.of();

        return Optional.of(new RouteResultResponse(
                result.getTotalDistanceMeters(),
                result.getTotalDurationSeconds(),
                segmentDtos,
                trafficLights.isEmpty() ? null : trafficLights));
    }

    private Set<UUID> segmentIdsWithHeavyTrafficFromIncidents(List<UUID> segmentIds) {
        if (segmentIds.isEmpty()) {
            return Set.of();
        }
        String inClause = segmentIds.stream().map(id -> "?::uuid").collect(Collectors.joining(","));
        String sql = "SELECT DISTINCT segment_id FROM segment_incident_display " +
                "WHERE active = TRUE " +
                "AND (incident_type = 'HEAVY_TRAFFIC' OR severity IN ('HIGH', 'CRITICAL')) " +
                "AND segment_id IN (" + inClause + ")";
        List<UUID> list = jdbcTemplate.query(
                sql,
                (rs, i) -> UUID.fromString(rs.getString("segment_id")),
                segmentIds.toArray());
        return list != null ? Set.copyOf(list) : Set.of();
    }
}
