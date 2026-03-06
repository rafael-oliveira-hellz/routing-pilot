package com.example.routing.application.usecase;

import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.domain.enums.IncidentType;
import com.example.routing.domain.event.IncidentExpiredEvent;
import com.example.routing.domain.model.RegionTile;
import com.example.routing.infrastructure.persistence.entity.IncidentJpaEntity;
import com.example.routing.infrastructure.persistence.repository.IncidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ExpireIncidentsUseCase {

    private final IncidentRepository incidentRepo;
    private final EventPublisher eventPublisher;

    @Scheduled(fixedDelayString = "${routing.incident.expire-check-ms:60000}")
    @Transactional
    public void expireOldIncidents() {
        Instant now = Instant.now();
        List<IncidentJpaEntity> expired = incidentRepo.findByActiveTrueAndExpiresAtBefore(now);

        if (expired.isEmpty()) return;

        log.info("Expiring {} incidents", expired.size());
        for (IncidentJpaEntity incident : expired) {
            incident.setActive(false);
            incident.setUpdatedAt(now);
            incidentRepo.save(incident);

            RegionTile tile = new RegionTile(
                    incident.getRegionZoom(),
                    incident.getRegionTileX(),
                    incident.getRegionTileY());

            eventPublisher.publish("incident.expired." + tile.tileX() + "." + tile.tileY(),
                    new IncidentExpiredEvent(
                        UUID.randomUUID(),
                        incident.getId(),
                        IncidentType.valueOf(incident.getIncidentType()),
                        tile,
                        now));
        }
    }
}
