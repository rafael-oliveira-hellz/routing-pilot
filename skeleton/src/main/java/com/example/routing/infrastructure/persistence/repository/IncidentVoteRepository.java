package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.IncidentVoteJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface IncidentVoteRepository extends JpaRepository<IncidentVoteJpaEntity, UUID> {

    List<IncidentVoteJpaEntity> findByIncidentId(UUID incidentId);

    boolean existsByIncidentIdAndVoterId(UUID incidentId, UUID voterId);

    long countByIncidentIdAndVoteType(UUID incidentId, String voteType);
}
