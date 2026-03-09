package com.rivo.infrastructure.nats;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.application.port.out.DeadLetterPort;
import com.rivo.application.usecase.RecalculateRouteUseCase;
import com.rivo.domain.enums.ProcessingErrorCode;
import com.rivo.domain.event.RecalculateRouteRequested;
import com.rivo.domain.model.ProcessingError;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import io.nats.client.JetStream;
import io.nats.client.Message;
import io.nats.client.PushSubscribeOptions;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class NatsRecalcListener {

    private final Connection natsConnection;
    private final RecalculateRouteUseCase recalcUseCase;
    private final DeadLetterPort deadLetter;
    private final ObjectMapper objectMapper;
    private Dispatcher dispatcher;

    @PostConstruct
    void subscribe() throws Exception {
        JetStream js = natsConnection.jetStream();
        PushSubscribeOptions opts = PushSubscribeOptions.builder()
                .stream("ROUTE_RECALC")
                .durable("recalc-worker")
                .build();
        dispatcher = natsConnection.createDispatcher();
        js.subscribe("route.recalc.requested.>", "recalc-worker-group", dispatcher, this::onMessage, false, opts);
        log.info("Subscribed to ROUTE_RECALC stream (recalc-worker)");
    }

    private void onMessage(Message msg) {
        String raw = new String(msg.getData());
        try {
            RecalculateRouteRequested event = objectMapper.readValue(raw, RecalculateRouteRequested.class);
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
        } catch (com.rivo.domain.exception.OptimizationException e) {
            log.error("Recalc optimization failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "ROUTE_RECALC", msg.getSubject());
            msg.nak();
        } catch (com.rivo.domain.exception.RoutingException e) {
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

    @PreDestroy
    void stop() {
        if (dispatcher != null) {
            natsConnection.closeDispatcher(dispatcher);
        }
    }
}
