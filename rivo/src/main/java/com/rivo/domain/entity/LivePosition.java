package com.rivo.domain.entity;

import java.time.Instant;
import java.util.UUID;

/**
 * Posi????o ao vivo do ve??culo em uma execu????o de rota.
 * Entidade de dom??nio: agn??stica a persist??ncia; sem anota????es JPA.
 * ID e executionId em UUID.
 */
public record LivePosition(
    UUID id,
    UUID executionId,
    double latitude,
    double longitude,
    double speedMps,
    double heading,
    double accuracyM,
    Instant recordedAt
) {}


