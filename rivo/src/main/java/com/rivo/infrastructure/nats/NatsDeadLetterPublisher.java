package com.rivo.infrastructure.nats;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rivo.application.port.out.DeadLetterPort;
import com.rivo.domain.model.ProcessingError;
import com.rivo.infrastructure.persistence.entity.DeadLetterEventJpaEntity;
import com.rivo.infrastructure.persistence.repository.DeadLetterEventRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.nats.client.Connection;
import io.nats.client.JetStream;
import io.nats.client.impl.NatsMessage;
import java.time.Instant;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Implementacao do port de dead-letter com NATS.
 * Trocar por Kafka/etc. = nova implementacao de {@link DeadLetterPort}.
 */
@Component
@Slf4j
public class NatsDeadLetterPublisher implements DeadLetterPort {

    private final JetStream jetStream;
    private final ObjectMapper objectMapper;
    private final DeadLetterEventRepository dlqRepo;
    private final MeterRegistry meterRegistry;

    public NatsDeadLetterPublisher(Connection natsConnection, ObjectMapper objectMapper,
                                   DeadLetterEventRepository dlqRepo,
                                   MeterRegistry meterRegistry) throws Exception {
        this.jetStream = natsConnection.jetStream();
        this.objectMapper = objectMapper;
        this.dlqRepo = dlqRepo;
        this.meterRegistry = meterRegistry;
    }

    @Override
    public void publish(ProcessingError error, String originalStream, String originalSubject) {
        try {
            String subject = "route.dlq." + (error.vehicleId() != null ? error.vehicleId() : "unknown");
            byte[] data = objectMapper.writeValueAsBytes(error);
            NatsMessage msg = NatsMessage.builder()
                    .subject(subject)
                    .data(data)
                    .headers(new io.nats.client.impl.Headers()
                            .add("Nats-Msg-Id", UUID.randomUUID().toString())
                            .add("X-Trace-Id", error.traceId() != null ? error.traceId().toString() : "")
                            .add("X-Error-Code", error.errorCode().name()))
                    .build();
            jetStream.publish(msg);
            Counter.builder("routing.dlq.published")
                    .tag("sink", "nats")
                    .tag("error_code", error.errorCode().name())
                    .register(meterRegistry)
                    .increment();
            log.warn("Published to DLQ: subject={} errorCode={} traceId={} vehicleId={}",
                    subject, error.errorCode(), error.traceId(), error.vehicleId());
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Failed to serialize DLQ payload for traceId={}", error.traceId(), e);
        } catch (java.io.IOException | io.nats.client.JetStreamApiException e) {
            log.error("Failed to publish to DLQ NATS, falling back to DB only. traceId={}", error.traceId(), e);
        }

        persistToDlqTable(error, originalStream, originalSubject);
    }

    private void persistToDlqTable(ProcessingError error, String stream, String subject) {
        try {
            DeadLetterEventJpaEntity entity = new DeadLetterEventJpaEntity();
            entity.setId(UUID.randomUUID());
            entity.setStream(stream);
            entity.setSubject(subject);
            entity.setRawPayload(error.rawPayload());
            entity.setErrorCode(error.errorCode().name());
            entity.setErrorMessage(error.message());
            entity.setTraceId(error.traceId());
            entity.setVehicleId(error.vehicleId());
            entity.setOccurredAt(error.occurredAt());
            entity.setCreatedAt(Instant.now());
            entity.setReprocessed(false);
            dlqRepo.save(entity);
            Counter.builder("routing.dlq.published")
                    .tag("sink", "db")
                    .tag("error_code", error.errorCode().name())
                    .register(meterRegistry)
                    .increment();
        } catch (org.springframework.dao.DataAccessException e) {
            log.error("CRITICAL: Failed to persist DLQ event to database. traceId={} vehicleId={}",
                    error.traceId(), error.vehicleId(), e);
        }
    }
}