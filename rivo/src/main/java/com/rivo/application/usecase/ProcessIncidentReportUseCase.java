package com.rivo.application.usecase;

import com.rivo.application.port.in.ReportIncidentPort;
import com.rivo.application.port.out.EventPublisher;
import com.rivo.domain.event.IncidentActivatedEvent;
import com.rivo.domain.event.IncidentReportedEvent;
import com.rivo.domain.model.GeoPoint;
import com.rivo.domain.model.RegionTile;
import com.rivo.infrastructure.persistence.entity.IncidentJpaEntity;
import com.rivo.infrastructure.persistence.repository.IncidentRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProcessIncidentReportUseCase implements ReportIncidentPort {

    private final IncidentRepository incidentRepo;
    private final EventPublisher eventPublisher;
    private final MeterRegistry meterRegistry;

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
            boolean activated = checkQuorumAndPublish(inc, event);
            incidentRepo.save(inc);
            recordReportMetric(true, activated, event.incidentType().name());
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
        inc.setExpiresAt(Instant.now().plusSeconds(7200));
        incidentRepo.save(inc);

        boolean activated = checkQuorumAndPublish(inc, event);
        recordReportMetric(false, activated, event.incidentType().name());
        return inc.getId();
    }

    private boolean checkQuorumAndPublish(IncidentJpaEntity inc, IncidentReportedEvent event) {
        int requiredQuorum = getQuorum(event.incidentType().name());
        if (!inc.isQuorumReached() && inc.getVoteCount() >= requiredQuorum) {
            inc.setQuorumReached(true);
            String subject = "incident.activated." + inc.getRegionTileX() + "_" + inc.getRegionTileY();
            eventPublisher.publish(subject,
                    new IncidentActivatedEvent(UUID.randomUUID(), Instant.now(),
                            inc.getId(), event.incidentType(), event.severity(),
                            inc.getLatitude(), inc.getLongitude(), inc.getRadiusMeters(),
                            inc.getRegionTileX(), inc.getRegionTileY(), inc.getExpiresAt()));
            Counter.builder("routing.incident.activated")
                    .tag("type", event.incidentType().name())
                    .register(meterRegistry)
                    .increment();
            return true;
        }
        return false;
    }

    private void recordReportMetric(boolean deduplicated, boolean activated, String incidentType) {
        Counter.builder("routing.incident.reports")
                .tag("type", incidentType)
                .tag("deduplicated", Boolean.toString(deduplicated))
                .tag("activated", Boolean.toString(activated))
                .register(meterRegistry)
                .increment();
    }

    private int getQuorum(String type) {
        return switch (type) {
            case "ACCIDENT", "FLOOD", "LANDSLIDE", "ROAD_WORK" -> 1;
            case "BLITZ", "WET_ROAD", "BROKEN_TRAFFIC_LIGHT", "VEHICLE_STOPPED", "FOG" -> 2;
            default -> 3;
        };
    }
}