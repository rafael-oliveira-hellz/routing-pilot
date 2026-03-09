package com.rivo.infrastructure.nats;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.application.port.in.ReportIncidentPort;
import com.rivo.application.port.out.DeadLetterPort;
import com.rivo.domain.enums.ProcessingErrorCode;
import com.rivo.domain.event.IncidentReportedEvent;
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
public class NatsIncidentListener {

    private final Connection natsConnection;
    private final ReportIncidentPort reportUseCase;
    private final DeadLetterPort deadLetter;
    private final ObjectMapper objectMapper;
    private Dispatcher dispatcher;

    @PostConstruct
    void subscribe() throws Exception {
        JetStream js = natsConnection.jetStream();
        PushSubscribeOptions opts = PushSubscribeOptions.builder()
                .stream("INCIDENTS")
                .durable("incident-worker")
                .build();
        dispatcher = natsConnection.createDispatcher();
        js.subscribe("incident.reported.>", "incident-worker-group", dispatcher, this::onMessage, false, opts);
        log.info("Subscribed to INCIDENTS stream (incident-worker)");
    }

    private void onMessage(Message msg) {
        String raw = new String(msg.getData());
        try {
            IncidentReportedEvent event = objectMapper.readValue(raw, IncidentReportedEvent.class);
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
        } catch (com.rivo.domain.exception.DomainException e) {
            log.error("Incident validation failed: {}", e.getMessage(), e);
            deadLetter.publish(
                    new ProcessingError(UUID.randomUUID(), null, null,
                            ProcessingErrorCode.DESERIALIZATION_FAILED, e.getMessage(),
                            raw, Instant.now(), 1),
                    "INCIDENTS", msg.getSubject());
            msg.ack();
        } catch (com.rivo.domain.exception.IncidentException e) {
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

    @PreDestroy
    void stop() {
        if (dispatcher != null) {
            natsConnection.closeDispatcher(dispatcher);
        }
    }
}
