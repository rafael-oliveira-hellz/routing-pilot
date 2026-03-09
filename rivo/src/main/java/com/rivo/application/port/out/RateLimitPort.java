package com.rivo.application.port.out;

/**
 * Port para rate limiting (ex.: por ve??culo, por usu??rio).
 * Trocar Redis por Memcached/etc. = nova implementa????o deste port.
 */
public interface RateLimitPort {

    /** Retorna true se a requisi????o de localiza????o do ve??culo deve ser rejeitada por rate limit. */
    boolean isLocationRateLimited(String vehicleId);

    /** Retorna true se o reporte de incidente do usu??rio deve ser rejeitado por rate limit. */
    boolean isIncidentRateLimited(String userId);
}


