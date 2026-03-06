package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.MultiPolygon;

@Entity
@Table(name = "osm_boundaries", schema = "geo")
@Getter @Setter @NoArgsConstructor
public class OsmBoundaryEntity {

    @Id
    @Column(name = "osm_id")
    private Long osmId;

    @Column(nullable = false)
    private String name;

    @Column(name = "admin_level")
    private Short adminLevel;

    private String boundary;

    @Column(columnDefinition = "geometry(MultiPolygon,4326)")
    private MultiPolygon geom;
}
