# 13 - Operacao, SLOs e Runbooks

## Observabilidade

### Logs estruturados (JSON)

Campos obrigatórios em todo log:
- `vehicleId`, `routeId`, `routeVersion`
- `eventId`, `eventType`
- `decision` (ETA_ONLY, RECALC_ROUTE, ARRIVED, DEGRADED)
- `processingMs`
- `traceId`, `spanId`

### Métricas (Micrometer → Prometheus)

| Métrica | Tipo | Labels |
|---------|------|--------|
| `route.events.processed` | Counter | eventType |
| `route.eta.update.duration` | Timer | - |
| `route.recalc.duration` | Timer | reason |
| `route.recalc.count` | Counter | vehicleId, reason |
| `route.deviation.detected` | Counter | - |
| `route.arrival.detected` | Counter | - |
| `incident.reported` | Counter | incidentType |
| `incident.active` | Gauge | severity |
| `nats.consumer.lag` | Gauge | consumer, stream |
| `eta.confidence.avg` | Gauge | - |

### Tracing (OpenTelemetry)

- Trace por evento do broker até push ao cliente.
- Span separado para: policy chain, ETA calculation, route recalculation.
- Propagação de `traceId` via headers NATS.

## SLO / SLI

| SLI | Target | Medição |
|-----|--------|---------|
| ETA update latency p95 | ≤ 200 ms | Timer `route.eta.update.duration` |
| Route recalc latency p95 | ≤ 5 s (500 pts) | Timer `route.recalc.duration` |
| ETA degraded rate | < 2% | `degraded_events / total_events` |
| Recalc avoided by policy | > 90% | `eta_only / total_decisions` |
| Incident activation latency p95 | ≤ 500 ms | Timer `incident.activation.duration` |
| Destination detection accuracy | > 99% | Manual audit sample |

## Runbooks

### RB-01: Pico de recálculo inesperado

**Sintoma**: `route.recalc.count` dispara acima do threshold.

**Ações**:
1. Verificar threshold de `RouteDeviationPolicy` (muito baixo?).
2. Inspecionar qualidade GPS (jitter alto → desvios falsos).
3. Aumentar `MIN_INTERVAL_SECONDS` temporariamente.
4. Verificar se incidente CRITICAL massivo está ativo.

### RB-02: Aumento de ETA degradado

**Sintoma**: `EtaDegradedEvent` em alta.

**Ações**:
1. Conferir atraso de ingestão de localização (NATS lag).
2. Verificar conectividade dos devices (rede celular).
3. Aumentar janela de extrapolação controlada.
4. Sinalizar badge de confiança baixa no frontend.

### RB-03: Consumer lag no NATS

**Ações**:
1. Escalar consumers da partição afetada.
2. Verificar se routing engine está lento (cold path).
3. Ativar modo de prioridade (arrived/deviation first).
4. Reduzir frequência de push para clientes menos críticos.

### RB-04: Falha no routing engine

**Ações**:
1. Circuit breaker abre automaticamente.
2. ETA continua em modo incremental/degradado.
3. `RecalculateRouteRequested` reenfileirado com retry exponencial.
4. Alertar on-call com lista de `vehicleId` impactados.

### RB-05: Explosão de incidentes falsos (spam)

**Ações**:
1. Verificar rate limit por usuário.
2. Aumentar quorum para tipos LOW/OTHER.
3. Bloquear usuários com score de confiança negativo.
4. Review manual dos tiles com mais de 10 incidentes ativos.
