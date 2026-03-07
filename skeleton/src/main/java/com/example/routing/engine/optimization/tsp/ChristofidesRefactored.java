package com.example.routing.engine.optimization.tsp;

import com.example.routing.engine.optimization.matrix.DistanceCalculator;
import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.CoordinatesWithDistance;
import com.example.routing.engine.optimization.model.WaypointSequence;
import org.jgrapht.alg.matching.blossom.v5.KolmogorovMinimumWeightPerfectMatching;
import org.jgrapht.graph.DefaultUndirectedWeightedGraph;
import org.jgrapht.graph.DefaultWeightedEdge;

import java.util.*;
import java.util.stream.Collectors;

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
            for (ChristofidesVertex v : oddVertices) oddGraph.addVertex(v.getCoordinates());
            for (int i = 0; i < oddVertices.size(); i++) {
                for (int j = i + 1; j < oddVertices.size(); j++) {
                    Coordinate o = oddVertices.get(i).getCoordinates();
                    Coordinate d = oddVertices.get(j).getCoordinates();
                    DefaultWeightedEdge e = oddGraph.addEdge(o, d);
                    if (e != null) oddGraph.setEdgeWeight(e, DistanceCalculator.haversineMeters(o, d));
                }
            }
            var matching = new KolmogorovMinimumWeightPerfectMatching<>(oddGraph).getMatching();
            List<CoordinatesWithDistance> extra = new ArrayList<>();
            for (var edge : matching.getEdges()) {
                Coordinate src = oddGraph.getEdgeSource(edge), dst = oddGraph.getEdgeTarget(edge);
                extra.add(new CoordinatesWithDistance(src, dst,
                        DistanceCalculator.haversineMeters(src, dst)));
            }
            List<CoordinatesWithDistance> merged = new ArrayList<>(spanningTree.size() + extra.size());
            merged.addAll(spanningTree);
            merged.addAll(extra);
            vertices.clear();
            generateVertices(merged);
        }

        depthFirstSearch(vertices.get(startingPointId));
        ChristofidesVertex dest = vertices.get(destinationPointId);
        if (dest != null) { dest.setColor("red"); dest.setFinishTime(++time); }
        vertices.get(startingPointId).setFinishTime(Integer.MIN_VALUE);

        List<WaypointSequence> route = buildFinalSequence(vertices, startingPointId, destinationPointId);
        vertices = new HashMap<>();
        return route;
    }

    private void generateVertices(List<CoordinatesWithDistance> edges) {
        for (CoordinatesWithDistance edge : edges) {
            vertices.putIfAbsent(edge.getOrigin().getId(), new ChristofidesVertex(edge.getOrigin()));
            vertices.putIfAbsent(edge.getDestination().getId(), new ChristofidesVertex(edge.getDestination()));
            ChristofidesVertex src = vertices.get(edge.getOrigin().getId());
            ChristofidesVertex dst = vertices.get(edge.getDestination().getId());
            if (src != null && dst != null) {
                src.addNeighbor(edge.getDestination());
                dst.addNeighbor(edge.getOrigin());
            }
        }
    }

    private List<ChristofidesVertex> getOddVertices() {
        return vertices.values().stream()
                .filter(v -> v.getNeighbors().size() % 2 != 0)
                .collect(Collectors.toList());
    }

    private void depthFirstSearch(ChristofidesVertex v) { time = 1; dfs(v); }

    private void dfs(ChristofidesVertex v) {
        v.setColor("red");
        v.setDiscoveryTime(++time);
        for (Coordinate n : v.getNeighbors()) {
            ChristofidesVertex nv = vertices.get(n.getId());
            if (nv != null && "black".equals(nv.getColor())) dfs(nv);
        }
        v.setColor("blue");
        v.setFinishTime(++time);
    }

    private List<WaypointSequence> buildFinalSequence(Map<UUID, ChristofidesVertex> map,
                                                      UUID startId, UUID destId) {
        List<WaypointSequence> out = new ArrayList<>();
        int[] seq = {0};
        map.entrySet().stream()
                .sorted(Map.Entry.comparingByValue(Comparator.comparingInt(ChristofidesVertex::getFinishTime)))
                .forEach(e -> out.add(new WaypointSequence(e.getValue().getCoordinates(), ++seq[0])));
        return TwoThirdsApproximationRouteMaker.getWaypointSequences(destId, out,
                out.stream().filter(w -> w.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
    }
}
