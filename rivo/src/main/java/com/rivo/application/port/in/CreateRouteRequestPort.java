package com.rivo.application.port.in;

import com.rivo.infrastructure.persistence.entity.RouteRequestJpaEntity;

import java.util.UUID;

public interface CreateRouteRequestPort {

    UUID handle(RouteRequestJpaEntity request);
}


