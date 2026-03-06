# 11 - Contratos de Eventos e Maquina de Estados

## Broker: NATS JetStream

### Streams recomendados

| Stream | Subjects | Retention | Max Age | Storage |
|--------|----------|-----------|---------|---------|
| `ROUTE_TRACKING` | `route.location.>`, `route.eta.>`, `route.arrived.>` | Limits | 24 h | File |
| `ROUTE_RECALC` | `route.recalc.>` | WorkQueue | 1 h | File |
| `INCIDENTS` | `incident.>` | Limits | 48 h | File |

### Consumer Groups

| Consumer | Stream | Filter | Deliver | Max Ack Pending |
|----------|--------|--------|---------|-----------------|
| `tracking-worker` | ROUTE_TRACKING | `route.location.>` | Push/QueueGroup | 500 |
| `recalc-worker` | ROUTE_RECALC | `route.recalc.requested.>` | Pull | 10 |
| `incident-worker` | INCIDENTS | `incident.reported.>` | Push/QueueGroup | 200 |
| `eta-fanout` | ROUTE_TRACKING | `route.eta.>` | Push | 1000 |

---

## Contratos de Eventos (JSON Schema)

### LocationUpdatedEvent

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "LocationUpdatedEvent",
  "type": "object",
  "required": ["eventId", "eventType", "vehicleId", "routeId", "routeVersion", "occurredAt", "payload"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "LocationUpdatedEvent" },
    "vehicleId": { "type": "string" },
    "routeId": { "type": "string" },
    "routeVersion": { "type": "integer", "minimum": 0 },
    "occurredAt": { "type": "string", "format": "date-time" },
    "payload": {
      "type": "object",
      "required": ["lat", "lon", "speedMps"],
      "properties": {
        "lat": { "type": "number", "minimum": -90, "maximum": 90 },
        "lon": { "type": "number", "minimum": -180, "maximum": 180 },
        "speedMps": { "type": "number", "minimum": 0 },
        "heading": { "type": "number", "minimum": 0, "maximum": 360 },
        "accuracyMeters": { "type": "number", "minimum": 0 }
      }
    }
  }
}
```

- **payload.speedMps**: velocidade reportada pelo veículo (m/s). Obrigatório. Usado pelo EtaEngine como velocidade observada (EWMA) para cálculo incremental do ETA; sem ele o ETA não reflete a velocidade real.

### EtaUpdatedEvent

```json
{
  "$id": "EtaUpdatedEvent",
  "type": "object",
  "required": ["eventId", "eventType", "vehicleId", "routeId", "routeVersion", "occurredAt", "payload"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "EtaUpdatedEvent" },
    "vehicleId": { "type": "string" },
    "routeId": { "type": "string" },
    "routeVersion": { "type": "integer" },
    "occurredAt": { "type": "string", "format": "date-time" },
    "payload": {
      "type": "object",
      "required": ["remainingSeconds", "confidence", "degraded", "distanceRemainingMeters"],
      "properties": {
        "remainingSeconds": { "type": "integer", "minimum": 0 },
        "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
        "degraded": { "type": "boolean" },
        "distanceRemainingMeters": { "type": "number", "minimum": 0 }
      }
    }
  }
}
```

### RecalculateRouteRequested

```json
{
  "$id": "RecalculateRouteRequested",
  "type": "object",
  "required": ["eventId", "eventType", "vehicleId", "routeId", "occurredAt", "payload"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "RecalculateRouteRequested" },
    "vehicleId": { "type": "string" },
    "routeId": { "type": "string" },
    "occurredAt": { "type": "string", "format": "date-time" },
    "payload": {
      "type": "object",
      "required": ["reason"],
      "properties": {
        "reason": { "type": "string", "enum": ["ROUTE_DEVIATION", "INCIDENT_CRITICAL", "MANUAL_DESTINATION_CHANGE", "STRATEGIC_REOPTIMIZATION", "TRAFFIC_SEVERE"] },
        "distanceToCorridorMeters": { "type": "number" }
      }
    }
  }
}
```

### IncidentReportedEvent

```json
{
  "$id": "IncidentReportedEvent",
  "type": "object",
  "required": ["eventId", "eventType", "occurredAt", "payload"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "IncidentReportedEvent" },
    "occurredAt": { "type": "string", "format": "date-time" },
    "payload": {
      "type": "object",
      "required": ["lat", "lon", "incidentType", "reportedBy"],
      "properties": {
        "lat": { "type": "number", "minimum": -90, "maximum": 90 },
        "lon": { "type": "number", "minimum": -180, "maximum": 180 },
        "incidentType": { "type": "string", "enum": ["BLITZ","ACCIDENT","HEAVY_TRAFFIC","WET_ROAD","FLOOD","ROAD_WORK","BROKEN_TRAFFIC_LIGHT","ANIMAL_ON_ROAD","VEHICLE_STOPPED","LANDSLIDE","FOG","OTHER"] },
        "severity": { "type": "string", "enum": ["LOW","MEDIUM","HIGH","CRITICAL"] },
        "description": { "type": "string", "maxLength": 500 },
        "reportedBy": { "type": "string", "format": "uuid" }
      }
    }
  }
}
```

### IncidentActivatedEvent

```json
{
  "$id": "IncidentActivatedEvent",
  "type": "object",
  "required": ["eventId", "eventType", "occurredAt", "payload"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "IncidentActivatedEvent" },
    "occurredAt": { "type": "string", "format": "date-time" },
    "payload": {
      "type": "object",
      "required": ["incidentId", "incidentType", "severity", "lat", "lon", "radiusMeters", "regionTileX", "regionTileY", "expiresAt"],
      "properties": {
        "incidentId": { "type": "string", "format": "uuid" },
        "incidentType": { "type": "string" },
        "severity": { "type": "string" },
        "lat": { "type": "number" },
        "lon": { "type": "number" },
        "radiusMeters": { "type": "integer" },
        "regionTileX": { "type": "integer" },
        "regionTileY": { "type": "integer" },
        "expiresAt": { "type": "string", "format": "date-time" }
      }
    }
  }
}
```

### RouteRecalculatedEvent / DestinationReachedEvent

```json
{
  "$id": "RouteRecalculatedEvent",
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "RouteRecalculatedEvent" },
    "vehicleId": { "type": "string" },
    "routeId": { "type": "string" },
    "routeVersion": { "type": "integer" },
    "payload": {
      "properties": {
        "totalDistanceMeters": { "type": "number" },
        "totalDurationSeconds": { "type": "number" },
        "waypointCount": { "type": "integer" }
      }
    }
  }
}
```

```json
{
  "$id": "DestinationReachedEvent",
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "eventType": { "const": "DestinationReachedEvent" },
    "vehicleId": { "type": "string" },
    "routeId": { "type": "string" },
    "payload": {
      "properties": {
        "distanceToDestinationMeters": { "type": "number" },
        "totalElapsedSeconds": { "type": "integer" }
      }
    }
  }
}
```

---

## Máquina de estados da execução

```text
         ┌──────────────────────────────────────────────────┐
         │                                                  │
         ▼                                                  │
    IN_PROGRESS ──(sem sinal > timeout)──► DEGRADED_ESTIMATE│
         │                                      │           │
         ├──(desvio + throttle ok)──► RECALCULATING──(ok)───┘
         │                                │
         │                         (falha)─┘──► DEGRADED_ESTIMATE
         │
         └──(chegada)──► ARRIVED
```

## Garantias de consistência

- Rejeitar evento com `occurredAt < lastProcessedAt` por veículo.
- Ignorar `routeVersion` obsoleto.
- Dedup por `eventId` via `Nats-Msg-Id` + JetStream dedup window (2 min).
- Persistir `lastProcessedSeq` por consumer para crash recovery.
