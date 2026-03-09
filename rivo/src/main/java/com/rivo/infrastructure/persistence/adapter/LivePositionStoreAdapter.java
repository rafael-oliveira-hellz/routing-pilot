package com.rivo.infrastructure.persistence.adapter;

import com.rivo.application.port.out.LivePositionStore;
import com.rivo.domain.entity.LivePosition;
import com.rivo.infrastructure.persistence.mapper.LivePositionMapper;
import com.rivo.infrastructure.persistence.repository.LivePositionRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Implementa????o do port de posi????es ao vivo com JPA/Postgres.
 * Trocar de banco = substituir por outro adapter sem alterar domain/application.
 */
@Component
public class LivePositionStoreAdapter implements LivePositionStore {

    private final LivePositionRepository jpaRepository;

    public LivePositionStoreAdapter(LivePositionRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public LivePosition save(LivePosition position) {
        return LivePositionMapper.toDomain(
                jpaRepository.save(LivePositionMapper.toJpa(position)));
    }

    @Override
    public List<LivePosition> findTop10ByExecutionIdOrderByRecordedAtDesc(UUID executionId) {
        return jpaRepository.findTop10ByExecutionIdOrderByRecordedAtDesc(executionId).stream()
                .map(LivePositionMapper::toDomain)
                .collect(Collectors.toList());
    }
}


