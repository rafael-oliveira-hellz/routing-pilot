# Alinhamento do App com o Backend (doc 11, 14)

## APIs REST consumidas

| Endpoint | Uso no app |
|----------|------------|
| POST /api/v1/auth/login, refresh, logout, forgot-password, reset-password, change-password | Auth (APP-1004, 1005) |
| POST /api/v1/route-requests | Nova rota (APP-2001) |
| GET /api/v1/route-requests/{id}/result | Resultado da rota (APP-3002) |
| POST /api/v1/route-requests/{id}/recalculate | Recálculo manual (APP-3002) |
| POST /api/v1/locations | Batch de posições (vehicleId, routeId, routeVersion, positions com speedMps, occurredAt) — APP-4001 |
| POST /api/v1/incidents | Reportar incidente (APP-6001) |
| POST /api/v1/incidents/{id}/vote | Votar CONFIRM/DENY/GONE (APP-6001) |
| GET /api/v1/incidents?lat=&lon=&radius= | Listar incidentes próximos (APP-6002) |

## WebSockets

| Endpoint | Eventos consumidos | Uso |
|----------|--------------------|-----|
| /ws/eta?token=&vehicleId=&routeId= | EtaUpdatedEvent, RouteRecalculatedEvent, DestinationReachedEvent | Tela "Em rota": ETA em tempo real, estado recalculando, chegada (APP-4002, APP-5001) |
| /ws/incidents?token=&lat=&lon=&radius= | IncidentActivatedEvent, IncidentExpiredEvent | Mapa e lista de incidentes em tempo real (APP-6002) |

## Contratos de eventos (doc 11)

- **EtaUpdatedEvent**: remainingSeconds, confidence, degraded, distanceRemainingMeters — exibidos no card ETA; degraded → estado DEGRADED_ESTIMATE.
- **RouteRecalculatedEvent**: rota recalculada → estado IN_PROGRESS após recálculo.
- **DestinationReachedEvent**: chegada → estado ARRIVED; para envio de posições e mostra "Chegada confirmada".
- **IncidentActivatedEvent**: incidentId, incidentType, severity, lat, lon, radiusMeters, expiresAt — adicionado ao mapa/lista.
- **IncidentExpiredEvent**: incidentId — removido ou marcado inativo na UI.

## Máquina de estados (doc 11)

Estados do veículo no app: IN_PROGRESS, DEGRADED_ESTIMATE, RECALCULATING, ARRIVED, STOPPED, FAILED. Atualizados por eventos ETA e por timer de "sinal perdido" (sem ETA por 20s → DEGRADED_ESTIMATE).

## Headers e tratamento de erro

- **X-Trace-Id**: enviado em todas as requisições HTTP; exibido em telas de erro para suporte.
- **429**: Retry-After respeitado no envio de locations; throttle no botão "Recalcular rota" (30s).
- **5xx**: Backoff exponencial no POST /locations (até 3 tentativas).
