package com.example.routing.application.port.out;

import com.example.routing.domain.entity.LivePosition;

import java.util.List;
import java.util.UUID;

/**
 * Port de persistência de posições ao vivo.
 * Contrato em termos de domínio (LivePosition); implementação na infraestrutura (ex.: JPA/Postgres).
 */
public interface LivePositionStore {

    LivePosition save(LivePosition position);

    List<LivePosition> findTop10ByExecutionIdOrderByRecordedAtDesc(UUID executionId);
}
