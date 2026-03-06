# 12 - Escalabilidade e Performance 1000x1000

## Metas de capacidade

- **1000+ veículos simultâneos**, cada um com **1000+ pontos por rota**.
- **5-20 location updates/s** por veículo (GPS típico).
- **5k a 20k eventos/s** no agregado total.
- **Centenas de incidentes ativos** simultaneamente.

## Estratégia por camada

### 1) Particionamento no broker (NATS JetStream)

- Subject particionado por `vehicleId`.
- Garante ordenação por veículo e paralelismo entre veículos.
- Para 1000 veículos: 16-32 shards suficientes.

### 2) Separação hot path / cold path

| Path | Serviço | Orçamento CPU | Frequência |
|------|---------|---------------|------------|
| Hot | route-tracking-service | 10-25 ms/evento | 90-95% dos eventos |
| Warm | incident-service | 5-15 ms/evento | < 5% |
| Cold | routing-engine-service | 1-10 s/job | < 3% |

### 3) Estado distribuído

| Store | Conteúdo | TTL | Acesso |
|-------|----------|-----|--------|
| Redis | VehicleState, EtaState, incidentes por tile | 24 h | < 3 ms |
| Redis KV (NATS) | Última posição, último recálculo | Sessão | < 1 ms |
| PostgreSQL/PostGIS | Rota, waypoints, incidentes, auditoria | Permanente | Async |

### 4) Backpressure

- `MaxAckPending` por consumer NATS.
- Fila interna com bounded capacity para recálculos.
- Circuit breaker no routing engine (Resilience4j).
- Drop de location events duplicados (dedup window).

### 5) Otimização de CPU

| Técnica | Ganho |
|---------|-------|
| Polilinha simplificada (Douglas-Peucker) | -70% pontos |
| R-tree para projeção em corredor | O(log n) vs O(n) |
| EWMA velocidade (1 multiplicação) | vs modelo físico completo |
| Cache de incidentes por tile | O(1) lookup |
| Clusterização + ForkJoinPool para rotas grandes | Linear speedup |

## Capacity planning

### Cenário: 1000 veículos, 10 updates/s cada

```text
Eventos/s: 10.000
Hot path (95%): 9.500/s → 4-8 instâncias tracking (2.5k evt/s/inst)
Cold path (3%): 300 recálculos/s → 4-6 instâncias routing
Incident (2%): 200/s → 2 instâncias
```

### Recursos estimados

| Componente | CPU | RAM | Instâncias |
|------------|-----|-----|------------|
| tracking-service | 2 vCPU | 1 GB | 4-8 |
| routing-engine | 8 vCPU | 6 GB | 2 (otimizado) / 5-6 (baseline) |
| incident-service | 1 vCPU | 512 MB | 2 |
| NATS | 2 vCPU | 1 GB | 3 (cluster) |
| Redis | 2 vCPU | 4 GB | 3 (cluster) |
| PostgreSQL | 4 vCPU | 8 GB | 1 primary + 1 read |

## Otimização para 1000 pontos por rota

- Clusterização em blocos de 150 pontos.
- ~7 clusters por rota de 1000 pontos.
- 7 tasks paralelas no ForkJoinPool.
- Tempo total (otimizado): **~126 ms para 1000 pontos** (paralelo + k-nearest + Blossom esparso + GH CH embarcado).
- Tempo total (baseline, sem otimizações agressivas): ~1.7 s.
- Warm-start com rota anterior reduz 2-opt em ~60%.
- Blossom V controlado em **< 10 ms por cluster** (grafo esparso k=7).
- ZGC recomendado para pausas < 10 ms sob carga.
- Com otimizações: **2 instâncias** (vs 6 anterior) atendem 1000 veículos.

> Análise completa de performance, memória, GC e gargalos: ver **[doc 04B](./04B-Analise-Performance-Otimizacao.md)**.

## Checklist de readiness

- [ ] Throttle de recálculo ativo (30 s / 2 por min)
- [ ] Circuit breaker no routing engine
- [ ] Fallback ETA degradado funcional
- [ ] Dead-letter queue para eventos inválidos
- [ ] Testes de carga com 1000 veículos simulados
- [ ] Particionamento temporal de `live_position`
- [ ] Monitoramento de consumer lag por partição
- [ ] Alertas de CPU/memória por serviço
