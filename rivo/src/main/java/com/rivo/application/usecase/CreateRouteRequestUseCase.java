package com.rivo.application.usecase;

import com.rivo.application.port.in.CreateRouteRequestPort;
import com.rivo.application.port.out.EventPublisher;
import com.rivo.domain.event.RouteOptimizationRequested;
import com.rivo.domain.validator.RouteRequestValidator;
import com.rivo.infrastructure.persistence.entity.RouteRequestJpaEntity;
import com.rivo.infrastructure.persistence.repository.RouteRequestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class CreateRouteRequestUseCase implements CreateRouteRequestPort {

    private final RouteRequestRepository repository;
    private final EventPublisher eventPublisher;

    @Override
    @Transactional
    public UUID handle(RouteRequestJpaEntity request) {
        RouteRequestValidator.validate(request);

        RouteRequestJpaEntity saved = repository.save(request);
        log.info("RouteRequest created: id={} stops={}", saved.getId(), saved.getStops().size());

        int pointCount = saved.getPoints().size() + saved.getStops().size();
        eventPublisher.publish("route.recalc.requested." + saved.getId(),
                new RouteOptimizationRequested(
                    UUID.randomUUID(),
                    saved.getId(),
                    Instant.now(),
                    pointCount));

        return saved.getId();
    }
}


