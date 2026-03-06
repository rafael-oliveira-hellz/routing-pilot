package com.example.routing.api.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
@RequiredArgsConstructor
@Slf4j
public class EtaWebSocketHandler extends TextWebSocketHandler {

    private final ObjectMapper objectMapper;

    /**
     * vehicleId -> set of sessions (multiple clients can watch same vehicle)
     */
    private final Map<String, Set<WebSocketSession>> vehicleSessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String vehicleId = extractParam(session, "vehicleId");
        if (vehicleId != null) {
            vehicleSessions.computeIfAbsent(vehicleId, k -> ConcurrentHashMap.newKeySet()).add(session);
            log.info("WebSocket connected for vehicle {} (session {})", vehicleId, session.getId());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session,
                                      org.springframework.web.socket.CloseStatus status) {
        String vehicleId = extractParam(session, "vehicleId");
        if (vehicleId != null) {
            Set<WebSocketSession> sessions = vehicleSessions.get(vehicleId);
            if (sessions != null) {
                sessions.remove(session);
                if (sessions.isEmpty()) vehicleSessions.remove(vehicleId);
            }
        }
    }

    public void pushEtaUpdate(String vehicleId, Object etaPayload) {
        push(vehicleId, new WsMessage("ETA_UPDATE", etaPayload));
    }

    public void pushRouteChanged(String vehicleId, Object routePayload) {
        push(vehicleId, new WsMessage("ROUTE_CHANGED", routePayload));
    }

    public void pushIncidentAlert(String vehicleId, Object incidentPayload) {
        push(vehicleId, new WsMessage("INCIDENT_ALERT", incidentPayload));
    }

    public void pushArrival(String vehicleId, Object arrivalPayload) {
        push(vehicleId, new WsMessage("ARRIVAL", arrivalPayload));
    }

    private void push(String vehicleId, WsMessage message) {
        Set<WebSocketSession> sessions = vehicleSessions.get(vehicleId);
        if (sessions == null || sessions.isEmpty()) return;
        try {
            String json = objectMapper.writeValueAsString(message);
            TextMessage textMessage = new TextMessage(json);
            for (WebSocketSession session : sessions) {
                if (session.isOpen()) {
                    try {
                        session.sendMessage(textMessage);
                    } catch (java.io.IOException e) {
                        log.warn("Failed to push to session {} for vehicle {}", session.getId(), vehicleId, e);
                    }
                }
            }
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("Failed to serialize WS message for vehicle {}", vehicleId, e);
        }
    }

    private String extractParam(WebSocketSession session, String param) {
        String query = session.getUri() != null ? session.getUri().getQuery() : null;
        if (query != null && query.contains(param + "=")) {
            return query.split(param + "=")[1].split("&")[0];
        }
        return null;
    }

    public record WsMessage(String type, Object payload) {}
}
