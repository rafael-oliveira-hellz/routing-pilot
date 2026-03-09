package com.rivo.engine.optimization.tsp;

import com.rivo.engine.optimization.model.CoordinatesWithDistance;
import com.rivo.engine.optimization.model.WaypointSequence;

import java.util.List;
import java.util.UUID;

public interface ApproximationAlgorithm {
    List<WaypointSequence> getRoute(List<CoordinatesWithDistance> spanningTree,
                                   UUID startingPointId,
                                   UUID destinationPointId);
}


