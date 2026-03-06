package com.example.routing.engine.optimization;

import lombok.*;

import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ResultDTO {
    private List<CoordinatesWithDistance> coordinates;
    private Double totalDistance;
}
