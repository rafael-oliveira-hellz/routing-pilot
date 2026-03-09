package com.rivo.application.port.out;

import com.rivo.domain.model.VehicleState;

import java.util.Optional;
import java.util.Set;

public interface VehicleStateStore {
    Optional<VehicleState> load(String vehicleId);
    void save(VehicleState state);
    Set<String> scanActiveVehicleIds();
}


