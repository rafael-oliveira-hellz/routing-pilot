package com.example.routing.engine.optimization.matrix;

import com.example.routing.engine.optimization.model.Coordinate;
import com.graphhopper.GHRequest;
import com.graphhopper.GraphHopper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.IntStream;

@Slf4j
@RequiredArgsConstructor
public class ParallelDistanceMatrix {

    private final GraphHopper hopper;
    private final ForkJoinPool pool;

    /**
     * Computes a symmetric distance matrix (meters) between all points using
     * GraphHopper CH queries in parallel across the ForkJoinPool.
     * Falls back to Haversine if GraphHopper is unavailable.
     */
    public double[][] compute(List<Coordinate> points) {
        int n = points.size();
        double[][] matrix = new double[n][n];

        if (hopper == null) {
            return computeHaversine(points, matrix, n);
        }

        pool.submit(() -> IntStream.range(0, n).parallel().forEach(i -> {
            Coordinate pi = points.get(i);
            for (int j = i + 1; j < n; j++) {
                Coordinate pj = points.get(j);
                double dist = queryDistance(pi, pj);
                matrix[i][j] = dist;
                matrix[j][i] = dist;
            }
        })).join();

        log.debug("Distance matrix {}x{} computed ({} pairs)", n, n, n * (n - 1) / 2);
        return matrix;
    }

    /**
     * Computes distances only for k-nearest neighbors per point (sparse matrix).
     * Uncomputed pairs remain 0 — caller must check.
     */
    public double[][] computeKNearest(List<Coordinate> points, int k) {
        int n = points.size();
        double[][] matrix = new double[n][n];
        int effectiveK = Math.min(k, n - 1);

        pool.submit(() -> IntStream.range(0, n).parallel().forEach(i -> {
            Coordinate pi = points.get(i);
            int[] nearest = findKNearestByHaversine(points, i, effectiveK);
            for (int jIdx : nearest) {
                if (matrix[i][jIdx] != 0 || i == jIdx) continue;
                double dist = queryDistance(pi, points.get(jIdx));
                matrix[i][jIdx] = dist;
                matrix[jIdx][i] = dist;
            }
        })).join();

        return matrix;
    }

    private double queryDistance(Coordinate from, Coordinate to) {
        try {
            var req = new GHRequest(from.getLatitude(), from.getLongitude(),
                                    to.getLatitude(), to.getLongitude())
                    .setProfile("car");
            var resp = hopper.route(req);
            if (resp.hasErrors()) {
                return DistanceCalculator.haversineMeters(from, to);
            }
            return resp.getBest().getDistance();
        } catch (com.example.routing.domain.exception.GraphHopperException e) {
            return DistanceCalculator.haversineMeters(from, to);
        } catch (IllegalArgumentException e) {
            return DistanceCalculator.haversineMeters(from, to);
        }
    }

    private int[] findKNearestByHaversine(List<Coordinate> points, int srcIdx, int k) {
        Coordinate src = points.get(srcIdx);
        return IntStream.range(0, points.size())
                .filter(j -> j != srcIdx)
                .boxed()
                .sorted((a, b) -> Double.compare(
                    DistanceCalculator.haversineMeters(src, points.get(a)),
                    DistanceCalculator.haversineMeters(src, points.get(b))))
                .limit(k)
                .mapToInt(Integer::intValue)
                .toArray();
    }

    private double[][] computeHaversine(List<Coordinate> points, double[][] matrix, int n) {
        for (int i = 0; i < n; i++) {
            for (int j = i + 1; j < n; j++) {
                double d = DistanceCalculator.haversineMeters(points.get(i), points.get(j));
                matrix[i][j] = d;
                matrix[j][i] = d;
            }
        }
        return matrix;
    }
}
