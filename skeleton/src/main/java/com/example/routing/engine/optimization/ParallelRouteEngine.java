package com.example.routing.engine.optimization;

import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveTask;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

@Slf4j
public class ParallelRouteEngine {
    private final ApproximateRouteCreator routeCreator;
    private final ForkJoinPool pool;
    private final boolean useTwoOpt;
    private final Semaphore concurrencyLimiter;

    public ParallelRouteEngine(ApproximateRouteCreator routeCreator,
                               int parallelism, boolean useTwoOpt,
                               int maxConcurrentJobs) {
        this.routeCreator = routeCreator;
        this.pool = new ForkJoinPool(parallelism > 0 ? parallelism : Runtime.getRuntime().availableProcessors());
        this.useTwoOpt = useTwoOpt;
        this.concurrencyLimiter = new Semaphore(maxConcurrentJobs > 0 ? maxConcurrentJobs : 4);
    }

    public List<WaypointSequence> calculate(List<Coordinate> points, UUID startId, UUID destId) {
        return calculate(points, startId, destId, null);
    }

    /**
     * @param previousRoute warm-start: if non-null, used as initial tour for 2-opt (converges faster)
     */
    public List<WaypointSequence> calculate(List<Coordinate> points, UUID startId, UUID destId,
                                            List<WaypointSequence> previousRoute) {
        var route = routeCreator.calculateRoute(points, startId, destId);
        if (useTwoOpt && route.size() >= 4) {
            List<WaypointSequence> initial = (previousRoute != null && previousRoute.size() == route.size())
                    ? previousRoute : route;
            return TwoOptOptimizer.optimize(initial);
        }
        return route;
    }

    public List<WaypointSequence> calculateLarge(List<Coordinate> points,
                                                 UUID startId, UUID destId, int clusterSize) {
        return calculateLarge(points, startId, destId, clusterSize, null);
    }

    public List<WaypointSequence> calculateLarge(List<Coordinate> points,
                                                 UUID startId, UUID destId, int clusterSize,
                                                 List<WaypointSequence> previousRoute) {
        if (points.size() <= clusterSize) return calculate(points, startId, destId, previousRoute);

        boolean acquired = false;
        try {
            acquired = concurrencyLimiter.tryAcquire(30, TimeUnit.SECONDS);
            if (!acquired) {
                log.warn("Concurrency limit reached, job queued for 30s and timed out. Points={}", points.size());
                throw new RuntimeException("Optimization concurrency limit exceeded");
            }

            var clusters = VRPClusterer.clusterByProximity(points, clusterSize, startId, destId);
            log.info("Optimization job: {} points, {} clusters, warm-start={}",
                    points.size(), clusters.size(), previousRoute != null);

            List<RecursiveTask<List<WaypointSequence>>> tasks = new ArrayList<>();
            for (var cluster : clusters) {
                tasks.add(new RouteTask(cluster, startId, destId, routeCreator, useTwoOpt));
            }
            return pool.invoke(new MergeTask(tasks, startId, destId));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Optimization interrupted", e);
        } finally {
            if (acquired) concurrencyLimiter.release();
        }
    }

    public int availablePermits() {
        return concurrencyLimiter.availablePermits();
    }

    public void shutdown() { pool.shutdown(); }

    private static class RouteTask extends RecursiveTask<List<WaypointSequence>> {
        private final List<Coordinate> points;
        private final UUID startId, destId;
        private final ApproximateRouteCreator creator;
        private final boolean useTwoOpt;

        RouteTask(List<Coordinate> p, UUID s, UUID d, ApproximateRouteCreator c, boolean t) {
            points = p; startId = s; destId = d; creator = c; useTwoOpt = t;
        }

        @Override
        protected List<WaypointSequence> compute() {
            var r = creator.calculateRoute(points, startId, destId);
            return (useTwoOpt && r.size() >= 4) ? TwoOptOptimizer.optimize(r) : r;
        }
    }

    private static class MergeTask extends RecursiveTask<List<WaypointSequence>> {
        private final List<RecursiveTask<List<WaypointSequence>>> tasks;
        private final UUID startId, destId;

        MergeTask(List<RecursiveTask<List<WaypointSequence>>> t, UUID s, UUID d) {
            tasks = t; startId = s; destId = d;
        }

        @Override
        protected List<WaypointSequence> compute() {
            for (var t : tasks) t.fork();
            List<WaypointSequence> merged = new ArrayList<>();
            for (var t : tasks) merged.addAll(t.join());
            return TwoThirdsApproximationRouteMaker.getWaypointSequences(destId, merged,
                    merged.stream().filter(w -> w.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
        }
    }
}
