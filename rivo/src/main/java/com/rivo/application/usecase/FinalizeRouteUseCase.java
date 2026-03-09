package com.rivo.application.usecase;

import com.rivo.application.port.out.VehicleStateStore;
import com.rivo.domain.enums.VehicleStatus;
import com.rivo.domain.event.DestinationReachedEvent;
import com.rivo.domain.model.EtaState;
import com.rivo.domain.model.VehicleState;
import com.rivo.infrastructure.persistence.entity.RouteExecutionJpaEntity;
import com.rivo.infrastructure.persistence.repository.RouteExecutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@RequiredArgsConstructor
@Slf4j
public class FinalizeRouteUseCase {

    private final VehicleStateStore stateStore;
    private final RouteExecutionRepository executionRepo;

    @Transactional
    public void handle(DestinationReachedEvent event) {
        log.info("Finalizing route for vehicle={} route={}", event.vehicleId(), event.routeId());

        Instant now = Instant.now();

        stateStore.load(event.vehicleId()).ifPresent(state -> {
            VehicleState finalized = state
                    .withStatus(VehicleStatus.ARRIVED)
                    .withEta(new EtaState(0, now, 1.0, 0, now, false));
            stateStore.save(finalized);
        });

        executionRepo.findByVehicleIdAndStatus(event.vehicleId(), VehicleStatus.IN_PROGRESS.name())
                .ifPresent(exec -> {
                    exec.setStatus(VehicleStatus.ARRIVED.name());
                    exec.setUpdatedAt(now);
                    executionRepo.save(exec);
                });
    }
}


