package com.example.routing.engine.optimization;

import java.util.List;
import java.util.UUID;

public interface ApproximateRouteCreator {
    List<WaypointSequence> calculateRoute(List<Coordinate> points,
                                         UUID startingPointId,
                                         UUID destinationPointId);
}
