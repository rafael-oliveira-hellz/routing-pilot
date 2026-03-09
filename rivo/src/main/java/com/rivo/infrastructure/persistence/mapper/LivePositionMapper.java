package com.rivo.infrastructure.persistence.mapper;

import com.rivo.domain.entity.LivePosition;
import com.rivo.infrastructure.persistence.entity.LivePositionJpaEntity;

/**
 * Mapeia entre entidade de dom??nio (agn??stica a banco) e entidade JPA.
 * Trocar de Postgres para outro banco = nova entidade de persist??ncia + novo mapper; dom??nio inalterado.
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


