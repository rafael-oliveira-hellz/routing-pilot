package com.example.routing.application.port.out;

/**
 * Port para rate limiting (ex.: por veículo, por usuário).
 * Trocar Redis por Memcached/etc. = nova implementação deste port.
 */
public interface RateLimitPort {

    /** Retorna true se a requisição de localização do veículo deve ser rejeitada por rate limit. */
    boolean isLocationRateLimited(String vehicleId);

    /** Retorna true se o reporte de incidente do usuário deve ser rejeitado por rate limit. */
    boolean isIncidentRateLimited(String userId);
}
