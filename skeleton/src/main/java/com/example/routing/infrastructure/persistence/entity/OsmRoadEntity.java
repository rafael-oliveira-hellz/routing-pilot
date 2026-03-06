package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.LineString;

@Entity
@Table(name = "osm_roads", schema = "geo")
@Getter @Setter @NoArgsConstructor
public class OsmRoadEntity {

    @Id
    @Column(name = "osm_id")
    private Long osmId;

    private String name;

    @Column(nullable = false)
    private String highway;

    private String ref;

    private Short maxspeed;

    private Boolean oneway;

    private String surface;

    private Short lanes;

    private Boolean bridge;

    private Boolean tunnel;

    private Boolean toll;

    private String access;

    @Column(columnDefinition = "geometry(LineString,4326)")
    private LineString geom;
}
