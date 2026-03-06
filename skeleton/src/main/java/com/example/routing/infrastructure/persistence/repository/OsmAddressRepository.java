package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.OsmAddressEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface OsmAddressRepository extends JpaRepository<OsmAddressEntity, Long> {

    @Query(value = """
        SELECT * FROM geo.osm_addresses
        WHERE ST_DWithin(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radiusMeters
        )
        ORDER BY ST_Distance(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
        )
        LIMIT 1
        """, nativeQuery = true)
    Optional<OsmAddressEntity> findNearestAddress(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") double radiusMeters
    );
}
