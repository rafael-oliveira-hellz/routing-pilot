package com.rivo.engine.optimization.tsp;

import com.rivo.engine.optimization.matrix.DistanceCalculator;
import com.rivo.engine.optimization.model.Coordinate;
import com.rivo.engine.optimization.model.CoordinatesWithDistance;
import com.rivo.engine.optimization.model.WaypointSequence;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.jgrapht.alg.matching.blossom.v5.KolmogorovWeightedPerfectMatching;
import org.jgrapht.alg.matching.blossom.v5.ObjectiveSense;
import org.jgrapht.graph.DefaultUndirectedWeightedGraph;
import org.jgrapht.graph.DefaultWeightedEdge;

public class ChristofidesRefactored implements ApproximationAlgorithm {
    private Map<UUID, ChristofidesVertex> vertices = new HashMap<>();
    private int time = 0;

    @Override
    public List<WaypointSequence> getRoute(List<CoordinatesWithDistance> spanningTree,
                                           UUID startingPointId, UUID destinationPointId) {
        generateVertices(spanningTree);
        List<ChristofidesVertex> oddVertices = getOddVertices();

        if (!oddVertices.isEmpty()) {
            var oddGraph = new DefaultUndirectedWeightedGraph<Coordinate, DefaultWeightedEdge>(
                    DefaultWeightedEdge.class);
            for (ChristofidesVertex vertex : oddVertices) {
                oddGraph.addVertex(vertex.getCoordinates());
            }
            for (int i = 0; i < oddVertices.size(); i++) {
                for (int j = i + 1; j < oddVertices.size(); j++) {
                    Coordinate origin = oddVertices.get(i).getCoordinates();
                    Coordinate destination = oddVertices.get(j).getCoordinates();
                    DefaultWeightedEdge edge = oddGraph.addEdge(origin, destination);
                    if (edge != null) {
                        oddGraph.setEdgeWeight(edge, DistanceCalculator.haversineMeters(origin, destination));
                    }
                }
            }
            var matching = new KolmogorovWeightedPerfectMatching<>(oddGraph, ObjectiveSense.MINIMIZE).getMatching();
            List<CoordinatesWithDistance> extra = new ArrayList<>();
            for (DefaultWeightedEdge edge : matching.getEdges()) {
                Coordinate source = oddGraph.getEdgeSource(edge);
                Coordinate target = oddGraph.getEdgeTarget(edge);
                extra.add(new CoordinatesWithDistance(source, target,
                        DistanceCalculator.haversineMeters(source, target)));
            }
            List<CoordinatesWithDistance> merged = new ArrayList<>(spanningTree.size() + extra.size());
            merged.addAll(spanningTree);
            merged.addAll(extra);
            vertices.clear();
            generateVertices(merged);
        }

        depthFirstSearch(vertices.get(startingPointId));
        ChristofidesVertex destination = vertices.get(destinationPointId);
        if (destination != null) {
            destination.setColor("red");
            destination.setFinishTime(++time);
        }
        vertices.get(startingPointId).setFinishTime(Integer.MIN_VALUE);

        List<WaypointSequence> route = buildFinalSequence(vertices, startingPointId, destinationPointId);
        vertices = new HashMap<>();
        return route;
    }

    private void generateVertices(List<CoordinatesWithDistance> edges) {
        for (CoordinatesWithDistance edge : edges) {
            vertices.putIfAbsent(edge.getOrigin().getId(), new ChristofidesVertex(edge.getOrigin()));
            vertices.putIfAbsent(edge.getDestination().getId(), new ChristofidesVertex(edge.getDestination()));
            ChristofidesVertex source = vertices.get(edge.getOrigin().getId());
            ChristofidesVertex destination = vertices.get(edge.getDestination().getId());
            if (source != null && destination != null) {
                source.addNeighbor(edge.getDestination());
                destination.addNeighbor(edge.getOrigin());
            }
        }
    }

    private List<ChristofidesVertex> getOddVertices() {
        return vertices.values().stream()
                .filter(vertex -> vertex.getNeighbors().size() % 2 != 0)
                .collect(Collectors.toList());
    }

    private void depthFirstSearch(ChristofidesVertex vertex) {
        time = 1;
        dfs(vertex);
    }

    private void dfs(ChristofidesVertex vertex) {
        vertex.setColor("red");
        vertex.setDiscoveryTime(++time);
        for (Coordinate neighbor : vertex.getNeighbors()) {
            ChristofidesVertex nextVertex = vertices.get(neighbor.getId());
            if (nextVertex != null && "black".equals(nextVertex.getColor())) {
                dfs(nextVertex);
            }
        }
        vertex.setColor("blue");
        vertex.setFinishTime(++time);
    }

    private List<WaypointSequence> buildFinalSequence(Map<UUID, ChristofidesVertex> map,
                                                      UUID startId, UUID destId) {
        List<WaypointSequence> output = new ArrayList<>();
        int[] sequence = {0};
        map.entrySet().stream()
                .sorted(Map.Entry.comparingByValue(Comparator.comparingInt(ChristofidesVertex::getFinishTime)))
                .forEach(entry -> output.add(new WaypointSequence(entry.getValue().getCoordinates(), ++sequence[0])));
        return TwoThirdsApproximationRouteMaker.getWaypointSequences(
                destId,
                output,
                output.stream().filter(waypoint -> waypoint.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
    }
}
