# 10 - Auditoria Ponta a Ponta, Observabilidade e Tratamento de Erros

## Objetivo

Garantir que para qualquer erro ou decisao no sistema, seja possivel responder:
- Qual dado de entrada causou o erro ou a decisao?
- Em qual etapa do pipeline ocorreu?
- Qual foi o traceId de ponta a ponta?
- Qual o payload original que disparou o problema?

---

## Modelo de auditoria

### Principio

Cada `LocationUpdatedEvent` processado pelo tracking service gera **exatamente 1** registro
em `execution_event`, independente do resultado (sucesso, erro, ou descarte).

### Campos de rastreio

| Campo | Tipo | Descricao |
|-------|------|-----------|
| `id` | UUID | PK do registro de auditoria |
| `execution_id` | UUID | FK para route_execution |
| `event_type` | ENUM | Tipo do evento (ETA_UPDATED, DEVIATION_DETECTED, etc.) |
| `trace_id` | UUID | Trace de ponta a ponta (gerado na ingestao, propagado via NATS header) |
| `source_event_id` | UUID | eventId do LocationUpdatedEvent que gerou esta decisao |
| `decision` | VARCHAR(30) | Resultado da policy chain (ETA_ONLY, RECALCULATE, ARRIVED, DEGRADED, PROCESSING_FAILED) |
| `duration_ms` | INTEGER | Tempo de processamento em ms |
| `payload` | JSONB | Dados complementares (etaState, incidentFactor, errorMessage, etc.) |
| `created_at` | TIMESTAMPTZ | Timestamp do registro |

### Exemplo de consulta de auditoria

```sql
-- Qual decisao foi tomada para um evento especifico?
SELECT * FROM execution_event WHERE source_event_id = '<eventId>';

-- Todas as decisoes de um trace de ponta a ponta
SELECT * FROM execution_event WHERE trace_id = '<traceId>' ORDER BY created_at;

-- Todos os erros de um veiculo nas ultimas 2 horas
SELECT * FROM execution_event
WHERE execution_id IN (SELECT id FROM route_execution WHERE vehicle_id = 'veh-001')
  AND decision = 'PROCESSING_FAILED'
  AND created_at > now() - INTERVAL '2 hours';
```

---

## Propagacao de traceId

### Fluxo

```text
Mobile (gera traceId ou recebe do backend)
    |
    v
POST /api/v1/locations (traceId no header X-Trace-Id)
    |
    v
LocationIngestionController: extrai ou gera traceId
    |
    v
NATS publish: traceId no header "X-Trace-Id"
    |
    v
NatsLocationListener: extrai traceId do header NATS
    |
    v
ProcessLocationUpdateUseCase: usa traceId em logs, execution_event, e DLQ
    |
    v
WebSocket push: inclui traceId no payload para correlacao no frontend
```

### Formato

`traceId` e um UUID v4. Se o mobile nao enviar, o servidor gera um na ingestao.

---

## Dead Letter Queue (DLQ)

### Quando um evento vai para DLQ

1. Falha de desserializacao (payload invalido).
2. Excecao nao recuperavel durante processamento (NullPointer, estado inconsistente).
3. 3 tentativas falharam com erro transiente (Redis timeout, PG timeout).

### Estrutura da DLQ

NATS stream `DEAD_LETTER`, subject `route.dlq.{vehicleId}`.

### Tabela `dead_letter_event`

| Campo | Tipo | Descricao |
|-------|------|-----------|
| `id` | UUID | PK |
| `stream` | VARCHAR(60) | Stream NATS de origem |
| `subject` | VARCHAR(200) | Subject NATS original |
| `raw_payload` | JSONB | Payload original inalterado |
| `error_code` | processing_error_code_enum | Categoria do erro |
| `error_message` | TEXT | Mensagem de erro / stacktrace resumido |
| `trace_id` | UUID | Trace de ponta a ponta |
| `vehicle_id` | VARCHAR(120) | VehicleId extraido (se possivel) |
| `occurred_at` | TIMESTAMPTZ | Timestamp do evento original |
| `created_at` | TIMESTAMPTZ | Quando entrou na DLQ |
| `reprocessed` | BOOLEAN | Se ja foi reprocessado manualmente |

### Categorias de erro

```sql
CREATE TYPE processing_error_code_enum AS ENUM (
    'DESERIALIZATION_FAILED',
    'VALIDATION_FAILED',
    'STATE_LOAD_FAILED',
    'STATE_SAVE_FAILED',
    'POLICY_EXCEPTION',
    'PUBLISH_FAILED',
    'TIMEOUT',
    'UNKNOWN'
);
```

### Classificacao

| Categoria | Tipo | Acao |
|-----------|------|------|
| `DESERIALIZATION_FAILED` | PERMANENT | DLQ imediato, sem retry |
| `VALIDATION_FAILED` | PERMANENT | DLQ imediato, sem retry |
| `STATE_LOAD_FAILED` | TRANSIENT | Retry 3x, depois DLQ |
| `STATE_SAVE_FAILED` | TRANSIENT | Retry 3x, depois DLQ |
| `POLICY_EXCEPTION` | PERMANENT | DLQ imediato |
| `PUBLISH_FAILED` | TRANSIENT | Retry 3x, depois DLQ |
| `TIMEOUT` | TRANSIENT | Retry 3x, depois DLQ |
| `UNKNOWN` | PERMANENT | DLQ imediato |

### Retry policy

- 3 tentativas com backoff exponencial: 1s, 4s, 16s.
- Somente para erros TRANSIENT.
- Apos 3 falhas: persiste na DLQ + `execution_event` com `PROCESSING_FAILED`.

---

## Structured error record

```java
public record ProcessingError(
    UUID traceId,
    UUID eventId,
    String vehicleId,
    ProcessingErrorCode errorCode,
    String message,
    String rawPayload,
    Instant occurredAt,
    int attemptNumber
) {}

public enum ProcessingErrorCode {
    DESERIALIZATION_FAILED,
    VALIDATION_FAILED,
    STATE_LOAD_FAILED,
    STATE_SAVE_FAILED,
    POLICY_EXCEPTION,
    PUBLISH_FAILED,
    TIMEOUT,
    UNKNOWN
}
```

---

## Logs estruturados em caso de erro

Cada log de erro DEVE conter:

```json
{
  "level": "ERROR",
  "traceId": "uuid",
  "eventId": "uuid",
  "vehicleId": "veh-001",
  "routeId": "route-abc",
  "errorCode": "STATE_LOAD_FAILED",
  "message": "Redis timeout after 2000ms",
  "attemptNumber": 2,
  "rawPayload": "{...}",
  "timestamp": "2026-03-02T10:00:00Z"
}
```

Isso permite buscar no Kibana/Loki por `traceId` e ver exatamente o que aconteceu.

---

## Dashboard de auditoria

### Queries essenciais

| Pergunta | Query |
|----------|-------|
| Quantos eventos processados por decisao? | `SELECT decision, count(*) FROM execution_event GROUP BY decision` |
| Taxa de erro por hora? | `SELECT date_trunc('hour', created_at), count(*) FROM execution_event WHERE decision = 'PROCESSING_FAILED' GROUP BY 1` |
| Qual veiculo mais gera erros? | `SELECT vehicle_id, count(*) FROM dead_letter_event GROUP BY 1 ORDER BY 2 DESC` |
| DLQ nao reprocessada? | `SELECT * FROM dead_letter_event WHERE reprocessed = false ORDER BY created_at` |
| Trace completo de um evento? | `SELECT * FROM execution_event WHERE trace_id = '...' ORDER BY created_at` |

### Metricas Prometheus

| Metrica | Tipo |
|---------|------|
| `audit.events.total` | Counter(decision) |
| `audit.processing.duration_ms` | Histogram |
| `dlq.events.total` | Counter(errorCode) |
| `dlq.events.pending_reprocess` | Gauge |
