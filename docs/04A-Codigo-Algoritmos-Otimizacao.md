# 04A - Código Completo dos Algoritmos de Otimização

> Este documento contém todo o código refatorado dos helpers de otimização,
> na ordem de implementação (Sprint 3).
> Todos os `id` e `boundToId` são `UUID`.
>
> **Por que cada algoritmo (Kruskal, Edmonds Blossom, Christofides, 2-opt, VRPClusterer, ForkJoinPool)** está explicado no [doc 04 - Contexto OptimizationEngine](./04-Contexto-OptimizationEngine.md), seção *Por que cada algoritmo e otimização*.

## 1. Interfaces base

```java
package com.example.routing.engine.optimization;

import java.util.List;
import java.util.UUID;

public interface SpanningTreeMaker {
    ResultDTO getTree(List<Coordinate> coordinates);
}

public interface ApproximationAlgorithm {
    List<WaypointSequence> getRoute(List<CoordinatesWithDistance> spanningTree,
                                   UUID startingPointId,
                                   UUID destinationPointId);
}

public interface ApproximateRouteCreator {
    List<WaypointSequence> calculateRoute(List<Coordinate> points,
                                         UUID startingPointId,
                                         UUID destinationPointId);
}
```

## 2. Modelos internos do engine

```java
package com.example.routing.engine.optimization;

import com.example.routing.domain.enums.RouteType;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Coordinate {
    private UUID id;
    private String name;
    private Double latitude;
    private Double longitude;
    private RouteType type;
    private UUID boundToId;
    private Integer loadingTime;
    private Integer unloadingTime;
    private LocalDateTime initialDateTime;
    private LocalDateTime finalDateTime;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CoordinatesWithDistance {
    private Coordinate origin;
    private Coordinate destination;
    private Double distance;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WaypointSequence {
    private Coordinate waypoints;
    private Integer sequence;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ResultDTO {
    private List<CoordinatesWithDistance> coordinates;
    private Double totalDistance;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ChristofidesVertex {
    private Coordinate coordinates;
    private List<Coordinate> neighbors = new ArrayList<>();
    private String color = "black";
    private int discoveryTime;
    private int finishTime;

    public ChristofidesVertex(Coordinate coordinates) {
        this.coordinates = coordinates;
    }
    public UUID getId() { return coordinates.getId(); }
    public void addNeighbor(Coordinate c) { neighbors.add(c); }
}

@Getter @Setter
public class NodeParents {
    private Coordinate parent;
    private int rank;
    public NodeParents(Coordinate parent, int rank) {
        this.parent = parent;
        this.rank = rank;
    }
}
```

## 3. Graph (Kruskal support)

```java
package com.example.routing.engine.optimization;

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
```

## 4. DistanceCalculator - O(1) por par

```java
package com.example.routing.engine.optimization;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class DistanceCalculator {
    private static final double EARTH_RADIUS_KM = 6371.0;
    private DistanceCalculator() {}

    public static CoordinatesWithDistance getDistanceBetweenTwoPoints(
            Coordinate source, Coordinate destination) {
        if (Objects.equals(source.getLatitude(), destination.getLatitude())
                && Objects.equals(source.getLongitude(), destination.getLongitude())) {
            return new CoordinatesWithDistance(source, destination, 0.0);
        }
        return new CoordinatesWithDistance(source, destination, haversineMeters(source, destination));
    }

    public static double haversineMeters(Coordinate p1, Coordinate p2) {
        double lat1 = Math.toRadians(p1.getLatitude());
        double lon1 = Math.toRadians(p1.getLongitude());
        double lat2 = Math.toRadians(p2.getLatitude());
        double lon2 = Math.toRadians(p2.getLongitude());
        double dLat = lat2 - lat1, dLon = lon2 - lon1;
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 1000;
    }

    public static double haversineKm(Coordinate p1, Coordinate p2) {
        return haversineMeters(p1, p2) / 1000.0;
    }

    public static Double round(double value, int decimals) {
        return Math.round(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
    }

    public static List<CoordinatesWithDistance> calculateDistancesBetweenPoints(
            List<WaypointSequence> waypoints) {
        List<CoordinatesWithDistance> distances = new ArrayList<>(waypoints.size() - 1);
        for (int i = 0; i < waypoints.size() - 1; i++) {
            Coordinate p1 = waypoints.get(i).getWaypoints();
            Coordinate p2 = waypoints.get(i + 1).getWaypoints();
            distances.add(new CoordinatesWithDistance(p1, p2, haversineMeters(p1, p2)));
        }
        return distances;
    }
}
```

## 5. KruskalSpanningTree - O(n² log n)

```java
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
```

## 6. ChristofidesRefactored - Edmonds Blossom V (3/2-approx)

```java
package com.example.routing.engine.optimization;

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
```

## 7. TwoOptOptimizer - O(n²) por iteração

```java
package com.example.routing.engine.optimization;

import java.util.ArrayList;
import java.util.List;

public class TwoOptOptimizer {
    public static List<WaypointSequence> optimize(List<WaypointSequence> tour) {
        if (tour == null || tour.size() < 4) return tour;
        List<WaypointSequence> current = new ArrayList<>(tour);
        boolean improved = true;
        while (improved) {
            improved = false;
            for (int i = 0; i < current.size() - 2; i++) {
                for (int k = i + 2; k < current.size(); k++) {
                    if (k == current.size() - 1 && i == 0) continue;
                    double delta = computeDelta(current, i, k);
                    if (delta < -1e-9) {
                        reverse(current, i + 1, k);
                        improved = true;
                        break;
                    }
                }
                if (improved) break;
            }
        }
        return renumber(current);
    }

    private static double computeDelta(List<WaypointSequence> t, int i, int k) {
        Coordinate a = t.get(i).getWaypoints(), b = t.get(i + 1).getWaypoints();
        Coordinate c = t.get(k).getWaypoints(), d = t.get((k + 1) % t.size()).getWaypoints();
        return (DistanceCalculator.haversineMeters(a, c) + DistanceCalculator.haversineMeters(b, d))
             - (DistanceCalculator.haversineMeters(a, b) + DistanceCalculator.haversineMeters(c, d));
    }

    private static void reverse(List<WaypointSequence> l, int from, int to) {
        while (from < to) { var tmp = l.get(from); l.set(from++, l.get(to)); l.set(to--, tmp); }
    }

    private static List<WaypointSequence> renumber(List<WaypointSequence> l) {
        List<WaypointSequence> out = new ArrayList<>();
        for (int i = 0; i < l.size(); i++) out.add(new WaypointSequence(l.get(i).getWaypoints(), i + 1));
        return out;
    }
}
```

## 8. TwoThirdsApproximationRouteMaker (orquestrador)

```java
package com.example.routing.engine.optimization;

import java.util.List;
import java.util.UUID;

public class TwoThirdsApproximationRouteMaker implements ApproximateRouteCreator {
    private final SpanningTreeMaker spanningTreeMaker;
    private final ApproximationAlgorithm approximationAlgorithm;

    public TwoThirdsApproximationRouteMaker(SpanningTreeMaker spanningTreeMaker,
                                            ApproximationAlgorithm approximationAlgorithm) {
        this.spanningTreeMaker = spanningTreeMaker;
        this.approximationAlgorithm = approximationAlgorithm;
    }

    public static List<WaypointSequence> getWaypointSequences(UUID destId,
                                                             List<WaypointSequence> route,
                                                             WaypointSequence start) {
        if (start != null) { route.remove(start); route.add(0, start); }
        WaypointSequence dest = route.stream()
                .filter(r -> r.getWaypoints().getId().equals(destId)).findFirst().orElse(null);
        if (dest != null) { route.remove(dest); route.add(dest); }
        return route;
    }

    @Override
    public List<WaypointSequence> calculateRoute(List<Coordinate> points,
                                                 UUID startId, UUID destId) {
        ResultDTO result = spanningTreeMaker.getTree(points);
        List<WaypointSequence> route = approximationAlgorithm.getRoute(
                result.getCoordinates(), startId, destId);
        WaypointSequence start = route.stream()
                .filter(r -> r.getSequence() == 1).findFirst().orElse(null);
        return getWaypointSequences(destId, route, start);
    }
}
```

## 9. VRPClusterer + RouteAssigner

```java
package com.example.routing.engine.optimization;

import java.util.*;
import java.util.stream.Collectors;

public class VRPClusterer {
    public static List<List<Coordinate>> clusterByProximity(List<Coordinate> points,
                                                            int maxClusterSize,
                                                            UUID depotStartId,
                                                            UUID depotDestId) {
        if (points.size() <= maxClusterSize) return Collections.singletonList(new ArrayList<>(points));
        Coordinate depot = points.stream()
                .filter(p -> p.getId().equals(depotStartId) || p.getId().equals(depotDestId))
                .findFirst().orElse(points.get(0));
        List<Coordinate> rest = points.stream()
                .filter(p -> !p.getId().equals(depotStartId) && !p.getId().equals(depotDestId))
                .collect(Collectors.toList());
        int k = (int) Math.ceil((double) rest.size() / maxClusterSize);
        return kMeans(rest, k, depot);
    }

    private static List<List<Coordinate>> kMeans(List<Coordinate> points, int k, Coordinate depot) {
        if (k >= points.size()) {
            List<List<Coordinate>> s = new ArrayList<>();
            for (Coordinate p : points) s.add(Collections.singletonList(p));
            return s;
        }
        Random rnd = new Random(42);
        List<Coordinate> centroids = new ArrayList<>();
        Set<Integer> used = new HashSet<>();
        for (int i = 0; i < k; i++) {
            int idx = rnd.nextInt(points.size());
            while (used.contains(idx)) idx = rnd.nextInt(points.size());
            used.add(idx); centroids.add(points.get(idx));
        }
        List<List<Coordinate>> clusters = new ArrayList<>();
        for (int i = 0; i < k; i++) clusters.add(new ArrayList<>());
        for (int iter = 0; iter < 20; iter++) {
            for (var c : clusters) c.clear();
            for (Coordinate p : points) {
                int best = 0; double bestD = Double.MAX_VALUE;
                for (int j = 0; j < k; j++) {
                    double d = DistanceCalculator.haversineMeters(p, centroids.get(j));
                    if (d < bestD) { bestD = d; best = j; }
                }
                clusters.get(best).add(p);
            }
            for (int j = 0; j < k; j++) {
                var c = clusters.get(j);
                if (c.isEmpty()) continue;
                double sLat = 0, sLon = 0;
                for (var p : c) { sLat += p.getLatitude(); sLon += p.getLongitude(); }
                centroids.set(j, Coordinate.builder()
                        .id(UUID.randomUUID()).name("centroid")
                        .latitude(sLat / c.size()).longitude(sLon / c.size()).build());
            }
        }
        List<List<Coordinate>> result = new ArrayList<>();
        for (var cluster : clusters) {
            if (cluster.isEmpty()) continue;
            List<Coordinate> withDepot = new ArrayList<>();
            withDepot.add(depot); withDepot.addAll(cluster); withDepot.add(depot);
            result.add(withDepot);
        }
        return result;
    }
}

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
```

## 10. ParallelRouteEngine + HybridRouteStrategy

```java
package com.example.routing.engine.optimization;

import lombok.extern.slf4j.Slf4j;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveTask;

@Slf4j
public class ParallelRouteEngine {
    private final ApproximateRouteCreator routeCreator;
    private final ForkJoinPool pool;
    private final boolean useTwoOpt;

    public ParallelRouteEngine(ApproximateRouteCreator routeCreator, int parallelism, boolean useTwoOpt) {
        this.routeCreator = routeCreator;
        this.pool = new ForkJoinPool(parallelism > 0 ? parallelism : Runtime.getRuntime().availableProcessors());
        this.useTwoOpt = useTwoOpt;
    }

    public List<WaypointSequence> calculate(List<Coordinate> points, UUID startId, UUID destId) {
        var route = routeCreator.calculateRoute(points, startId, destId);
        return (useTwoOpt && route.size() >= 4) ? TwoOptOptimizer.optimize(route) : route;
    }

    public List<WaypointSequence> calculateLarge(List<Coordinate> points,
                                                 UUID startId, UUID destId, int clusterSize) {
        if (points.size() <= clusterSize) return calculate(points, startId, destId);
        var clusters = VRPClusterer.clusterByProximity(points, clusterSize, startId, destId);
        List<RecursiveTask<List<WaypointSequence>>> tasks = new ArrayList<>();
        for (var cluster : clusters) tasks.add(new RouteTask(cluster, startId, destId, routeCreator, useTwoOpt));
        return pool.invoke(new MergeTask(tasks, startId, destId));
    }

    public void shutdown() { pool.shutdown(); }

    private static class RouteTask extends RecursiveTask<List<WaypointSequence>> {
        private final List<Coordinate> points;
        private final UUID startId, destId;
        private final ApproximateRouteCreator creator;
        private final boolean useTwoOpt;
        RouteTask(List<Coordinate> p, UUID s, UUID d, ApproximateRouteCreator c, boolean t) {
            points = p; startId = s; destId = d; creator = c; useTwoOpt = t;
        }
        @Override protected List<WaypointSequence> compute() {
            var r = creator.calculateRoute(points, startId, destId);
            return (useTwoOpt && r.size() >= 4) ? TwoOptOptimizer.optimize(r) : r;
        }
    }

    private static class MergeTask extends RecursiveTask<List<WaypointSequence>> {
        private final List<RecursiveTask<List<WaypointSequence>>> tasks;
        private final UUID startId, destId;
        MergeTask(List<RecursiveTask<List<WaypointSequence>>> t, UUID s, UUID d) {
            tasks = t; startId = s; destId = d;
        }
        @Override protected List<WaypointSequence> compute() {
            List<WaypointSequence> merged = new ArrayList<>();
            for (var t : tasks) merged.addAll(t.join());
            return TwoThirdsApproximationRouteMaker.getWaypointSequences(destId, merged,
                    merged.stream().filter(w -> w.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
        }
    }
}

public class HybridRouteStrategy {
    private static final int DEFAULT_CLUSTER_SIZE = 150;
    public static List<WaypointSequence> solve(List<Coordinate> points,
                                               UUID startId, UUID destId,
                                               ApproximateRouteCreator creator) {
        if (points.size() <= 300) return TwoOptOptimizer.optimize(creator.calculateRoute(points, startId, destId));
        int cs = Math.min(DEFAULT_CLUSTER_SIZE, (int) Math.ceil(Math.sqrt(points.size() * 50)));
        var clusters = VRPClusterer.clusterByProximity(points, cs, startId, destId);
        ForkJoinPool pool = new ForkJoinPool(Runtime.getRuntime().availableProcessors());
        try {
            var merged = pool.submit(() -> clusters.parallelStream()
                    .map(c -> TwoOptOptimizer.optimize(creator.calculateRoute(c, startId, destId)))
                    .reduce(new ArrayList<>(), (a, b) -> { a.addAll(b); return a; })).get();
            return TwoThirdsApproximationRouteMaker.getWaypointSequences(destId, merged,
                    merged.stream().filter(w -> w.getWaypoints().getId().equals(startId)).findFirst().orElse(null));
        } catch (Exception e) { throw new RuntimeException(e); }
        finally { pool.shutdown(); }
    }
}
```

## 11. Benchmark teórico

| Pontos | Kruskal | Matching Greedy | Edmonds Blossom | 2-Opt | Total Legado | Total Otimizado |
|--------|---------|-----------------|-----------------|-------|-------------|-----------------|
| 100 | ~5 ms | ~50 ms | ~15 ms | ~20 ms | ~75 ms | ~40 ms |
| 300 | ~45 ms | ~1.3 s | ~120 ms | ~180 ms | ~1.5 s | ~350 ms |
| 500 | ~125 ms | ~6 s | ~350 ms | ~500 ms | ~6.6 s | ~1 s |
| 1000 | ~500 ms | ~48 s | ~1.5 s | ~2 s | ~50 s | ~4 s (hybrid) |
