package com.example.routing.engine.optimization;

import lombok.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

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
