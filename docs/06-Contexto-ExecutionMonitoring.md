# 06 - Contexto ExecutionMonitoring

## Responsabilidade

Acompanhar execucao em campo, processar posicao em tempo real, manter ETA atualizado,
decidir recalculo quando necessario, detectar inatividade e perda de sinal,
e gerar trilha de auditoria completa para cada decisao. Este e o **hot path** do sistema.

## Aggregate Root: `RouteExecution`

## Entidades

| Tabela | Campos principais | Notas |
|--------|-------------------|-------|
| `route_execution` | id, optimization_id, vehicle_id, status, route_version | Estado da execucao |
| `live_position` | id, execution_id, location, speed_mps, heading, accuracy_m, recorded_at | Telemetria |
| `execution_event` | id, execution_id, event_type, trace_id, source_event_id, decision, duration_ms, payload (JSONB), created_at | Auditoria ponta a ponta |

## Estados do veiculo

```text
IN_PROGRESS
  |--(sem sinal > signal_lost_seconds)-----> DEGRADED_ESTIMATE
  |--(desvio + throttle ok)----------------> RECALCULATING
  |--(chegada)-----------------------------> ARRIVED
  |--(parado > vehicle_stopped_seconds)----> STOPPED (novo)
  |--(abandonado > vehicle_abandoned_sec)--> FAILED (novo)

DEGRADED_ESTIMATE
  |--(sinal recuperado)----> IN_PROGRESS
  |--(chegada confirmada)--> ARRIVED

RECALCULATING
  |--(rota recalculada)----> IN_PROGRESS
  |--(falha no recalculo)--> DEGRADED_ESTIMATE

STOPPED
  |--(movimento retomado)--> IN_PROGRESS
  |--(sem sinal > timeout)-> DEGRADED_ESTIMATE
```

## Pipeline por LocationUpdatedEvent (hot path)

1. Deserializar evento (< 1 ms).
2. Extrair `traceId` do header NATS (ou gerar se ausente).
3. Carregar `VehicleState` de Redis (1-3 ms).
4. Verificar stale: rejeitar se `occurredAt < lastProcessedAt`.
5. Projetar posicao no corredor da rota (R-tree, 1-5 ms).
6. Aplicar policies em cadeia (< 1 ms):
   - `DestinationArrivalPolicy`
   - `RecalculationThrottlePolicy`
   - `RouteDeviationPolicy`
   - `IncidentImpactPolicy`
   - `EtaUpdatePolicy`
7. Atualizar `EtaState` (< 1 ms): usar **velocidade reportada pelo veiculo** (`event.payload.speedMps`) como entrada do EtaEngine (EWMA + calculo de remainingSeconds). O campo `live_position.speed_mps` persiste esse valor para auditoria e deteccao de veiculo parado.
8. Persistir estado em Redis + batch async para PostgreSQL.
9. Persistir `execution_event` com `traceId`, `sourceEventId`, `decision`, `durationMs`.
10. Publicar evento de saida via NATS (1-3 ms).
11. Em caso de erro: publicar na DLQ com payload original e traceId.

**Total p95 esperado: 10-25 ms** (sem recalculo).

## Deteccao de inatividade: InactivityDetectorJob

### Problema

O hot path so reage quando chega um `LocationUpdatedEvent`. Se o dispositivo
para de enviar (offline, bateria, crash), nenhum evento chega e o veiculo
fica "congelado" com o ultimo ETA.

### Solucao: scheduled job

`InactivityDetectorJob` roda a cada **10 segundos** e escaneia veiculos ativos
no Redis para detectar 3 cenarios distintos:

### Cenarios e thresholds

| Cenario | Condicao | Threshold padrao | Acao |
|---------|----------|------------------|------|
| **Sem sinal** | Nenhum evento recebido ha X segundos | `signal-lost-seconds: 20` | Status -> DEGRADED_ESTIMATE, emitir SIGNAL_LOST, push EtaDegradedEvent |
| **Veiculo parado** | Ultimos N eventos com speed < 1 m/s | `vehicle-stopped-seconds: 120` | Status -> STOPPED, emitir execution_event(VEHICLE_STOPPED) |
| **Abandonado** | Sem sinal ha muito tempo | `vehicle-abandoned-seconds: 3600` | Status -> FAILED, emitir execution_event(VEHICLE_ABANDONED), alertar operacao |

### Diferenca entre "sem sinal" e "parado"

| | Sem sinal | Parado |
|-|-----------|--------|
| Ultimo evento | Ha > 20s | Recente (< 20s) |
| Speed | Desconhecido | < 1 m/s |
| Heading | Desconhecido | Estavel |
| Acao | Extrapolar ETA + degradar | Manter ETA (distance nao muda) |
| Status | DEGRADED_ESTIMATE | STOPPED |

### Emissao de SIGNAL_LOST e SIGNAL_RECOVERED

Quando `InactivityDetectorJob` detecta que `now - lastLocationAt > signal_lost_seconds`:

1. Se o veiculo **ainda nao esta** em DEGRADED_ESTIMATE:
   - Mudar status para DEGRADED_ESTIMATE.
   - Persistir `execution_event(SIGNAL_LOST, traceId=null, decision='DEGRADED')`.
   - Publicar `EtaDegradedEvent` via NATS.
   - Push `DEGRADED` via WebSocket.

Quando o proximo `LocationUpdatedEvent` chega para um veiculo em DEGRADED_ESTIMATE:

1. Mudar status para IN_PROGRESS.
2. Persistir `execution_event(SIGNAL_RECOVERED, sourceEventId=<eventId>)`.
3. Processar normalmente (ETA update).

### Implementacao

```java
@Component
@Slf4j
public class InactivityDetectorJob {

    private final VehicleStateStore stateStore;
    private final EventPublisher eventPublisher;
    private final ExecutionEventRepository auditRepo;
    private final EtaWebSocketHandler wsHandler;

    @Value("${routing.eta.signal-timeout-seconds:20}")
    private long signalLostSec;

    @Value("${routing.inactivity.vehicle-stopped-seconds:120}")
    private long stoppedSec;

    @Value("${routing.inactivity.vehicle-abandoned-seconds:3600}")
    private long abandonedSec;

    @Scheduled(fixedRate = 10_000)
    public void detectInactiveVehicles() {
        Instant now = Instant.now();
        // scan all active vehicles from Redis
        // for each: check lastLocationAt, speedMps, status
        // apply thresholds and emit events
    }
}
```

## Escala para 1000+ veiculos

- 1 particao NATS por faixa de `vehicleId`.
- Cada consumer processa ~100-200 veiculos.
- 5-10 consumers para 1000 veiculos a 5 updates/s cada.
- Estado em Redis com chave `vehicle:{vehicleId}:state`.
- `live_position` particionado por mes no PostgreSQL.
- `InactivityDetectorJob` roda em 1 instancia (leader election ou distributed lock).

## Performance de persistencia

- `live_position`: batch insert a cada 1 s (ou 100 registros).
- `execution_event`: write-behind assincrono, batch de 50.
- TTL de dados brutos: 30 dias (depois archive/delete).

## Eventos de saida

- `EtaUpdatedEvent`
- `EtaDegradedEvent`
- `RecalculateRouteRequested`
- `DestinationReachedEvent`
- `SignalLostEvent` (novo)
- `SignalRecoveredEvent` (novo)

## Auditoria por evento

Cada `LocationUpdatedEvent` processado gera 1 `execution_event` com:
- `trace_id`: rastreio ponta a ponta
- `source_event_id`: UUID do LocationUpdatedEvent que gerou a decisao
- `decision`: ETA_ONLY, RECALCULATE, ARRIVED, DEGRADED, PROCESSING_FAILED
- `duration_ms`: tempo total de processamento
- `payload`: dados complementares (etaState, incidentFactor, errorMessage)

Em caso de falha, o evento original vai para DLQ (ver doc 10).
