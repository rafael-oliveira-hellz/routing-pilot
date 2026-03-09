package com.rivo.engine.optimization.model;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WaypointSequence {
    private Coordinate waypoints;
    private Integer sequence;
}


