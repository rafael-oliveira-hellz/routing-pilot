package com.rivo.api.rest;

import com.rivo.application.port.in.ReportIncidentPort;
import com.rivo.application.usecase.ProcessIncidentVoteUseCase;
import com.rivo.domain.enums.IncidentSeverity;
import com.rivo.domain.enums.IncidentType;
import com.rivo.domain.enums.VoteType;
import com.rivo.domain.event.IncidentReportedEvent;
import com.rivo.infrastructure.persistence.entity.IncidentJpaEntity;
import com.rivo.infrastructure.persistence.repository.IncidentRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/incidents")
@RequiredArgsConstructor
public class IncidentController {

    private final ReportIncidentPort reportUseCase;
    private final ProcessIncidentVoteUseCase voteUseCase;
    private final IncidentRepository incidentRepo;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> report(@Valid @RequestBody ReportRequest req) {
        var event = new IncidentReportedEvent(
                UUID.randomUUID(), Instant.now(),
                req.lat(), req.lon(), req.incidentType(), req.severity(),
                req.description(), req.reportedBy());
        UUID incidentId = reportUseCase.handle(event);
        return Map.of("incidentId", incidentId, "status", "REPORTED");
    }

    @PostMapping("/{id}/vote")
    @ResponseStatus(HttpStatus.OK)
    public Map<String, String> vote(@PathVariable UUID id, @Valid @RequestBody VoteRequest req) {
        voteUseCase.vote(id, req.voterId(), req.voteType());
        return Map.of("status", "VOTE_REGISTERED");
    }

    @GetMapping
    public List<IncidentJpaEntity> nearby(
            @RequestParam double lat, @RequestParam double lon,
            @RequestParam(defaultValue = "1000") double radius) {
        var tile = com.rivo.domain.model.RegionTile.fromGeoPoint(
                new com.rivo.domain.model.GeoPoint(lat, lon), 14);
        return incidentRepo.findActiveByTileRange(
                tile.tileX() - 1, tile.tileX() + 1,
                tile.tileY() - 1, tile.tileY() + 1, 14);
    }

    public record ReportRequest(
        @NotNull Double lat,
        @NotNull Double lon,
        @NotNull IncidentType incidentType,
        IncidentSeverity severity,
        String description,
        @NotNull UUID reportedBy
    ) {}

    public record VoteRequest(
        @NotNull UUID voterId,
        @NotNull VoteType voteType
    ) {}
}



