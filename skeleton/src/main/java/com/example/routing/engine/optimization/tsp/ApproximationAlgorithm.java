package com.example.routing.engine.optimization.tsp;

import com.example.routing.engine.optimization.model.CoordinatesWithDistance;
import com.example.routing.engine.optimization.model.WaypointSequence;

import java.util.List;
import java.util.UUID;

public interface ApproximationAlgorithm {
    List<WaypointSequence> getRoute(List<CoordinatesWithDistance> spanningTree,
                                   UUID startingPointId,
                                   UUID destinationPointId);
}
