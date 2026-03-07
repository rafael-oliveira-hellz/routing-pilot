# Backend — Pendências para o App (lista em formato Sprint/TODO)

Lista de itens que o **backend** precisa implementar ou expor para o app consumir. Organizada como sprints/todo. O app já está preparado para usar assim que o backend entregar.

---

## Sprint Mapa (trânsito, radar, semáforos)

Pendências identificadas a partir do app (mapa com nomes de ruas, radar pulsante, trânsito por segmento, semáforos).

### Trânsito intenso por segmento
- [ ] No GET do resultado da rota (`/api/v1/route-requests/{id}/result`), em cada item de `segments[]`, incluir o campo **`trafficLevel`**.
- [ ] Valores esperados: `"HEAVY"` para trecho com trânsito intenso; omitir ou `"NORMAL"` para trecho fluido.
- [ ] **Por enquanto**, definir `trafficLevel` com base nos **incidentes reportados pelos usuários** (ex.: segmentos afetados por incidentes do tipo HEAVY_TRAFFIC ou com severidade alta); futuramente pode vir de provedor de trânsito.
- [ ] O app pinta em **vermelho** os segmentos com `trafficLevel: "HEAVY"` e em azul o restante.
- [ ] Fonte do dado: integração com dados de trânsito (ex.: provedor externo ou heurística por velocidade/congestionamento).

### Semáforos (POIs no mapa)
- [ ] Expor pontos de semáforo para o app exibir no mapa (ícone onde houver semáforo).
- [ ] Opção A: endpoint de POIs, ex. `GET /api/v1/pois?lat=&lon=&radius=&type=TRAFFIC_LIGHT` retornando lista `[{ id, lat, lon, type }]`.
- [ ] Opção B: incluir no resultado da rota um array opcional `trafficLightsAlongRoute: [{ lat, lon }]`.
- [ ] App: quando o dado existir, adicionar camada de marcadores (semáforo) no mapa.

### Radar (BLITZ)
- [ ] Já coberto: incidentes tipo **BLITZ** (reportar e listar). O app exibe com marcador pulsante.
- [ ] Nenhuma pendência adicional para radar.

---

## Sprint APIs / Contratos já usados pelo app

Checklist do que o app **já consome**; garantir que o backend implemente ou mantenha estável.

### Auth
- [ ] POST /api/v1/auth/login (email, password, rememberMe) → accessToken, refreshToken, user (id, email, name, vehicleId, role)
- [ ] POST /api/v1/auth/refresh (refreshToken) → accessToken
- [ ] POST /api/v1/auth/logout (Bearer)
- [ ] POST /api/v1/auth/forgot-password, reset-password, change-password
- [ ] POST /api/v1/auth/revoke-all-other-sessions (Bearer) → opcional novo refreshToken

### Rotas
- [ ] POST /api/v1/route-requests (body: points, stops, constraints, departureAt) → id, status
- [ ] GET /api/v1/route-requests/{id}/result → id, routeRequestId, status, totalDistanceMeters, totalDurationSeconds, waypointCount, pathGeometry, segments (com opcional trafficLevel), waypoints, recalculationReason
- [ ] POST /api/v1/route-requests/{id}/recalculate (body: { reason }) 

### Locations
- [ ] POST /api/v1/locations (body: vehicleId, routeId, routeVersion, positions[]) → 202 com opcional { accepted, duplicates, rejected }; suportar 429 com Retry-After

### Incidentes
- [ ] POST /api/v1/incidents (lat, lon, incidentType, severity?, description?, reportedBy) → incidentId
- [ ] POST /api/v1/incidents/{id}/vote (body: { voteType: CONFIRM | DENY | GONE })
- [ ] GET /api/v1/incidents?lat=&lon=&radius= → lista de incidentes (id, lat, lon, incidentType, severity, description?, expiresAt, etc.)

### WebSockets
- [ ] /ws/eta?token=&vehicleId=&routeId= → eventos EtaUpdatedEvent, RouteRecalculatedEvent, DestinationReachedEvent
- [ ] /ws/incidents?token=&lat=&lon=&radius= → eventos IncidentActivatedEvent, IncidentExpiredEvent

---

## Sprint Observabilidade / Erro

- [ ] Respostas de erro no padrão do app: body com `message`, `errorCode`, `traceId` (e opcional `path`, `timestamp`).
- [ ] Header **X-Trace-Id** aceito e propagado (logs, eventos, DLQ) para o app exibir “Código: {traceId}” em telas de erro.
- [ ] 429 com header **Retry-After** (segundos) quando aplicável (ex.: rate limit de locations ou incidentes).

---

## Resumo rápido

| Pendência              | Onde no backend                         | Status app        |
|------------------------|-----------------------------------------|-------------------|
| trafficLevel por segmento | GET result → segments[].trafficLevel   | ✅ Pronto (vermelho/azul) |
| Semáforos (POIs)       | Novo endpoint ou campo no result        | ⏳ Aguardando dado |
| Contratos APIs/WS      | Conforme doc 11 e 14                    | ✅ App alinhado   |
| Erro + traceId         | ErrorResponse + X-Trace-Id + 429        | ✅ App usa        |

Quando o backend entregar **trafficLevel** em `segments[]` e, se quiser, POIs de semáforo, o app já está preparado para consumir e exibir.
