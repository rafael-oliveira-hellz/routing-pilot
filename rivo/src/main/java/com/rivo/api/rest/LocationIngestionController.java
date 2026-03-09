package com.rivo.api.rest;

import com.rivo.application.port.out.EventPublisher;
import com.rivo.application.port.out.LocationDedupPort;
import com.rivo.application.port.out.RateLimitPort;
import com.rivo.domain.event.LocationUpdatedEvent;
import com.rivo.domain.exception.ForbiddenException;
import com.rivo.domain.exception.RateLimitExceededException;
import com.rivo.domain.exception.UnauthorizedException;
import com.rivo.domain.model.GeoPoint;
import com.rivo.infrastructure.security.AuthenticatedUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @Valid @RequestBody BatchLocationRequest request,
            @RequestHeader(value = "X-Trace-Id", required = false) String incomingTraceId) {

        if (!currentUser.isAdmin()) {
            if (currentUser.vehicleId() == null || currentUser.vehicleId().isBlank()) {
                throw new UnauthorizedException("Authenticated token is missing vehicleId claim");
            }
            if (!currentUser.vehicleId().equals(request.vehicleId())) {
                throw new ForbiddenException("Token vehicleId does not match the payload vehicleId");
            }
        }

        if (rateLimitPort.isLocationRateLimited(request.vehicleId())) {
            throw new RateLimitExceededException("Rate limit exceeded for vehicle " + request.vehicleId(), 60);
        }

        UUID traceId = incomingTraceId != null ? UUID.fromString(incomingTraceId) : UUID.randomUUID();
        int accepted = 0;
        int duplicates = 0;
        int rejected = 0;

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

            LocationUpdatedEvent event = new LocationUpdatedEvent(
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

