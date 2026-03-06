package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.OsmBoundaryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface OsmBoundaryRepository extends JpaRepository<OsmBoundaryEntity, Long> {

    @Query(value = """
        SELECT * FROM geo.osm_boundaries
        WHERE admin_level = :adminLevel
          AND ST_Contains(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
        LIMIT 1
        """, nativeQuery = true)
    Optional<OsmBoundaryEntity> findBoundaryAt(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("adminLevel") int adminLevel
    );

    default Optional<OsmBoundaryEntity> findMunicipalityAt(double lat, double lon) {
        return findBoundaryAt(lat, lon, 8);
    }

    default Optional<OsmBoundaryEntity> findStateAt(double lat, double lon) {
        return findBoundaryAt(lat, lon, 4);
    }
}
