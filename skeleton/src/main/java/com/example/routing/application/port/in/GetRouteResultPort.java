package com.example.routing.application.port.in;

import com.example.routing.api.rest.dto.RouteResultResponse;

import java.util.Optional;
import java.util.UUID;

/** Port para obter o resultado da rota otimizada (GET result). */
public interface GetRouteResultPort {

    /**
     * Retorna o resultado da rota para o route-request, se existir e estiver COMPLETED.
     * @param routeRequestId ID do route-request (path /api/v1/route-requests/{id})
     */
    Optional<RouteResultResponse> getByRouteRequestId(UUID routeRequestId);
}
