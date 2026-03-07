package com.example.routing.application.usecase;

import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.application.port.out.VehicleStateStore;
import com.example.routing.domain.enums.OptimizationStatus;
import com.example.routing.domain.enums.VehicleStatus;
import com.example.routing.domain.event.OptimizationFailedEvent;
import com.example.routing.domain.event.RecalculateRouteRequested;
import com.example.routing.domain.event.RouteRecalculatedEvent;
import com.example.routing.domain.exception.DomainException;
import com.example.routing.domain.exception.GraphHopperException;
import com.example.routing.domain.exception.OptimizationException;
import com.example.routing.engine.optimization.orchestration.ParallelRouteEngine;
import com.example.routing.engine.optimization.mst.KruskalSpanningTree;
import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.WaypointSequence;
import com.example.routing.engine.optimization.routing.GraphHopperSegmentRouter;
import com.example.routing.engine.optimization.tsp.ChristofidesRefactored;
import com.example.routing.engine.optimization.tsp.TwoThirdsApproximationRouteMaker;
import com.example.routing.infrastructure.persistence.entity.*;
import com.example.routing.infrastructure.persistence.repository.*;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RecalculateRouteUseCase {

    private final RouteOptimizationRepository optimizationRepo;
    private final RouteResultRepository resultRepo;
    private final RouteWaypointRepository waypointRepo;
    private final RouteSegmentRepository segmentRepo;
    private final RouteStopRepository stopRepo;
    private final VehicleStateStore stateStore;
    private final EventPublisher eventPublisher;
    private final GraphHopperSegmentRouter segmentRouter;
    private final MeterRegistry meterRegistry;

    @Value("${routing.optimization.cluster-size:150}")
    private int clusterSize;

    @CircuitBreaker(name = "routeOptimization", fallbackMethod = "handleFallback")
    @Transactional
    public void handle(RecalculateRouteRequested event) {
        Timer.Sample sample = Timer.start(meterRegistry);
        UUID optimizationId = UUID.randomUUID();
        Instant now = Instant.now();

        log.info("Recalculating route: vehicle={} route={} reason={}",
                event.vehicleId(), event.routeId(), event.reason());

        optimizationRepo.save(RouteOptimizationJpaEntity.builder()
                .id(optimizationId)
                .routeRequestId(UUID.fromString(event.routeId()))
                .status(OptimizationStatus.RUNNING.name())
                .createdAt(now)
                .build());

        try {
            List<RouteStopJpaEntity> stops = stopRepo.findByRouteRequestIdOrderBySequenceOrder(
                    UUID.fromString(event.routeId()));

            List<Coordinate> points = stops.stream()
                    .map(s -> Coordinate.builder()
                            .id(s.getId())
                            .latitude(s.getLatitude())
                            .longitude(s.getLongitude())
                            .name(s.getIdentifier())
                            .build())
                    .collect(Collectors.toList());

            if (points.size() < 2) {
                throw new IllegalStateException("Not enough points for optimization: " + points.size());
            }

            UUID startId = points.get(0).getId();
            UUID destId = points.get(points.size() - 1).getId();

            var spanningTreeMaker = new KruskalSpanningTree();
            var christofides = new ChristofidesRefactored();
            var routeCreator = new TwoThirdsApproximationRouteMaker(spanningTreeMaker, christofides);
            var engine = new ParallelRouteEngine(routeCreator,
                    Runtime.getRuntime().availableProcessors(), true, 4);

            List<WaypointSequence> optimizedRoute;
            try {
                optimizedRoute = engine.calculateLarge(points, startId, destId, clusterSize);
            } finally {
                engine.shutdown();
            }

            List<Coordinate> orderedPoints = optimizedRoute.stream()
                    .map(WaypointSequence::getWaypoints)
                    .toList();
            var segments = segmentRouter.routeSegments(orderedPoints);

            double totalDist = segments.stream().mapToDouble(GraphHopperSegmentRouter.SegmentResult::distanceMeters).sum();
            double totalDur = segments.stream().mapToDouble(GraphHopperSegmentRouter.SegmentResult::durationSeconds).sum();

            RouteResultJpaEntity result = resultRepo.save(RouteResultJpaEntity.builder()
                    .id(UUID.randomUUID())
                    .optimizationId(optimizationId)
                    .totalDistanceMeters(totalDist)
                    .totalDurationSeconds(totalDur)
                    .build());

            GeometryFactory gf = new GeometryFactory(new PrecisionModel(), 4326);
            List<RouteWaypointJpaEntity> waypoints = new ArrayList<>();
            for (int i = 0; i < orderedPoints.size(); i++) {
                Coordinate c = orderedPoints.get(i);
                waypoints.add(RouteWaypointJpaEntity.builder()
                        .id(UUID.randomUUID())
                        .resultId(result.getId())
                        .sequenceOrder(i + 1)
                        .location(gf.createPoint(new org.locationtech.jts.geom.Coordinate(c.getLongitude(), c.getLatitude())))
                        .build());
            }
            waypointRepo.saveAll(waypoints);

            List<RouteSegmentJpaEntity> segmentEntities = new ArrayList<>();
            for (int i = 0; i < segments.size(); i++) {
                GraphHopperSegmentRouter.SegmentResult sr = segments.get(i);
                List<double[]> pts = sr.geometryPoints();
                org.locationtech.jts.geom.Coordinate[] coords = pts.stream()
                        .map(p -> new org.locationtech.jts.geom.Coordinate(p[1], p[0]))
                        .toArray(org.locationtech.jts.geom.Coordinate[]::new);
                LineString pathGeometry = coords.length >= 2 ? gf.createLineString(coords) : null;
                segmentEntities.add(RouteSegmentJpaEntity.builder()
                        .resultId(result.getId())
                        .fromPoint(waypoints.get(i).getId())
                        .toPoint(waypoints.get(i + 1).getId())
                        .segmentOrder(i + 1)
                        .distanceMeters(sr.distanceMeters())
                        .travelTimeSeconds(sr.durationSeconds())
                        .pathGeometry(pathGeometry)
                        .trafficLevel(null)
                        .build());
            }
            segmentRepo.saveAll(segmentEntities);

            optimizationRepo.save(RouteOptimizationJpaEntity.builder()
                    .id(optimizationId)
                    .routeRequestId(UUID.fromString(event.routeId()))
                    .status(OptimizationStatus.COMPLETED.name())
                    .createdAt(now)
                    .build());

            stateStore.load(event.vehicleId()).ifPresent(state ->
                    stateStore.save(state.withStatus(VehicleStatus.IN_PROGRESS)));

            eventPublisher.publish("route.recalc.completed." + event.vehicleId(),
                    new RouteRecalculatedEvent(UUID.randomUUID(),
                            UUID.fromString(event.routeId()), optimizationId,
                            Instant.now(), totalDist, totalDur, optimizedRoute.size()));

            sample.stop(Timer.builder("optimization.duration")
                    .tag("status", "success")
                    .register(meterRegistry));

            log.info("Route recalculated: vehicle={} points={} distance={}m duration={}s",
                    event.vehicleId(), optimizedRoute.size(), (int) totalDist, (int) totalDur);

        } catch (DomainException e) {
            log.error("Route recalculation validation failed: vehicle={} reason={}",
                    event.vehicleId(), e.getMessage());
            markFailed(optimizationId, event, now, sample, e.getMessage());
        } catch (OptimizationException e) {
            log.error("Route optimization engine failed: vehicle={}", event.vehicleId(), e);
            markFailed(optimizationId, event, now, sample, e.getMessage());
        } catch (GraphHopperException e) {
            log.error("GraphHopper failed during recalculation: vehicle={}", event.vehicleId(), e);
            markFailed(optimizationId, event, now, sample, e.getMessage());
        } catch (org.springframework.dao.DataAccessException e) {
            log.error("Database error during recalculation: vehicle={}", event.vehicleId(), e);
            markFailed(optimizationId, event, now, sample, e.getMessage());
        }
    }

    private void markFailed(UUID optimizationId, RecalculateRouteRequested event,
                            Instant now, Timer.Sample sample, String reason) {
        optimizationRepo.save(RouteOptimizationJpaEntity.builder()
                .id(optimizationId)
                .routeRequestId(UUID.fromString(event.routeId()))
                .status(OptimizationStatus.FAILED.name())
                .createdAt(now)
                .build());

        stateStore.load(event.vehicleId()).ifPresent(state ->
                stateStore.save(state.withStatus(VehicleStatus.DEGRADED_ESTIMATE)));

        eventPublisher.publish("route.recalc.failed." + event.vehicleId(),
                new OptimizationFailedEvent(UUID.randomUUID(),
                        UUID.fromString(event.routeId()), Instant.now(), reason));

        sample.stop(Timer.builder("optimization.duration")
                .tag("status", "failed")
                .register(meterRegistry));
    }

    @SuppressWarnings("unused")
    private void handleFallback(RecalculateRouteRequested event, Throwable t) {
        log.error("Circuit breaker OPEN for route optimization. vehicle={} error={}",
                event.vehicleId(), t.getMessage());
        stateStore.load(event.vehicleId()).ifPresent(state ->
                stateStore.save(state.withStatus(VehicleStatus.DEGRADED_ESTIMATE)));
        eventPublisher.publish("route.recalc.failed." + event.vehicleId(),
                new OptimizationFailedEvent(UUID.randomUUID(),
                        UUID.fromString(event.routeId()), Instant.now(),
                        "Circuit breaker open: " + t.getMessage()));
    }
}
