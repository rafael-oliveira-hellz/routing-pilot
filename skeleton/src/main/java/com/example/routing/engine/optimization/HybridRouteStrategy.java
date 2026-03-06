package com.example.routing.engine.optimization;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ForkJoinPool;

public class HybridRouteStrategy {
    private static final int DEFAULT_CLUSTER_SIZE = 150;

    public static List<WaypointSequence> solve(List<Coordinate> points,
                                               UUID startId, UUID destId,
                                               ApproximateRouteCreator creator) {
        if (points.size() <= 300) return TwoOptOptimizer.optimize(creator.calculateRoute(points, startId, destId));
        int cs = Math.min(DEFAULT_CLUSTER_SIZE, (int) Math.ceil(Math.sqrt(points.size() * 50)));
        var clusters = VRPClusterer.clusterByProximity(points, cs, startId, destId);
        ForkJoinPool pool = new ForkJoinPool(Runtime.getRuntime().availableProcessors());
        try {
            var merged = pool.submit(() -> clusters.parallelStream()
                    .map(c -> TwoOptOptimizer.optimize(creator.calculateRoute(c, startId, destId)))
                    .reduce(new ArrayList<>(), (a, b) -> { a.addAll(b); return a; })).get();
            return TwoThirdsApproximationRouteMaker.getWaypointSequences(destId, merged,
                    merged.stream().filter(w -> w.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Optimization interrupted", e);
        } catch (java.util.concurrent.ExecutionException e) {
            throw new RuntimeException("Optimization failed", e.getCause());
        }
        finally { pool.shutdown(); }
    }
}
