package com.rivo.application.port.out;

import java.time.Instant;

/**
 * Port para deduplica????o de eventos (ex.: posi????o por vehicleId + occurredAt).
 * Trocar Redis por Memcached/etc. = nova implementa????o deste port.
 */
public interface LocationDedupPort {

    /**
     * Retorna true se j?? existir um evento para (vehicleId, occurredAt), false caso contr??rio.
     * Em caso de sucesso, o par ?? considerado "visto" para a janela de dedup.
     */
    boolean isDuplicate(String vehicleId, Instant occurredAt);
}


