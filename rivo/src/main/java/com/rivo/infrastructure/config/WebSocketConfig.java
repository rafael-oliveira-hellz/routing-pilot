package com.rivo.infrastructure.config;

import com.rivo.api.websocket.EtaWebSocketHandler;
import com.rivo.api.websocket.IncidentAlertHandler;
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


