# Pendências do app (backend) — implementado no skeleton

Tudo abaixo está **implementado** no skeleton, conforme `docs/14-Checklist-Sprints.md`.

---

## 1. GET resultado da rota — `trafficLevel` por segmento (Sprint 3)

**Endpoint:** `GET /api/v1/route-requests/{id}/result`

**Implementado:**
- Controller: `RouteRequestController.getResult(@PathVariable UUID id)` → 200 com body ou 404.
- Port: `GetRouteResultPort.getByRouteRequestId(routeRequestId)`.
- Use case: `GetRouteResultUseCase` — busca última otimização COMPLETED do route-request, resultado, segmentos (ordenados por `segment_order`), waypoints; monta DTO.
- DTO: `RouteResultResponse` com `totalDistanceMeters`, `totalDurationSeconds`, `segments[]` (id, fromPoint, toPoint, distanceMeters, travelTimeSeconds, **trafficLevel**), **trafficLightsAlongRoute** (opcional).
- Coluna `route_segment.traffic_level` (V007) e campo `RouteSegmentJpaEntity.trafficLevel`.
- `RecalculateRouteUseCase` persiste segmentos com waypoints (location), segment_order, path_geometry e trafficLevel=null.
- **trafficLevel na resposta:** no GET result, cada segmento tem `trafficLevel` definido com base em **segment_incident_display**: se o segmento tiver incidente ativo com tipo HEAVY_TRAFFIC ou severidade HIGH/CRITICAL → `"HEAVY"`; senão `"NORMAL"` (ou o valor já persistido no segmento, se houver).

---

## 2. POIs / semáforos no mapa (Sprint 6)

**Implementado:**

- **Opção A — GET /api/v1/pois:**  
  `PoiController.list(lat, lon, radius, type)` → `GET /api/v1/pois?lat=&lon=&radius=&type=TRAFFIC_LIGHT` retorna `[{ id, lat, lon, type }]`.  
  Port: `PoiQueryPort.findByLocationAndType(lat, lon, radiusMeters, type)`.  
  Implementação: **OsmPoiQueryAdapter** usando **geo.osm_pois** (V004) para tipos amenity/shop/tourism; para **TRAFFIC_LIGHT** consulta **geo.osm_other** (tags->>'highway' = 'traffic_signals').

- **Opção B — trafficLightsAlongRoute no resultado da rota:**  
  No GET result, o campo **trafficLightsAlongRoute** é preenchido com semáforos (osm_other, traffic_signals) na bbox dos waypoints da rota.  
  Port: `PoiQueryPort.findTrafficLightsInBbox(minLat, maxLat, minLon, maxLon)`.

Nenhuma tabela nova: usa **geo.osm_pois** (V004) e **geo.osm_other** (V004) para semáforos.

---

## 3. Respostas de erro e traceId (Sprint 8)

**Implementado:**
- `ErrorResponse`: body com `message`, `errorCode`, `traceId`, `path`, `timestamp`.
- `TraceIdFilter`: lê header **X-Trace-Id** da requisição (ou gera UUID), coloca no MDC e repete no header da resposta; limpa no finally. Todas as respostas de erro REST passam a incluir o traceId.

---

## 4. Rate limit 429 + Retry-After (Sprint 4 / Sprint 8)

**Implementado:**
- `GlobalExceptionHandler.handleRateLimit`: em 429 adiciona header **Retry-After** (segundos).
- `RateLimitExceededException.getRetryAfterSeconds()` (default 60).
- `LocationIngestionController`: antes de processar o batch, chama `RateLimitPort.isLocationRateLimited(vehicleId)` e lança `RateLimitExceededException` com 60s se limitado.
