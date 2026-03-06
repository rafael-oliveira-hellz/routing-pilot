# 05 - Ingestao GPS e Resiliencia Offline

## Objetivo

Definir como dispositivos moveis enviam posicoes ao backend de forma confiavel,
mesmo com perda de conectividade, e como o servidor ingere, valida e deduplicada
esses dados em escala de 1000+ veiculos.

---

## API de ingestao

### Endpoint

```
POST /api/v1/locations
Authorization: Bearer <JWT>
Content-Type: application/json
```

O JWT deve conter `vehicleId` no claim. O servidor rejeita qualquer payload
cujo `vehicleId` no body nao coincida com o claim do token.

### Contrato da request (batch)

```json
{
  "vehicleId": "veh-001",
  "routeId": "route-abc",
  "routeVersion": 12,
  "positions": [
    {
      "lat": -23.5505,
      "lon": -46.6333,
      "speedMps": 13.9,
      "heading": 180.0,
      "accuracyMeters": 8.0,
      "occurredAt": "2026-03-02T10:00:00Z"
    },
    {
      "lat": -23.5510,
      "lon": -46.6340,
      "speedMps": 14.2,
      "heading": 175.0,
      "accuracyMeters": 6.0,
      "occurredAt": "2026-03-02T10:00:03Z"
    }
  ]
}
```

### Resposta

```json
{
  "accepted": 2,
  "duplicates": 0,
  "rejected": 0
}
```

HTTP 202 Accepted (processamento assincrono).
HTTP 429 Too Many Requests com header `Retry-After: 2` quando rate limit excedido.
HTTP 401 Unauthorized quando JWT invalido ou `vehicleId` divergente.

---

## Frequencia de envio (client-side)

| Cenario | Intervalo | Motivo |
|---------|-----------|--------|
| Movimento normal | 3-5 s | Balanco entre precisao e custo |
| Curva ou desvio | 1 s | Detectar desvio de rota rapido |
| Veiculo parado (speed < 1 m/s) | 10 s | Economizar bateria e banda |
| Sem movimento por > 2 min | 30 s | Heartbeat minimo |

O intervalo deve ser adaptativo: o cliente monitora `speedMps` e `headingDelta`
para decidir a frequencia.

---

## Batching client-side

- Acumular posicoes ate **10 posicoes** ou **5 segundos**, o que ocorrer primeiro.
- Enviar como array no campo `positions`.
- Cada posicao tem seu `occurredAt` original (timestamp do GPS, nao do envio).
- O servidor processa cada posicao individualmente, na ordem de `occurredAt`.
- O campo **`speedMps`** (velocidade em m/s) e obrigatorio por posicao: e usado pelo motor de ETA para calcular o tempo restante (EWMA + distancia restante). Sem velocidade reportada pelo veiculo, o ETA nao reflete a velocidade real.

---

## Buffer offline (resiliencia)

### Comportamento do cliente quando sem internet

1. Posicoes continuam sendo coletadas do GPS.
2. Armazenadas em **buffer local persistente** (SQLite ou Room no Android, CoreData no iOS).
3. Buffer maximo: 10.000 posicoes (~3h de coleta a 1/s).
4. Quando buffer estiver 90% cheio, descartar posicoes mais antigas (FIFO).

### Comportamento ao reconectar

1. Enviar posicoes buffered em **batches de 50**, ordenadas por `occurredAt` ASC.
2. Intervalo entre batches: 200 ms (evitar burst).
3. O servidor aceita posicoes com `occurredAt` no passado (replay).
4. Dedup server-side garante idempotencia.

### Diagrama de fluxo offline

```text
[GPS Sensor]
    |
    v
[Buffer Local (SQLite)]
    |
    +--(online)--> [POST /api/v1/locations] --> [NATS]
    |
    +--(offline)--> [acumula no buffer]
    |
    +--(reconecta)--> [envia batches atrasados em ordem]
```

---

## Deduplicacao server-side

### Estrategia

- Chave de dedup: `(vehicleId, occurredAt)` com granularidade de milissegundo.
- Janela de dedup: 2 minutos (Redis SET com TTL).
- Chave Redis: `dedup:{vehicleId}:{occurredAtEpochMs}`.
- Se chave ja existe: posicao descartada como duplicata, contabilizada no response.

### Implementacao

```java
public boolean isDuplicate(String vehicleId, Instant occurredAt) {
    String key = "dedup:" + vehicleId + ":" + occurredAt.toEpochMilli();
    Boolean wasAbsent = redis.opsForValue().setIfAbsent(key, "1", Duration.ofMinutes(2));
    return wasAbsent == null || !wasAbsent;
}
```

---

## Rate limiting

| Escopo | Limite | Janela | Acao |
|--------|--------|--------|------|
| Por `vehicleId` | 20 req/s | Sliding window | HTTP 429 + `Retry-After` |
| Global | 50.000 req/s | Sliding window | HTTP 503 |

Implementacao via Redis sliding window ou bucket4j.

---

## Fluxo server-side completo

```text
POST /api/v1/locations
    |
    v
[1. Auth: validar JWT, extrair vehicleId]
    |
    v
[2. Rate limit: verificar vehicleId]
    |
    v
[3. Validacao: lat [-90,90], lon [-180,180], occurredAt nao futuro]
    |
    v
[4. Para cada posicao no batch:]
    |-- [4a. Dedup: verificar (vehicleId, occurredAt)]
    |-- [4b. Enriquecer: gerar eventId (UUID), adicionar traceId; incluir speedMps no payload (obrigatorio para ETA)]
    |-- [4c. Publicar LocationUpdatedEvent no NATS subject route.location.{vehicleId} (payload com lat, lon, speedMps, ...)]
    |
    v
[5. Retornar accepted/duplicates/rejected]
```

---

## Seguranca

- JWT assinado com RS256, expirado em 1h, refresh via endpoint separado.
- `vehicleId` no claim `sub` ou claim customizado `vehicle_id`.
- TLS obrigatorio (HTTPS).
- Payload maximo: 100 KB por request (limitado no gateway/nginx).

---

## Metricas de ingestao

| Metrica | Tipo | Labels |
|---------|------|--------|
| `location.ingestion.received` | Counter | vehicleId, status(accepted/duplicate/rejected) |
| `location.ingestion.batch_size` | Histogram | - |
| `location.ingestion.latency_ms` | Timer | - |
| `location.ingestion.rate_limited` | Counter | vehicleId |
| `location.ingestion.offline_replay` | Counter | vehicleId |
