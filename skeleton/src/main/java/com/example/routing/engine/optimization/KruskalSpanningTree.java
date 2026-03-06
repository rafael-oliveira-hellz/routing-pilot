package com.example.routing.engine.optimization;

import lombok.extern.slf4j.Slf4j;

import java.util.*;

@Slf4j
public class KruskalSpanningTree implements SpanningTreeMaker {

    @Override
    public ResultDTO getTree(List<Coordinate> coordinates) {
        Graph graph = new Graph(coordinates);
        Map<Coordinate, NodeParents> subsets = new HashMap<>();
        for (Coordinate node : graph.getNodes()) {
            subsets.put(node, new NodeParents(node, 0));
        }
        List<CoordinatesWithDistance> result = new ArrayList<>();
        double cost = 0;
        int edgesNeeded = coordinates.size() - 1;
        int edgesAdded = 0, edgeIndex = 0;
        while (edgesAdded < edgesNeeded) {
            CoordinatesWithDistance edge = graph.getEdge(edgeIndex++);
            Coordinate root1 = graph.findParent(subsets, edge.getOrigin());
            Coordinate root2 = graph.findParent(subsets, edge.getDestination());
            if (!root1.equals(root2)) {
                result.add(edge);
                cost += edge.getDistance();
                graph.union(subsets, root1, root2);
                edgesAdded++;
            }
        }
        log.info("MST total distance: [{}] km", DistanceCalculator.round(cost / 1000.0, 2));
        return ResultDTO.builder()
                .coordinates(result)
                .totalDistance(DistanceCalculator.round(cost / 1000.0, 2))
                .build();
    }
}
