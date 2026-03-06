package com.example.routing.application.port.out;

import java.time.Instant;

/**
 * Port para deduplicação de eventos (ex.: posição por vehicleId + occurredAt).
 * Trocar Redis por Memcached/etc. = nova implementação deste port.
 */
public interface LocationDedupPort {

    /**
     * Retorna true se já existir um evento para (vehicleId, occurredAt), false caso contrário.
     * Em caso de sucesso, o par é considerado "visto" para a janela de dedup.
     */
    boolean isDuplicate(String vehicleId, Instant occurredAt);
}
