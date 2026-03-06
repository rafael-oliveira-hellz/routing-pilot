package com.example.routing.domain.entity;

import java.time.Instant;
import java.util.UUID;

/**
 * Posição ao vivo do veículo em uma execução de rota.
 * Entidade de domínio: agnóstica a persistência; sem anotações JPA.
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
