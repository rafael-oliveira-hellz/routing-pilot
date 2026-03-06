package com.example.routing.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Evento de posição enviado pelo dispositivo/veículo.
 * O campo {@code speedMps} é obrigatório: é a velocidade reportada pelo veículo (m/s)
 * e é usada pelo EtaEngine como velocidade observada (EWMA) para o cálculo incremental do ETA.
 */
public record LocationUpdatedEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    double lat,
    double lon,
    /** Velocidade reportada pelo veículo em m/s. Obrigatória para o EtaEngine (EWMA e remainingSeconds). */
    double speedMps,
    double heading,
    double accuracyMeters
) {}
