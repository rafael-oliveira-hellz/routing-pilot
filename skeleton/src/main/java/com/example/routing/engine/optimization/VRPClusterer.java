package com.example.routing.engine.optimization;

import java.util.*;
import java.util.stream.Collectors;

public class VRPClusterer {

    public static List<List<Coordinate>> clusterByProximity(List<Coordinate> points,
                                                            int maxClusterSize,
                                                            UUID depotStartId,
                                                            UUID depotDestId) {
        if (points.size() <= maxClusterSize) return Collections.singletonList(new ArrayList<>(points));
        Coordinate depot = points.stream()
                .filter(p -> p.getId().equals(depotStartId) || p.getId().equals(depotDestId))
                .findFirst().orElse(points.get(0));
        List<Coordinate> rest = points.stream()
                .filter(p -> !p.getId().equals(depotStartId) && !p.getId().equals(depotDestId))
                .collect(Collectors.toList());
        int k = (int) Math.ceil((double) rest.size() / maxClusterSize);
        return kMeans(rest, k, depot);
    }

    private static List<List<Coordinate>> kMeans(List<Coordinate> points, int k, Coordinate depot) {
        if (k >= points.size()) {
            List<List<Coordinate>> s = new ArrayList<>();
            for (Coordinate p : points) s.add(Collections.singletonList(p));
            return s;
        }
        Random rnd = new Random(42);
        List<Coordinate> centroids = new ArrayList<>();
        Set<Integer> used = new HashSet<>();
        for (int i = 0; i < k; i++) {
            int idx = rnd.nextInt(points.size());
            while (used.contains(idx)) idx = rnd.nextInt(points.size());
            used.add(idx); centroids.add(points.get(idx));
        }
        List<List<Coordinate>> clusters = new ArrayList<>();
        for (int i = 0; i < k; i++) clusters.add(new ArrayList<>());
        for (int iter = 0; iter < 20; iter++) {
            for (var c : clusters) c.clear();
            for (Coordinate p : points) {
                int best = 0; double bestD = Double.MAX_VALUE;
                for (int j = 0; j < k; j++) {
                    double d = DistanceCalculator.haversineMeters(p, centroids.get(j));
                    if (d < bestD) { bestD = d; best = j; }
                }
                clusters.get(best).add(p);
            }
            for (int j = 0; j < k; j++) {
                var c = clusters.get(j);
                if (c.isEmpty()) continue;
                double sLat = 0, sLon = 0;
                for (var p : c) { sLat += p.getLatitude(); sLon += p.getLongitude(); }
                centroids.set(j, Coordinate.builder()
                        .id(UUID.randomUUID()).name("centroid")
                        .latitude(sLat / c.size()).longitude(sLon / c.size()).build());
            }
        }
        List<List<Coordinate>> result = new ArrayList<>();
        for (var cluster : clusters) {
            if (cluster.isEmpty()) continue;
            List<Coordinate> withDepot = new ArrayList<>();
            withDepot.add(depot); withDepot.addAll(cluster); withDepot.add(depot);
            result.add(withDepot);
        }
        return result;
    }
}
