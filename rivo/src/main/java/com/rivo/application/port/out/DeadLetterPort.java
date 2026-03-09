package com.rivo.application.port.out;

import com.rivo.domain.model.ProcessingError;

/**
 * Port para publica????o em dead-letter (eventos que falharam no processamento).
 * Trocar NATS por Kafka/etc. = nova implementa????o deste port.
 */
public interface DeadLetterPort {

    void publish(ProcessingError error, String originalStream, String originalSubject);
}


