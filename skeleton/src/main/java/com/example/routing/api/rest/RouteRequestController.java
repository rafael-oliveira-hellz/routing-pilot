package com.example.routing.api.rest;

import com.example.routing.application.port.in.CreateRouteRequestPort;
import com.example.routing.infrastructure.persistence.entity.RouteRequestJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/route-requests")
@RequiredArgsConstructor
public class RouteRequestController {

    private final CreateRouteRequestPort createRouteRequest;

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@RequestBody RouteRequestJpaEntity request) {
        UUID id = createRouteRequest.handle(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("id", id, "status", "OPTIMIZATION_REQUESTED"));
    }
}
