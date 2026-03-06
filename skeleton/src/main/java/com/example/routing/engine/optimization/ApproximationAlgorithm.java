package com.example.routing.engine.optimization;

import java.util.List;
import java.util.UUID;

public interface ApproximationAlgorithm {
    List<WaypointSequence> getRoute(List<CoordinatesWithDistance> spanningTree,
                                   UUID startingPointId,
                                   UUID destinationPointId);
}
