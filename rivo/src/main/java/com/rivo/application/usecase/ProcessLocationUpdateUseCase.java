package com.rivo.application.usecase;

import com.rivo.application.port.in.ProcessLocationUpdatePort;
import com.rivo.application.port.out.EventPublisher;
import com.rivo.application.port.out.ExecutionEventStore;
import com.rivo.application.port.out.IncidentQueryPort;
import com.rivo.application.port.out.VehicleStateStore;
import com.rivo.domain.entity.ExecutionEvent;
import com.rivo.domain.enums.Decision;
import com.rivo.domain.enums.RecalcReason;
import com.rivo.domain.enums.VehicleStatus;
import com.rivo.domain.event.DestinationReachedEvent;
import com.rivo.domain.event.EtaUpdatedEvent;
import com.rivo.domain.event.LocationUpdatedEvent;
import com.rivo.domain.event.RecalculateRouteRequested;
import com.rivo.domain.event.SignalRecoveredEvent;
import com.rivo.domain.model.ActiveIncident;
import com.rivo.domain.model.EtaState;
import com.rivo.domain.model.GeoPoint;
import com.rivo.domain.model.PolicyDecision;
import com.rivo.domain.model.RegionTile;
import com.rivo.domain.model.RouteProgress;
import com.rivo.domain.model.VehicleState;
import com.rivo.domain.policy.DestinationArrivalPolicy;
import com.rivo.domain.policy.IncidentImpactPolicy;
import com.rivo.domain.policy.RecalculationThrottlePolicy;
import com.rivo.domain.policy.RouteDeviationPolicy;
import com.rivo.engine.eta.EtaEngine;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

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
    private final MeterRegistry meterRegistry;

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
            recordMetrics("STALE", state.status(), startNs);
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
            recordMetrics(decision.name(), state.status(), startNs);
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
            recordMetrics(decision.name(), state.status(), startNs);
            return;
        }

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
        recordMetrics(decision.name(), state.status(), startNs);
    }

    private void persistAudit(LocationUpdatedEvent event, UUID traceId,
                              String eventType, Decision decision, long startNs, String extraPayload) {
        try {
            int durationMs = (int) ((System.nanoTime() - startNs) / 1_000_000);
            org.slf4j.MDC.put("decision", decision.name());
            org.slf4j.MDC.put("processingMs", Integer.toString(durationMs));
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
        } finally {
            org.slf4j.MDC.remove("decision");
            org.slf4j.MDC.remove("processingMs");
        }
    }

    private void recordMetrics(String decision, VehicleStatus status, long startNs) {
        Counter.builder("routing.location.updates")
                .tag("decision", decision)
                .tag("status", status.name())
                .register(meterRegistry)
                .increment();
        Timer.builder("routing.location.processing")
                .tag("decision", decision)
                .tag("status", status.name())
                .register(meterRegistry)
                .record(Duration.ofNanos(System.nanoTime() - startNs));
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