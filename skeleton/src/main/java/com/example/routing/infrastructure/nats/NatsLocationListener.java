package com.example.routing.infrastructure.nats;

import com.example.routing.application.port.in.ProcessLocationUpdatePort;
import com.example.routing.application.port.out.DeadLetterPort;
import com.example.routing.domain.enums.ProcessingErrorCode;
import com.example.routing.domain.event.LocationUpdatedEvent;
import com.example.routing.domain.model.ProcessingError;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.nats.client.*;
import io.nats.client.api.ConsumerConfiguration;
import io.nats.client.api.DeliverPolicy;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class NatsLocationListener {

    private final Connection natsConnection;
    private final ProcessLocationUpdatePort useCase;
    private final ObjectMapper objectMapper;
    private final DeadLetterPort deadLetter;
    private Dispatcher dispatcher;

    @PostConstruct
    public void start() throws Exception {
        JetStream js = natsConnection.jetStream();
        var cc = ConsumerConfiguration.builder()
                .durable("tracking-worker")
                .filterSubject("route.location.>")
                .deliverPolicy(DeliverPolicy.New)
                .maxAckPending(500)
                .build();
        var opts = PushSubscribeOptions.builder()
                .configuration(cc)
                .build();
        dispatcher = natsConnection.createDispatcher();
        js.subscribe("route.location.>", "tracking-group", dispatcher, this::onMessage, false, opts);
        log.info("NATS location listener started");
    }

    private void onMessage(Message msg) {
        String rawPayload = new String(msg.getData(), StandardCharsets.UTF_8);
        String traceIdHeader = msg.getHeaders() != null ? msg.getHeaders().getFirst("X-Trace-Id") : null;
        UUID traceId = traceIdHeader != null && !traceIdHeader.isBlank()
                ? UUID.fromString(traceIdHeader) : UUID.randomUUID();
        String vehicleId = null;
        UUID eventId = null;

        try {
            org.slf4j.MDC.put("traceId", traceId.toString());
            LocationUpdatedEvent event = objectMapper.readValue(msg.getData(), LocationUpdatedEvent.class);
            vehicleId = event.vehicleId();
            eventId = event.eventId();
            org.slf4j.MDC.put("vehicleId", vehicleId);
            org.slf4j.MDC.put("eventId", eventId.toString());
            useCase.handle(event);
            msg.ack();
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Deserialization failed: traceId={} rawPayload={}", traceId, rawPayload, e);
            deadLetter.publish(
                    new ProcessingError(traceId, eventId, vehicleId,
                            ProcessingErrorCode.DESERIALIZATION_FAILED,
                            e.getMessage(), rawPayload, Instant.now(), 1),
                    "ROUTE_TRACKING", msg.getSubject());
            msg.ack();
        } catch (com.example.routing.domain.exception.RoutingException e) {
            log.error("Processing failed [{}]: traceId={} vehicleId={} eventId={}",
                    e.getErrorCode(), traceId, vehicleId, eventId, e);
            deadLetter.publish(
                    new ProcessingError(traceId, eventId, vehicleId,
                            ProcessingErrorCode.UNKNOWN,
                            e.getMessage(), rawPayload, Instant.now(), 1),
                    "ROUTE_TRACKING", msg.getSubject());
            msg.nak();
        } finally {
            org.slf4j.MDC.clear();
        }
    }

    @PreDestroy
    public void stop() {
        if (dispatcher != null) {
            natsConnection.closeDispatcher(dispatcher);
        }
    }
}
