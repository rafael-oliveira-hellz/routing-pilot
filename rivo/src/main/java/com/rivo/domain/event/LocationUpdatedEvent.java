package com.rivo.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Evento de posi????o enviado pelo dispositivo/ve??culo.
 * O campo {@code speedMps} ?? obrigat??rio: ?? a velocidade reportada pelo ve??culo (m/s)
 * e ?? usada pelo EtaEngine como velocidade observada (EWMA) para o c??lculo incremental do ETA.
 */
public record LocationUpdatedEvent(
    UUID eventId,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    double lat,
    double lon,
    /** Velocidade reportada pelo ve??culo em m/s. Obrigat??ria para o EtaEngine (EWMA e remainingSeconds). */
    double speedMps,
    double heading,
    double accuracyMeters
) {}


