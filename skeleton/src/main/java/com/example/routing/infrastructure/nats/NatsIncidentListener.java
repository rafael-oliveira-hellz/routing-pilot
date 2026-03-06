package com.example.routing.infrastructure.nats;

import com.example.routing.application.port.in.ReportIncidentPort;
import com.example.routing.application.port.out.DeadLetterPort;
import com.example.routing.domain.enums.ProcessingErrorCode;
import com.example.routing.domain.event.IncidentReportedEvent;
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
public class NatsIncidentListener {

    private final Connection natsConnection;
    private final ReportIncidentPort reportUseCase;
    private final DeadLetterPort deadLetter;
    private final ObjectMapper objectMapper;

    @PostConstruct
    void subscribe() throws Exception {
        var js = natsConnection.jetStream();
        var opts = PushSubscribeOptions.builder()
                .stream("INCIDENTS")
                .durable("incident-worker")
                .build();

        JetStreamSubscription sub = js.subscribe("incident.reported.>",
                "incident-worker-group", this::onMessage, false, opts);
        log.info("Subscribed to INCIDENTS stream (incident-worker)");
    }

    private void onMessage(Message msg) {
        String raw = new String(msg.getData());
        try {
            var event = objectMapper.readValue(raw, IncidentReportedEvent.class);
            reportUseCase.handle(event);
            msg.ack();
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Incident deserialization failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.DESERIALIZATION_FAILED, e.getMessage(),
                            raw, Instant.now(), 1),
                    "INCIDENTS", msg.getSubject());
            msg.ack();
        } catch (com.example.routing.domain.exception.DomainException e) {
            log.error("Incident validation failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.DESERIALIZATION_FAILED, e.getMessage(),
                            raw, Instant.now(), 1),
                    "INCIDENTS", msg.getSubject());
            msg.ack();
        } catch (com.example.routing.domain.exception.IncidentException e) {
            log.error("Incident processing error: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "INCIDENTS", msg.getSubject());
            msg.nak();
        } catch (org.springframework.dao.DataAccessException e) {
            log.error("Incident DB error: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.UNKNOWN, e.getMessage(),
                            raw, Instant.now(), 1),
                    "INCIDENTS", msg.getSubject());
            msg.nak();
        }
    }
}
