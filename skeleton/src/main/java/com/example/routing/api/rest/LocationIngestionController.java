package com.example.routing.api.rest;

import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.application.port.out.LocationDedupPort;
import com.example.routing.application.port.out.RateLimitPort;
import com.example.routing.domain.event.LocationUpdatedEvent;
import com.example.routing.domain.exception.RateLimitExceededException;
import com.example.routing.domain.model.GeoPoint;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/locations")
@RequiredArgsConstructor
@Slf4j
public class LocationIngestionController {

    private final EventPublisher eventPublisher;
    private final LocationDedupPort locationDedup;
    private final RateLimitPort rateLimitPort;

    @PostMapping
    public ResponseEntity<IngestionResponse> ingest(
            @Valid @RequestBody BatchLocationRequest request,
            @RequestHeader(value = "X-Trace-Id", required = false) String incomingTraceId) {

        if (rateLimitPort.isLocationRateLimited(request.vehicleId())) {
            throw new RateLimitExceededException("Rate limit exceeded for vehicle " + request.vehicleId(), 60);
        }

        UUID traceId = incomingTraceId != null ? UUID.fromString(incomingTraceId) : UUID.randomUUID();
        int accepted = 0, duplicates = 0, rejected = 0;

        for (PositionPayload pos : request.positions()) {
            try {
                new GeoPoint(pos.lat(), pos.lon());
            } catch (IllegalArgumentException e) {
                rejected++;
                continue;
            }

            if (pos.occurredAt().isAfter(Instant.now().plusSeconds(60))) {
                rejected++;
                continue;
            }

            if (locationDedup.isDuplicate(request.vehicleId(), pos.occurredAt())) {
                duplicates++;
                continue;
            }

            var event = new LocationUpdatedEvent(
                    UUID.randomUUID(),
                    request.vehicleId(),
                    request.routeId(),
                    request.routeVersion(),
                    pos.occurredAt(),
                    pos.lat(), pos.lon(),
                    pos.speedMps(), pos.heading(), pos.accuracyMeters());

            eventPublisher.publish("route.location." + request.vehicleId(), event);
            accepted++;
        }

        log.info("Ingested batch: vehicleId={} traceId={} accepted={} dup={} rejected={}",
                request.vehicleId(), traceId, accepted, duplicates, rejected);

        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(new IngestionResponse(accepted, duplicates, rejected));
    }

    public record BatchLocationRequest(
        @NotNull String vehicleId,
        @NotNull String routeId,
        int routeVersion,
        @NotEmpty List<PositionPayload> positions
    ) {}

    /** Payload de uma posição no batch. speedMps é obrigatório para o cálculo do ETA (velocidade reportada pelo veículo). */
    public record PositionPayload(
        double lat,
        double lon,
        double speedMps,
        double heading,
        double accuracyMeters,
        @NotNull Instant occurredAt
    ) {}

    public record IngestionResponse(int accepted, int duplicates, int rejected) {}
}
