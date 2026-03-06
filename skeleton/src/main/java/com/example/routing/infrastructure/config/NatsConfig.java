package com.example.routing.infrastructure.config;

import io.nats.client.Connection;
import io.nats.client.JetStreamManagement;
import io.nats.client.api.StreamConfiguration;
import io.nats.client.api.StorageType;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class NatsConfig {

    private final Connection natsConnection;

    @PostConstruct
    public void createStreams() throws Exception {
        JetStreamManagement jsm = natsConnection.jetStreamManagement();
        ensureStream(jsm, "ROUTE_TRACKING",
                new String[]{"route.location.>", "route.eta.>", "route.arrived.>"}, Duration.ofHours(24));
        ensureStream(jsm, "ROUTE_RECALC",
                new String[]{"route.recalc.>"}, Duration.ofHours(1));
        ensureStream(jsm, "INCIDENTS",
                new String[]{"incident.>"}, Duration.ofHours(48));
        ensureStream(jsm, "DEAD_LETTER",
                new String[]{"route.dlq.>"}, Duration.ofDays(30));
    }

    private void ensureStream(JetStreamManagement jsm, String name, String[] subjects, Duration maxAge) {
        try {
            jsm.getStreamInfo(name);
            log.info("Stream {} already exists", name);
        } catch (io.nats.client.JetStreamApiException e) {
            try {
                jsm.addStream(StreamConfiguration.builder()
                        .name(name)
                        .subjects(subjects)
                        .maxAge(maxAge)
                        .storageType(StorageType.File)
                        .build());
                log.info("Created stream {}", name);
            } catch (java.io.IOException | io.nats.client.JetStreamApiException ex) {
                log.error("Failed to create stream {}", name, ex);
            }
        } catch (java.io.IOException e) {
            log.error("Failed to check stream {}", name, e);
        }
    }
}
