package com.example.routing.application.port.out;

import com.example.routing.domain.model.ProcessingError;

/**
 * Port para publicação em dead-letter (eventos que falharam no processamento).
 * Trocar NATS por Kafka/etc. = nova implementação deste port.
 */
public interface DeadLetterPort {

    void publish(ProcessingError error, String originalStream, String originalSubject);
}
