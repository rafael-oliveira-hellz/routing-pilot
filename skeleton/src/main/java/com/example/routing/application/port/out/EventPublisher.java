package com.example.routing.application.port.out;

public interface EventPublisher {
    void publish(String subject, Object event);
}
