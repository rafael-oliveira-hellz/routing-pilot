# 01 - Visão Geral e Arquitetura Event-Driven

## Escopo

Backbone de eventos para roteamento, ETA e incidentes em tempo real.
Escala: **1000+ veículos**, cada um com **1000+ pontos/rotas**.

## Fluxo macro

```text
Mobile/GPS Device ──► LocationUpdatedEvent
                          │
User App ──────────► IncidentReportedEvent
                          │
                    ┌─────▼─────┐
                    │   NATS    │  (JetStream, partição por vehicleId)
                    │ JetStream │
                    └─────┬─────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌──────────┐   ┌───────────┐   ┌─────────────┐
   │ Tracking │   │ Incident  │   │   Routing   │
   │ Service  │   │  Service  │   │   Engine    │
   │(hot path)│   │(aggregate)│   │ (cold path) │
   └────┬─────┘   └─────┬─────┘   └──────┬──────┘
        │               │                │
        ▼               ▼                ▼
   EtaUpdated    IncidentAggregated  RouteRecalculated
        │               │                │
        └───────┬───────┘────────────────┘
                ▼
        ┌──────────────┐
        │  WebSocket / │
        │ Push Gateway │
        └──────────────┘
```

## Topologia de serviços

| Serviço | Tipo | Responsabilidade | Escala |
|---------|------|------------------|--------|
| `route-tracking-service` | Hot path | Localização, ETA incremental, policies | N instâncias por partição |
| `routing-engine-service` | Cold path | Christofides + 2-opt + VRP | Pool dedicado |
| `incident-service` | Warm path | Ingestão, agregação e expiração de incidentes | 2-4 instâncias |
| `route-planning-service` | API | Criação de requests e constraints | Auto-scale |
| `notification-gateway` | Fan-out | WebSocket/push para clientes | Sticky por conexão |
| `state-store` | Infra | PostgreSQL/PostGIS + Redis | Cluster |

## Broker: NATS JetStream

### Por que NATS em vez de Kafka

- Open source, sem JVM no broker (Go nativo).
- Latência sub-milissegundo.
- JetStream para persistência e replay.
- Custo operacional ~3× menor que Kafka em infra equivalente.
- Consumer groups nativos (queue groups).
- Suporte a key-value store embutido (substituir Redis para estado leve).

### Subjects recomendados

```text
route.location.{vehicleId}          # posição em tempo real
route.eta.{vehicleId}               # ETA atualizado
route.recalc.requested.{vehicleId}  # pedido de recálculo
route.recalc.completed.{vehicleId}  # rota recalculada
route.arrived.{vehicleId}           # destino alcançado
incident.reported.{regionTile}      # incidente reportado por tile
incident.aggregated.{regionTile}    # incidente consolidado
incident.expired.{regionTile}       # incidente expirado
```

### Garantias

- Ordem por veículo via subject particionado.
- Idempotência por `Nats-Msg-Id` (dedup nativo do JetStream).
- Replay para reprocessamento.
- Backpressure via `MaxAckPending` por consumer.

## Latência alvo (p95)

| Fluxo | Alvo |
|-------|------|
| `LocationUpdated` → `EtaUpdated` | ≤ 100 ms |
| `RecalculateRequested` → `RouteRecalculated` | 150ms (100 pts), ≤ 400 ms (1000 pts) |
| `IncidentReported` → impacto no ETA | ≤ 70 ms |
| Push ao cliente após ETA | ≤ 170 ms |

## Decisão de performance

- 90-95% dos eventos ficam no hot path (ETA-only).
- Recálculo é exceção governada por policy.
- Incidentes influenciam `trafficFactor` sem forçar recálculo imediato.
