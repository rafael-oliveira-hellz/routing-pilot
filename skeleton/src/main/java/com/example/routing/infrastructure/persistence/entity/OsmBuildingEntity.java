package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.Polygon;

@Entity
@Table(name = "osm_buildings", schema = "geo")
@Getter @Setter @NoArgsConstructor
public class OsmBuildingEntity {

    @Id
    @Column(name = "osm_id")
    private Long osmId;

    private String name;

    @Column(nullable = false)
    private String building;

    private String housenumber;

    private String street;

    private String height;

    @Column(name = "building_levels")
    private Short buildingLevels;

    @Column(columnDefinition = "geometry(Polygon,4326)")
    private Polygon geom;
}
