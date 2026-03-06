package com.example.routing.api.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@RequiredArgsConstructor
@Slf4j
public class IncidentAlertHandler extends TextWebSocketHandler {

    private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String vehicleId = extractVehicleId(session);
        if (vehicleId != null) {
            sessions.put(vehicleId, session);
            log.info("WebSocket INCIDENT connected: vehicleId={}", vehicleId);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session,
                                      org.springframework.web.socket.CloseStatus status) {
        String vehicleId = extractVehicleId(session);
        if (vehicleId != null) {
            sessions.remove(vehicleId);
        }
    }

    public void pushIncidentAlert(String vehicleId, Object alert) {
        WebSocketSession session = sessions.get(vehicleId);
        if (session != null && session.isOpen()) {
            try {
                Map<String, Object> message = Map.of(
                    "type", "INCIDENT_ALERT",
                    "payload", alert
                );
                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(message)));
            } catch (IOException e) {
                log.warn("Failed to push incident alert to vehicleId={}: {}", vehicleId, e.getMessage());
            }
        }
    }

    public void broadcastToArea(Object alert, java.util.Set<String> vehicleIds) {
        for (String vehicleId : vehicleIds) {
            pushIncidentAlert(vehicleId, alert);
        }
    }

    private String extractVehicleId(WebSocketSession session) {
        var params = session.getUri() != null
                ? org.springframework.web.util.UriComponentsBuilder.fromUri(session.getUri())
                    .build().getQueryParams()
                : null;
        return params != null ? params.getFirst("vehicleId") : null;
    }
}
