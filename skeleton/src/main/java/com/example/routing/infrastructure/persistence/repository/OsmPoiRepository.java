package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.OsmPoiEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface OsmPoiRepository extends JpaRepository<OsmPoiEntity, Long> {

    @Query(value = """
        SELECT * FROM geo.osm_pois
        WHERE ST_DWithin(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radiusMeters
        )
        ORDER BY ST_Distance(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
        )
        """, nativeQuery = true)
    List<OsmPoiEntity> findNearby(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") double radiusMeters
    );

    @Query(value = """
        SELECT * FROM geo.osm_pois
        WHERE amenity = :amenity
          AND ST_DWithin(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radiusMeters
          )
        ORDER BY ST_Distance(
            geom::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
        )
        """, nativeQuery = true)
    List<OsmPoiEntity> findNearbyByAmenity(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") double radiusMeters,
        @Param("amenity") String amenity
    );
}
