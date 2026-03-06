package com.example.routing.infrastructure.persistence.repository;

import com.example.routing.infrastructure.persistence.entity.OsmRoadEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface OsmRoadRepository extends JpaRepository<OsmRoadEntity, Long> {

    @Query(value = """
        SELECT * FROM geo.osm_roads
        WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), 0.0005)
        ORDER BY ST_Distance(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
        LIMIT 1
        """, nativeQuery = true)
    Optional<OsmRoadEntity> findNearestRoad(@Param("lat") double lat, @Param("lon") double lon);

    @Query(value = """
        SELECT * FROM geo.osm_roads
        WHERE ST_Intersects(geom, ST_GeomFromText(:wkt, 4326))
          AND maxspeed IS NOT NULL
        """, nativeQuery = true)
    List<OsmRoadEntity> findRoadsWithSpeedLimit(@Param("wkt") String routeWkt);

    @Query(value = """
        SELECT name, highway, ref FROM geo.osm_roads
        WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), 0.0003)
        ORDER BY ST_Distance(geom, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
        LIMIT 1
        """, nativeQuery = true)
    Optional<Object[]> findRoadNameAt(@Param("lat") double lat, @Param("lon") double lon);
}
