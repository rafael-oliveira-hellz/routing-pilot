package com.rivo.application.usecase;

import com.rivo.application.port.out.EventPublisher;
import com.rivo.domain.enums.IncidentType;
import com.rivo.domain.event.IncidentExpiredEvent;
import com.rivo.domain.model.RegionTile;
import com.rivo.infrastructure.persistence.entity.IncidentJpaEntity;
import com.rivo.infrastructure.persistence.repository.IncidentRepository;
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


