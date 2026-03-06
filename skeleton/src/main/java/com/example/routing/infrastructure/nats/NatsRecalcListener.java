package com.example.routing.infrastructure.nats;

import com.example.routing.application.port.out.DeadLetterPort;
import com.example.routing.application.usecase.RecalculateRouteUseCase;
import com.example.routing.domain.enums.ProcessingErrorCode;
import com.example.routing.domain.event.RecalculateRouteRequested;
import com.example.routing.domain.model.ProcessingError;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.nats.client.Connection;
import io.nats.client.JetStreamSubscription;
import io.nats.client.Message;
import io.nats.client.PushSubscribeOptions;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class NatsRecalcListener {

    private final Connection natsConnection;
    private final RecalculateRouteUseCase recalcUseCase;
    private final DeadLetterPort deadLetter;
    private final ObjectMapper objectMapper;

    @PostConstruct
    void subscribe() throws Exception {
        var js = natsConnection.jetStream();
        var opts = PushSubscribeOptions.builder()
                .stream("ROUTE_RECALC")
                .durable("recalc-worker")
                .build();

        JetStreamSubscription sub = js.subscribe("route.recalc.requested.>",
                "recalc-worker-group", this::onMessage, false, opts);
        log.info("Subscribed to ROUTE_RECALC stream (recalc-worker)");
    }

    private void onMessage(Message msg) {
        String raw = new String(msg.getData());
        try {
            var event = objectMapper.readValue(raw, RecalculateRouteRequested.class);
            recalcUseCase.handle(event);
            msg.ack();
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Recalc deserialization failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.DESERIALIZATION_FAILED, e.getMessage(),
                            raw, Instant.now(), 1),
                    "ROUTE_RECALC", msg.getSubject());
            msg.ack();
        } catch (com.example.routing.domain.exception.OptimizationException e) {
            log.error("Recalc optimization failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "ROUTE_RECALC", msg.getSubject());
            msg.nak();
        } catch (com.example.routing.domain.exception.RoutingException e) {
            log.error("Recalc routing error [{}]: {}", e.getErrorCode(), e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "ROUTE_RECALC", msg.getSubject());
            msg.nak();
        } catch (org.springframework.dao.DataAccessException e) {
            log.error("Recalc DB error: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "ROUTE_RECALC", msg.getSubject());
            msg.nak();
        }
    }
}
