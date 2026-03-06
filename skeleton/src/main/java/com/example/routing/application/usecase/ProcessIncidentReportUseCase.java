package com.example.routing.application.usecase;

import com.example.routing.application.port.in.ReportIncidentPort;
import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.domain.event.IncidentActivatedEvent;
import com.example.routing.domain.event.IncidentReportedEvent;
import com.example.routing.domain.model.GeoPoint;
import com.example.routing.domain.model.RegionTile;
import com.example.routing.infrastructure.persistence.entity.IncidentJpaEntity;
import com.example.routing.infrastructure.persistence.repository.IncidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProcessIncidentReportUseCase implements ReportIncidentPort {

    private final IncidentRepository incidentRepo;
    private final EventPublisher eventPublisher;

    @Value("${routing.incident.default-zoom:14}")
    private int defaultZoom;

    @Override
    @Transactional
    public UUID handle(IncidentReportedEvent event) {
        GeoPoint point = new GeoPoint(event.lat(), event.lon());
        RegionTile tile = RegionTile.fromGeoPoint(point, defaultZoom);

        Optional<IncidentJpaEntity> existing = incidentRepo
                .findActiveByTileAndType(tile.tileX(), tile.tileY(), defaultZoom,
                        event.incidentType().name());

        if (existing.isPresent()) {
            IncidentJpaEntity inc = existing.get();
            inc.setVoteCount(inc.getVoteCount() + 1);
            checkQuorumAndPublish(inc, event);
            incidentRepo.save(inc);
            return inc.getId();
        }

        IncidentJpaEntity inc = new IncidentJpaEntity();
        inc.setId(UUID.randomUUID());
        inc.setIncidentType(event.incidentType().name());
        inc.setSeverity(event.severity() != null ? event.severity().name() : "LOW");
        inc.setLatitude(event.lat());
        inc.setLongitude(event.lon());
        inc.setRadiusMeters(200);
        inc.setRegionTileX(tile.tileX());
        inc.setRegionTileY(tile.tileY());
        inc.setRegionZoom(defaultZoom);
        inc.setDescription(event.description());
        inc.setReportedBy(event.reportedBy());
        inc.setVoteCount(1);
        inc.setQuorumReached(false);
        inc.setActive(true);
        inc.setCreatedAt(Instant.now());
        inc.setUpdatedAt(Instant.now());
        // TTL varies by type - simplified to 2h default
        inc.setExpiresAt(Instant.now().plusSeconds(7200));
        incidentRepo.save(inc);

        checkQuorumAndPublish(inc, event);
        return inc.getId();
    }

    private void checkQuorumAndPublish(IncidentJpaEntity inc, IncidentReportedEvent event) {
        int requiredQuorum = getQuorum(event.incidentType().name());
        if (!inc.isQuorumReached() && inc.getVoteCount() >= requiredQuorum) {
            inc.setQuorumReached(true);
            String subject = "incident.activated." + inc.getRegionTileX() + "_" + inc.getRegionTileY();
            eventPublisher.publish(subject,
                    new IncidentActivatedEvent(UUID.randomUUID(), Instant.now(),
                            inc.getId(), event.incidentType(), event.severity(),
                            inc.getLatitude(), inc.getLongitude(), inc.getRadiusMeters(),
                            inc.getRegionTileX(), inc.getRegionTileY(), inc.getExpiresAt()));
        }
    }

    private int getQuorum(String type) {
        return switch (type) {
            case "ACCIDENT", "FLOOD", "LANDSLIDE", "ROAD_WORK" -> 1;
            case "BLITZ", "WET_ROAD", "BROKEN_TRAFFIC_LIGHT", "VEHICLE_STOPPED", "FOG" -> 2;
            default -> 3;
        };
    }
}
