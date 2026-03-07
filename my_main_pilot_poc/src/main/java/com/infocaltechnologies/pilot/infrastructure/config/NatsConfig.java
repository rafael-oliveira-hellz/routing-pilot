package com.infocaltechnologies.pilot.infrastructure.config;

import io.nats.client.Connection;
import io.nats.client.JetStreamApiException;
import io.nats.client.JetStreamManagement;
import io.nats.client.api.StreamConfiguration;
import io.nats.client.api.StorageType;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.time.Duration;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class NatsConfig {
    private final Connection connection;

    @PostConstruct
    public void setupStreams() throws Exception {
        JetStreamManagement jetStreamManagement = connection.jetStreamManagement();

        ensureStream(jetStreamManagement, "ROUTE_TRACKING",
                new String[]{"route.location.>", "route.eta.>", "route.arrived.>"}, Duration.ofHours(24));
        ensureStream(jetStreamManagement, "ROUTE_RECALC",
                new String[]{"route.recalc.>"}, Duration.ofHours(1));
        ensureStream(jetStreamManagement, "INCIDENTS",
                new String[]{"incident.>"}, Duration.ofHours(48));
        ensureStream(jetStreamManagement, "DEAD_LETTER",
                new String[]{"route.dlq.>"}, Duration.ofDays(30));
    }

    private void ensureStream(JetStreamManagement jetStreamManagement, String name, String[] subjects, Duration maxAge) {
        try {
            jetStreamManagement.getStreamInfo(name);
            log.info("Stream {} already exists", name);
        } catch (JetStreamApiException e) {
            try {
                jetStreamManagement.addStream(StreamConfiguration.builder()
                        .name(name)
                        .subjects(subjects)
                        .maxAge(maxAge)
                        .storageType(StorageType.File)
                        .build());
                log.info("Created stream {}", name);
            } catch (IOException | JetStreamApiException ex) {
                log.error("Failed to create stream {}", name, ex);
            }
        } catch (IOException e) {
            log.error("Failed to check stream {}", name, e);
        }
    }
}
