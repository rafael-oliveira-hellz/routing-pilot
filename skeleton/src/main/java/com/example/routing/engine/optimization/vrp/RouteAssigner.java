package com.example.routing.engine.optimization.vrp;

import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.WaypointSequence;
import com.example.routing.engine.optimization.tsp.ApproximateRouteCreator;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class RouteAssigner {

    public static List<List<WaypointSequence>> assignRoutes(List<Coordinate> allPoints,
                                                           int vehicleCount,
                                                           UUID startId, UUID destId,
                                                           ApproximateRouteCreator creator) {
        var clusters = VRPClusterer.clusterByProximity(
                allPoints, (allPoints.size() + vehicleCount - 1) / vehicleCount, startId, destId);
        List<List<WaypointSequence>> routes = new ArrayList<>();
        for (var cluster : clusters) routes.add(creator.calculateRoute(cluster, startId, destId));
        return routes;
    }
}
