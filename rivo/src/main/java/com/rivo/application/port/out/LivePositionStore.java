package com.rivo.application.port.out;

import com.rivo.domain.entity.LivePosition;

import java.util.List;
import java.util.UUID;

/**
 * Port de persist??ncia de posi????es ao vivo.
 * Contrato em termos de dom??nio (LivePosition); implementa????o na infraestrutura (ex.: JPA/Postgres).
 */
public interface LivePositionStore {

    LivePosition save(LivePosition position);

    List<LivePosition> findTop10ByExecutionIdOrderByRecordedAtDesc(UUID executionId);
}


