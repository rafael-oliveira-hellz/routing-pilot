package com.rivo.application.port.out;

import com.rivo.domain.model.ActiveIncident;
import com.rivo.domain.model.RegionTile;

import java.util.List;

public interface IncidentQueryPort {
    List<ActiveIncident> findActiveByTile(RegionTile tile);
    List<ActiveIncident> findActiveNearby(double lat, double lon, double radiusMeters);
}


