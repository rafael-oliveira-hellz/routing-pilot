package com.example.routing.engine.optimization.model;

import com.example.routing.domain.enums.RouteType;
import lombok.*;

import java.time.LocalDateTime;
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
