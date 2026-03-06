package com.example.routing.engine.optimization;

import java.util.*;

/**
 * Greedy nearest-neighbor matching for odd-degree vertices.
 * O(n^2), no risk of explosion. Used as fallback when Blossom V exceeds timeout.
 */
public class GreedyMatching {

    public static List<CoordinatesWithDistance> match(List<ChristofidesVertex> oddVertices) {
        List<CoordinatesWithDistance> pairs = new ArrayList<>();
        Set<UUID> matched = new HashSet<>();

        List<ChristofidesVertex> sorted = new ArrayList<>(oddVertices);
        sorted.sort(Comparator.comparing(v -> v.getId().toString()));

        for (ChristofidesVertex v : sorted) {
            if (matched.contains(v.getId())) continue;

            ChristofidesVertex nearest = null;
            double nearestDist = Double.MAX_VALUE;

            for (ChristofidesVertex u : sorted) {
                if (u.equals(v) || matched.contains(u.getId())) continue;
                double d = DistanceCalculator.haversineMeters(v.getCoordinates(), u.getCoordinates());
                if (d < nearestDist) {
                    nearestDist = d;
                    nearest = u;
                }
            }

            if (nearest != null) {
                pairs.add(new CoordinatesWithDistance(
                        v.getCoordinates(), nearest.getCoordinates(), nearestDist));
                matched.add(v.getId());
                matched.add(nearest.getId());
            }
        }
        return pairs;
    }
}
