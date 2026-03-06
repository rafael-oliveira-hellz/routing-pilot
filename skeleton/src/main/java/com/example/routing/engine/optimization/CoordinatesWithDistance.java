package com.example.routing.engine.optimization;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CoordinatesWithDistance {
    private Coordinate origin;
    private Coordinate destination;
    private Double distance;
}
