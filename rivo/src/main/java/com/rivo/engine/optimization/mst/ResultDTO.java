package com.rivo.engine.optimization.mst;

import com.rivo.engine.optimization.model.CoordinatesWithDistance;
import lombok.*;

import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ResultDTO {
    private List<CoordinatesWithDistance> coordinates;
    private Double totalDistance;
}


