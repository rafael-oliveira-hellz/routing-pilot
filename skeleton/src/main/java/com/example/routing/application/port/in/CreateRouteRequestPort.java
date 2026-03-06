package com.example.routing.application.port.in;

import com.example.routing.infrastructure.persistence.entity.RouteRequestJpaEntity;

import java.util.UUID;

public interface CreateRouteRequestPort {

    UUID handle(RouteRequestJpaEntity request);
}
