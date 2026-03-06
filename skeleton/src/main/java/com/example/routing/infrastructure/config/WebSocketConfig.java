package com.example.routing.infrastructure.config;

import com.example.routing.api.websocket.EtaWebSocketHandler;
import com.example.routing.api.websocket.IncidentAlertHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final EtaWebSocketHandler etaHandler;
    private final IncidentAlertHandler incidentAlertHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(etaHandler, "/ws/eta").setAllowedOrigins("*");
        registry.addHandler(incidentAlertHandler, "/ws/incidents").setAllowedOrigins("*");
    }
}
