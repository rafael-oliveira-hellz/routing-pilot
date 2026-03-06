package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.IncidentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IncidentRepository extends JpaRepository<IncidentJpaEntity, UUID> {

    @Query("""
        SELECT i FROM IncidentJpaEntity i
        WHERE i.regionTileX = :tileX AND i.regionTileY = :tileY AND i.regionZoom = :zoom
          AND i.incidentType = :type AND i.active = true
        ORDER BY i.createdAt DESC
        """)
    Optional<IncidentJpaEntity> findActiveByTileAndType(long tileX, long tileY, int zoom, String type);

    @Query("""
        SELECT i FROM IncidentJpaEntity i
        WHERE i.regionTileX BETWEEN :minX AND :maxX
          AND i.regionTileY BETWEEN :minY AND :maxY
          AND i.regionZoom = :zoom
          AND i.active = true AND i.quorumReached = true
        """)
    List<IncidentJpaEntity> findActiveByTileRange(long minX, long maxX, long minY, long maxY, int zoom);

    @Modifying
    @Query("UPDATE IncidentJpaEntity i SET i.active = false, i.updatedAt = :now WHERE i.expiresAt < :now AND i.active = true")
    int expireOldIncidents(Instant now);

    List<IncidentJpaEntity> findByActiveTrueAndExpiresAtBefore(Instant now);
}
