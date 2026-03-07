package com.example.routing.engine.optimization.tsp;

import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.WaypointSequence;

import java.util.List;
import java.util.UUID;

public interface ApproximateRouteCreator {
    List<WaypointSequence> calculateRoute(List<Coordinate> points,
                                         UUID startingPointId,
                                         UUID destinationPointId);
}
