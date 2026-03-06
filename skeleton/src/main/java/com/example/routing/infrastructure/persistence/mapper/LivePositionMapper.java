package com.example.routing.infrastructure.persistence.mapper;

import com.example.routing.domain.entity.LivePosition;
import com.example.routing.infrastructure.persistence.entity.LivePositionJpaEntity;

/**
 * Mapeia entre entidade de domínio (agnóstica a banco) e entidade JPA.
 * Trocar de Postgres para outro banco = nova entidade de persistência + novo mapper; domínio inalterado.
 */
public final class LivePositionMapper {

    private LivePositionMapper() {}

    public static LivePositionJpaEntity toJpa(LivePosition domain) {
        LivePositionJpaEntity e = new LivePositionJpaEntity();
        e.setId(domain.id());
        e.setExecutionId(domain.executionId());
        e.setLatitude(domain.latitude());
        e.setLongitude(domain.longitude());
        e.setSpeedMps(domain.speedMps());
        e.setHeading(domain.heading());
        e.setAccuracyM(domain.accuracyM());
        e.setRecordedAt(domain.recordedAt());
        return e;
    }

    public static LivePosition toDomain(LivePositionJpaEntity jpa) {
        return new LivePosition(
            jpa.getId(),
            jpa.getExecutionId(),
            jpa.getLatitude(),
            jpa.getLongitude(),
            jpa.getSpeedMps(),
            jpa.getHeading(),
            jpa.getAccuracyM(),
            jpa.getRecordedAt()
        );
    }
}
