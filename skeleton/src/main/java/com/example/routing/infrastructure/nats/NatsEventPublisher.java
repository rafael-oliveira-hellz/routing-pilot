package com.example.routing.infrastructure.nats;

import com.example.routing.application.port.out.EventPublisher;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.nats.client.Connection;
import io.nats.client.JetStream;
import io.nats.client.api.PublishAck;
import io.nats.client.impl.NatsMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Component
@Slf4j
public class NatsEventPublisher implements EventPublisher {

    private final JetStream jetStream;
    private final ObjectMapper objectMapper;

    public NatsEventPublisher(Connection natsConnection, ObjectMapper objectMapper) throws Exception {
        this.jetStream = natsConnection.jetStream();
        this.objectMapper = objectMapper;
    }

    @Override
    public void publish(String subject, Object event) {
        try {
            byte[] data = objectMapper.writeValueAsBytes(event);
            NatsMessage msg = NatsMessage.builder()
                    .subject(subject)
                    .data(data)
                    .headers(new io.nats.client.impl.Headers()
                            .add("Nats-Msg-Id", UUID.randomUUID().toString()))
                    .build();
            PublishAck ack = jetStream.publish(msg);
            log.debug("Published to {} seq={}", subject, ack.getSeqno());
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Failed to serialize event for {}", subject, e);
            throw new IllegalStateException("Event serialization failed", e);
        } catch (java.io.IOException | io.nats.client.JetStreamApiException e) {
            log.error("Failed to publish event to {}", subject, e);
            throw new RuntimeException("Event publish failed", e);
        }
    }
}
