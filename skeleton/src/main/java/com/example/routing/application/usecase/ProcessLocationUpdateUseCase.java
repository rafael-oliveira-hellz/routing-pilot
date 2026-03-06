package com.example.routing.application.usecase;

import com.example.routing.application.port.in.ProcessLocationUpdatePort;
import com.example.routing.application.port.out.EventPublisher;
import com.example.routing.application.port.out.ExecutionEventStore;
import com.example.routing.application.port.out.IncidentQueryPort;
import com.example.routing.application.port.out.VehicleStateStore;
import com.example.routing.domain.entity.ExecutionEvent;
import com.example.routing.domain.enums.Decision;
import com.example.routing.domain.enums.RecalcReason;
import com.example.routing.domain.enums.VehicleStatus;
import com.example.routing.domain.event.*;
import com.example.routing.domain.model.*;
import com.example.routing.domain.policy.*;
import com.example.routing.engine.eta.EtaEngine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProcessLocationUpdateUseCase implements ProcessLocationUpdatePort {

    private final VehicleStateStore stateStore;
    private final IncidentQueryPort incidentQuery;
    private final EventPublisher eventPublisher;
    private final EtaEngine etaEngine;
    private final DestinationArrivalPolicy arrivalPolicy;
    private final RecalculationThrottlePolicy throttlePolicy;
    private final RouteDeviationPolicy deviationPolicy;
    private final IncidentImpactPolicy incidentPolicy;
    private final ExecutionEventStore auditStore;

    @Override
    public void handle(LocationUpdatedEvent event) {
        long startNs = System.nanoTime();
        String mdcTrace = org.slf4j.MDC.get("traceId");
        UUID traceId = (mdcTrace != null) ? UUID.fromString(mdcTrace) : UUID.randomUUID();
        Instant now = event.occurredAt();
        Decision decision = Decision.ETA_ONLY;

        VehicleState state = stateStore.load(event.vehicleId())
                .orElseGet(() -> createInitial(event, now));

        if (now.isBefore(state.lastProcessedAt())) {
            log.debug("Stale event: traceId={} vehicleId={} eventId={}", traceId, event.vehicleId(), event.eventId());
            return;
        }

        boolean wasSignalLost = state.status() == VehicleStatus.DEGRADED_ESTIMATE;

        GeoPoint pos = new GeoPoint(event.lat(), event.lon());
        state = state.withPosition(pos, event.heading(), event.speedMps(), now);

        if (wasSignalLost) {
            state = state.withStatus(VehicleStatus.IN_PROGRESS);
            long offlineSec = state.eta() != null && state.eta().lastLocationAt() != null
                    ? java.time.Duration.between(state.eta().lastLocationAt(), now).toSeconds() : 0;
            eventPublisher.publish("route.eta." + event.vehicleId(),
                    new SignalRecoveredEvent(UUID.randomUUID(), event.vehicleId(),
                            event.routeId(), now, offlineSec));
            persistAudit(event, traceId, "SIGNAL_RECOVERED", Decision.ETA_ONLY, startNs, null);
        }

        RouteProgress progress = state.routeProgress();

        if (arrivalPolicy.hasArrived(progress)) {
            decision = Decision.ARRIVED;
            state = state.withStatus(VehicleStatus.ARRIVED);
            stateStore.save(state);
            eventPublisher.publish("route.arrived." + event.vehicleId(),
                    new DestinationReachedEvent(UUID.randomUUID(), event.vehicleId(),
                            event.routeId(), now, progress.distanceToDestinationMeters()));
            persistAudit(event, traceId, "DESTINATION_REACHED", decision, startNs, null);
            return;
        }

        RegionTile tile = RegionTile.fromGeoPoint(pos, 14);
        List<ActiveIncident> incidents = incidentQuery.findActiveByTile(tile);
        double incidentFactor = incidentPolicy.computeIncidentFactor(pos, incidents);

        boolean needsRecalc = false;
        if (deviationPolicy.shouldRecalculate(progress, event.heading(), 0.0)) {
            if (throttlePolicy.canRecalculate(state, now)) {
                needsRecalc = true;
            } else {
                state = state.withStatus(VehicleStatus.DEGRADED_ESTIMATE);
                decision = Decision.DEGRADED;
            }
        }

        if (!needsRecalc && incidentPolicy.evaluate(progress, pos, incidents) == PolicyDecision.RECALCULATE) {
            if (throttlePolicy.canRecalculate(state, now)) {
                needsRecalc = true;
            }
        }

        if (needsRecalc) {
            decision = Decision.RECALCULATE;
            state = state.withRecalculation(now);
            stateStore.save(state);
            eventPublisher.publish("route.recalc.requested." + event.vehicleId(),
                    new RecalculateRouteRequested(UUID.randomUUID(), event.vehicleId(),
                            event.routeId(), now, RecalcReason.ROUTE_DEVIATION,
                            progress.distanceToCorridorMeters()));
            persistAudit(event, traceId, "DEVIATION_DETECTED", decision, startNs, null);
            return;
        }

        // Velocidade reportada pelo veículo (event.speedMps) → EWMA e remainingSeconds no EtaEngine
        EtaState newEta = etaEngine.update(state.eta(), progress,
                event.speedMps(), 1.0, incidentFactor, now);
        state = state.withEta(newEta);

        if (newEta.degraded()) {
            state = state.withStatus(VehicleStatus.DEGRADED_ESTIMATE);
            decision = Decision.DEGRADED;
        } else if (state.status() == VehicleStatus.DEGRADED_ESTIMATE) {
            state = state.withStatus(VehicleStatus.IN_PROGRESS);
        }

        stateStore.save(state);
        eventPublisher.publish("route.eta." + event.vehicleId(),
                new EtaUpdatedEvent(UUID.randomUUID(), event.vehicleId(), event.routeId(),
                        event.routeVersion(), now, newEta.remainingSeconds(),
                        newEta.confidence(), newEta.degraded(),
                        progress.distanceRemainingMeters()));
        persistAudit(event, traceId, "ETA_UPDATED", decision, startNs,
                "{\"remaining\":" + newEta.remainingSeconds() + ",\"confidence\":" + newEta.confidence() + "}");
    }

    private void persistAudit(LocationUpdatedEvent event, UUID traceId,
                              String eventType, Decision decision, long startNs, String extraPayload) {
        try {
            int durationMs = (int) ((System.nanoTime() - startNs) / 1_000_000);
            ExecutionEvent auditEvent = ExecutionEvent.of(
                    UUID.randomUUID(),
                    null,
                    eventType,
                    traceId,
                    event.eventId(),
                    decision.name(),
                    durationMs,
                    extraPayload,
                    Instant.now());
            auditStore.save(auditEvent);
        } catch (org.springframework.dao.DataAccessException e) {
            log.error("Failed to persist audit: traceId={} eventId={}", traceId, event.eventId(), e);
        }
    }

    private VehicleState createInitial(LocationUpdatedEvent event, Instant now) {
        return new VehicleState(event.vehicleId(),
                new GeoPoint(event.lat(), event.lon()),
                event.heading(), event.speedMps(),
                VehicleStatus.IN_PROGRESS,
                EtaState.initial(now),
                new RouteProgress(event.routeId(), event.routeVersion(), 0, 0, 0, 0),
                null, 0, now);
    }
}
