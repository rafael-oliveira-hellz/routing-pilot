package com.rivo.application.port.out;

public interface EventPublisher {
    void publish(String subject, Object event);
}


