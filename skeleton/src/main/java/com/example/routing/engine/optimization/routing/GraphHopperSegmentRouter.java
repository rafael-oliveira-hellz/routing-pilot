package com.example.routing.engine.optimization.routing;

import com.example.routing.engine.optimization.matrix.DistanceCalculator;
import com.example.routing.engine.optimization.model.Coordinate;
import com.graphhopper.GHRequest;
import com.graphhopper.GraphHopper;
import com.graphhopper.ResponsePath;
import com.graphhopper.util.PointList;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.IntStream;

@Slf4j
@RequiredArgsConstructor
public class GraphHopperSegmentRouter {

    private final GraphHopper hopper;
    private final ForkJoinPool pool;

    public record SegmentResult(
        double distanceMeters,
        double durationSeconds,
        String geometryEncoded,
        List<double[]> geometryPoints
    ) {}

    /**
     * Routes each consecutive pair of waypoints through the road network in parallel.
     */
    public List<SegmentResult> routeSegments(List<Coordinate> orderedWaypoints) {
        int n = orderedWaypoints.size();
        SegmentResult[] results = new SegmentResult[n - 1];

        pool.submit(() -> IntStream.range(0, n - 1).parallel().forEach(i -> {
            Coordinate from = orderedWaypoints.get(i);
            Coordinate to = orderedWaypoints.get(i + 1);
            results[i] = routeSingle(from, to);
        })).join();

        return java.util.Arrays.asList(results);
    }

    private SegmentResult routeSingle(Coordinate from, Coordinate to) {
        try {
            var req = new GHRequest(from.getLatitude(), from.getLongitude(),
                                    to.getLatitude(), to.getLongitude())
                    .setProfile("car");
            var resp = hopper.route(req);

            if (resp.hasErrors()) {
                log.warn("GraphHopper routing failed {}->{}: {}", from.getId(), to.getId(), resp.getErrors());
                return fallback(from, to);
            }

            ResponsePath best = resp.getBest();
            PointList points = best.getPoints();
            List<double[]> geom = IntStream.range(0, points.size())
                    .mapToObj(i -> new double[]{points.getLat(i), points.getLon(i)})
                    .toList();

            return new SegmentResult(
                best.getDistance(),
                best.getTime() / 1000.0,
                best.getPoints().toLineString(false).toString(),
                geom
            );
        } catch (com.example.routing.domain.exception.GraphHopperException e) {
            log.warn("GraphHopper routing error {}->{}: {}", from.getId(), to.getId(), e.getMessage());
            return fallback(from, to);
        } catch (IllegalArgumentException e) {
            log.warn("GraphHopper invalid input {}->{}: {}", from.getId(), to.getId(), e.getMessage());
            return fallback(from, to);
        }
    }

    private SegmentResult fallback(Coordinate from, Coordinate to) {
        double dist = DistanceCalculator.haversineMeters(from, to);
        double duration = dist / 13.9; // ~50 km/h default
        return new SegmentResult(dist, duration, null,
            List.of(
                new double[]{from.getLatitude(), from.getLongitude()},
                new double[]{to.getLatitude(), to.getLongitude()}
            ));
    }
}
