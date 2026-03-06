package com.example.routing.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "osm_addresses", schema = "geo")
@Getter @Setter @NoArgsConstructor
public class OsmAddressEntity {

    @Id
    @Column(name = "osm_id")
    private Long osmId;

    private String housenumber;

    private String street;

    private String suburb;

    private String city;

    private String postcode;

    private String state;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point geom;
}
