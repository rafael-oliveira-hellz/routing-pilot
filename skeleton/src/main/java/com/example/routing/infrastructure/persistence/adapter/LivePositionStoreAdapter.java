package com.example.routing.infrastructure.persistence.adapter;

import com.example.routing.application.port.out.LivePositionStore;
import com.example.routing.domain.entity.LivePosition;
import com.example.routing.infrastructure.persistence.mapper.LivePositionMapper;
import com.example.routing.infrastructure.persistence.repository.LivePositionRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Implementação do port de posições ao vivo com JPA/Postgres.
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
