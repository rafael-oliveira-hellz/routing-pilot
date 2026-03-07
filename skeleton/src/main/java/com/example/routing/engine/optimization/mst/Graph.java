package com.example.routing.engine.optimization.mst;

import com.example.routing.engine.optimization.matrix.DistanceCalculator;
import com.example.routing.engine.optimization.model.Coordinate;
import com.example.routing.engine.optimization.model.CoordinatesWithDistance;

import java.util.*;

public class Graph {
    private final List<Coordinate> nodes;
    private final List<CoordinatesWithDistance> edges;

    public Graph(List<Coordinate> coordinates) {
        this.nodes = new ArrayList<>(coordinates);
        this.edges = new ArrayList<>();
        for (int i = 0; i < coordinates.size(); i++) {
            for (int j = i + 1; j < coordinates.size(); j++) {
                edges.add(DistanceCalculator.getDistanceBetweenTwoPoints(
                        coordinates.get(i), coordinates.get(j)));
            }
        }
        edges.sort(Comparator.comparingDouble(CoordinatesWithDistance::getDistance));
    }

    public List<Coordinate> getNodes() { return nodes; }
    public CoordinatesWithDistance getEdge(int i) { return edges.get(i); }
    public int edgeCount() { return edges.size(); }

    public Coordinate findParent(Map<Coordinate, NodeParents> subsets, Coordinate x) {
        NodeParents np = subsets.get(x);
        if (!np.getParent().equals(x)) np.setParent(findParent(subsets, np.getParent()));
        return np.getParent();
    }

    public void union(Map<Coordinate, NodeParents> subsets, Coordinate x, Coordinate y) {
        NodeParents px = subsets.get(x), py = subsets.get(y);
        if (px.getRank() < py.getRank()) px.setParent(y);
        else if (px.getRank() > py.getRank()) py.setParent(x);
        else { py.setParent(x); px.setRank(px.getRank() + 1); }
    }
}
