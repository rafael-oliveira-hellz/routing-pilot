package com.example.routing.engine.optimization;

import java.util.ArrayList;
import java.util.List;

public class TwoOptOptimizer {

    public static List<WaypointSequence> optimize(List<WaypointSequence> tour) {
        if (tour == null || tour.size() < 4) return tour;
        List<WaypointSequence> current = new ArrayList<>(tour);
        boolean improved = true;
        while (improved) {
            improved = false;
            for (int i = 0; i < current.size() - 2; i++) {
                for (int k = i + 2; k < current.size(); k++) {
                    if (k == current.size() - 1 && i == 0) continue;
                    double delta = computeDelta(current, i, k);
                    if (delta < -1e-9) {
                        reverse(current, i + 1, k);
                        improved = true;
                        break;
                    }
                }
                if (improved) break;
            }
        }
        return renumber(current);
    }

    private static double computeDelta(List<WaypointSequence> t, int i, int k) {
        Coordinate a = t.get(i).getWaypoints(), b = t.get(i + 1).getWaypoints();
        Coordinate c = t.get(k).getWaypoints(), d = t.get((k + 1) % t.size()).getWaypoints();
        return (DistanceCalculator.haversineMeters(a, c) + DistanceCalculator.haversineMeters(b, d))
             - (DistanceCalculator.haversineMeters(a, b) + DistanceCalculator.haversineMeters(c, d));
    }

    private static void reverse(List<WaypointSequence> l, int from, int to) {
        while (from < to) { var tmp = l.get(from); l.set(from++, l.get(to)); l.set(to--, tmp); }
    }

    private static List<WaypointSequence> renumber(List<WaypointSequence> l) {
        List<WaypointSequence> out = new ArrayList<>();
        for (int i = 0; i < l.size(); i++) out.add(new WaypointSequence(l.get(i).getWaypoints(), i + 1));
        return out;
    }
}
