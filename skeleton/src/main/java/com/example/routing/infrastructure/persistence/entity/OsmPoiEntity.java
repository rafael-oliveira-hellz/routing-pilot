package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "osm_pois", schema = "geo")
@Getter @Setter @NoArgsConstructor
public class OsmPoiEntity {

    @Id
    @Column(name = "osm_id")
    private Long osmId;

    private String name;

    private String amenity;

    private String shop;

    private String tourism;

    private String brand;

    private String phone;

    private String website;

    @Column(name = "opening_hours")
    private String openingHours;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point geom;
}
