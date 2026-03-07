package com.example.routing.api.rest;

import com.example.routing.application.port.in.CreateRouteRequestPort;
import com.example.routing.application.port.in.GetRouteResultPort;
import com.example.routing.api.rest.dto.RouteResultResponse;
import com.example.routing.domain.exception.ResourceNotFoundException;
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
    private final GetRouteResultPort getRouteResultPort;

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@RequestBody RouteRequestJpaEntity request) {
        UUID id = createRouteRequest.handle(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("id", id, "status", "OPTIMIZATION_REQUESTED"));
    }

    @GetMapping("/{id}/result")
    public ResponseEntity<RouteResultResponse> getResult(@PathVariable UUID id) {
        return getRouteResultPort.getByRouteRequestId(id)
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new ResourceNotFoundException("RouteResult", id));
    }
}
