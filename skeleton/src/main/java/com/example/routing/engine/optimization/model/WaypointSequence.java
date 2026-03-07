package com.example.routing.engine.optimization.model;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WaypointSequence {
    private Coordinate waypoints;
    private Integer sequence;
}
