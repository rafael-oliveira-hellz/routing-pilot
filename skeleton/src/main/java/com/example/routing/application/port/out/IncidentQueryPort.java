package com.example.routing.application.port.out;

import com.example.routing.domain.model.ActiveIncident;
import com.example.routing.domain.model.RegionTile;

import java.util.List;

public interface IncidentQueryPort {
    List<ActiveIncident> findActiveByTile(RegionTile tile);
    List<ActiveIncident> findActiveNearby(double lat, double lon, double radiusMeters);
}
