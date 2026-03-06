package com.example.routing.application.usecase;

import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.application.port.out.ExecutionEventStore;
import com.example.routing.application.port.out.VehicleStateStore;
import com.example.routing.api.websocket.EtaWebSocketHandler;
import com.example.routing.domain.entity.ExecutionEvent;
import com.example.routing.domain.enums.VehicleStatus;
import com.example.routing.domain.event.SignalLostEvent;
import com.example.routing.domain.model.VehicleState;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class InactivityDetectorJob {

    private final VehicleStateStore stateStore;
    private final EventPublisher eventPublisher;
    private final ExecutionEventStore auditStore;
    private final EtaWebSocketHandler wsHandler;

    @Value("${routing.eta.signal-timeout-seconds:20}")
    private long signalLostSec;

    @Value("${routing.inactivity.vehicle-stopped-seconds:120}")
    private long stoppedSec;

    @Value("${routing.inactivity.vehicle-abandoned-seconds:3600}")
    private long abandonedSec;

    @Scheduled(fixedRate = 10_000)
    public void detectInactiveVehicles() {
        Set<String> vehicleIds = stateStore.scanActiveVehicleIds();
        if (vehicleIds.isEmpty()) return;

        Instant now = Instant.now();
        int checked = 0, signalLost = 0, abandoned = 0;

        for (String vehicleId : vehicleIds) {
            var optState = stateStore.load(vehicleId);
            if (optState.isEmpty()) continue;

            VehicleState state = optState.get();

            if (state.status() == VehicleStatus.ARRIVED || state.status() == VehicleStatus.FAILED) {
                continue;
            }

            checked++;
            Instant lastLocation = (state.eta() != null && state.eta().lastLocationAt() != null)
                    ? state.eta().lastLocationAt()
                    : state.lastProcessedAt();

            if (lastLocation == null) continue;

            long secondsSince = Duration.between(lastLocation, now).toSeconds();

            if (secondsSince >= abandonedSec) {
                handleAbandoned(vehicleId, state, secondsSince);
                abandoned++;
            } else if (secondsSince >= signalLostSec
                       && state.status() != VehicleStatus.DEGRADED_ESTIMATE) {
                String routeId = (state.routeProgress() != null) ? state.routeProgress().routeId() : "unknown";
                handleSignalLost(vehicleId, routeId, state, secondsSince);
                signalLost++;
            }
        }

        if (signalLost > 0 || abandoned > 0) {
            log.info("Inactivity scan: checked={} signalLost={} abandoned={}", checked, signalLost, abandoned);
        }
    }

    private void handleSignalLost(String vehicleId, String routeId, VehicleState state, long secondsSince) {
        log.warn("Signal lost for vehicle {} ({} seconds)", vehicleId, secondsSince);

        stateStore.save(state.withStatus(VehicleStatus.DEGRADED_ESTIMATE));

        var event = new SignalLostEvent(
                UUID.randomUUID(), vehicleId, routeId, Instant.now(), secondsSince);
        eventPublisher.publish("route.eta." + vehicleId, event);

        auditStore.save(ExecutionEvent.of(
                UUID.randomUUID(),
                null,
                "SIGNAL_LOST",
                null,
                null,
                "DEGRADED",
                0,
                "{\"vehicleId\":\"" + vehicleId + "\",\"secondsSinceLastSignal\":" + secondsSince + "}",
                Instant.now()));

        wsHandler.pushEtaUpdate(vehicleId, Map.of(
                "type", "ETA_UPDATE",
                "degraded", true,
                "reason", "SIGNAL_LOST",
                "secondsSinceLastSignal", secondsSince));
    }

    private void handleAbandoned(String vehicleId, VehicleState state, long secondsSince) {
        log.error("Vehicle {} abandoned ({} seconds without signal)", vehicleId, secondsSince);

        stateStore.save(state.withStatus(VehicleStatus.FAILED));

        auditStore.save(ExecutionEvent.of(
                UUID.randomUUID(),
                null,
                "VEHICLE_ABANDONED",
                null,
                null,
                "PROCESSING_FAILED",
                0,
                "{\"vehicleId\":\"" + vehicleId + "\",\"secondsSinceLastSignal\":" + secondsSince + "}",
                Instant.now()));
    }
}
