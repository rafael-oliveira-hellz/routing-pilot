package com.example.routing.application.usecase;

import com.example.routing.domain.enums.IncidentType;
import com.example.routing.domain.enums.VoteType;
import com.example.routing.domain.exception.DomainException;
import com.example.routing.infrastructure.persistence.entity.IncidentJpaEntity;
import com.example.routing.infrastructure.persistence.entity.IncidentVoteJpaEntity;
import com.example.routing.infrastructure.persistence.repository.IncidentRepository;
import com.example.routing.infrastructure.persistence.repository.IncidentVoteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProcessIncidentVoteUseCase {

    private static final Map<IncidentType, Integer> QUORUM = Map.ofEntries(
        Map.entry(IncidentType.BLITZ, 2),
        Map.entry(IncidentType.ACCIDENT, 1),
        Map.entry(IncidentType.HEAVY_TRAFFIC, 3),
        Map.entry(IncidentType.WET_ROAD, 2),
        Map.entry(IncidentType.FLOOD, 1),
        Map.entry(IncidentType.ROAD_WORK, 1),
        Map.entry(IncidentType.BROKEN_TRAFFIC_LIGHT, 2),
        Map.entry(IncidentType.ANIMAL_ON_ROAD, 1),
        Map.entry(IncidentType.VEHICLE_STOPPED, 2),
        Map.entry(IncidentType.LANDSLIDE, 1),
        Map.entry(IncidentType.FOG, 2),
        Map.entry(IncidentType.OTHER, 3)
    );

    private final IncidentRepository incidentRepo;
    private final IncidentVoteRepository voteRepo;

    @Transactional
    public void vote(UUID incidentId, UUID voterId, VoteType voteType) {
        IncidentJpaEntity incident = incidentRepo.findById(incidentId)
                .orElseThrow(() -> new DomainException("Incident not found: " + incidentId));

        if (!incident.isActive())
            throw new DomainException("Incident is no longer active: " + incidentId);

        if (voteRepo.existsByIncidentIdAndVoterId(incidentId, voterId))
            throw new DomainException("User already voted on this incident");

        voteRepo.save(IncidentVoteJpaEntity.builder()
                .incidentId(incidentId)
                .voterId(voterId)
                .voteType(voteType.name())
                .build());

        if (voteType == VoteType.CONFIRM) {
            incident.setVoteCount(incident.getVoteCount() + 1);
            int required = QUORUM.getOrDefault(
                    IncidentType.valueOf(incident.getIncidentType()), 2);
            if (incident.getVoteCount() >= required && !incident.isQuorumReached()) {
                incident.setQuorumReached(true);
                log.info("Quorum reached for incident {} (type={}, votes={})",
                        incidentId, incident.getIncidentType(), incident.getVoteCount());
            }
            incidentRepo.save(incident);
        }
    }
}
