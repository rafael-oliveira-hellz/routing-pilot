package com.example.routing.engine.optimization;

import java.util.List;
import java.util.UUID;

public class TwoThirdsApproximationRouteMaker implements ApproximateRouteCreator {
    private final SpanningTreeMaker spanningTreeMaker;
    private final ApproximationAlgorithm approximationAlgorithm;

    public TwoThirdsApproximationRouteMaker(SpanningTreeMaker spanningTreeMaker,
                                            ApproximationAlgorithm approximationAlgorithm) {
        this.spanningTreeMaker = spanningTreeMaker;
        this.approximationAlgorithm = approximationAlgorithm;
    }

    public static List<WaypointSequence> getWaypointSequences(UUID destId,
                                                             List<WaypointSequence> route,
                                                             WaypointSequence start) {
        if (start != null) { route.remove(start); route.add(0, start); }
        WaypointSequence dest = route.stream()
                .filter(r -> r.getWaypoints().getId().equals(destId)).findFirst().orElse(null);
        if (dest != null) { route.remove(dest); route.add(dest); }
        return route;
    }

    @Override
    public List<WaypointSequence> calculateRoute(List<Coordinate> points,
                                                 UUID startId, UUID destId) {
        ResultDTO result = spanningTreeMaker.getTree(points);
        List<WaypointSequence> route = approximationAlgorithm.getRoute(
                result.getCoordinates(), startId, destId);
        WaypointSequence start = route.stream()
                .filter(r -> r.getSequence() == 1).findFirst().orElse(null);
        return getWaypointSequences(destId, route, start);
    }
}
