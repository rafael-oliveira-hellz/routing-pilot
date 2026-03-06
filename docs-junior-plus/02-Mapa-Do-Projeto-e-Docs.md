# 02 - Mapa do projeto e docs

Referência rápida: **onde está cada tema** na documentação e no código.

---

## Estrutura de pastas do projeto

```
014-routing/
├── docs/                    # Documentação técnica principal (Sprints, contratos, algoritmos)
├── docs-junior-plus/        # Este guia (júnior → júnior+)
├── pilot/                   # Código do piloto (Docker, app, etc.)
│   ├── docker/              # PostgreSQL, init scripts
│   ├── compose.yaml         # Subir PG, Redis, NATS, app
│   └── ...
├── skeleton/                # Estrutura Java (pacotes, classes) — se existir
└── (outros: DDD_Route_Architecture_Full_Model.xlsx, etc.)
```

O código principal do motor de roteamento pode estar em `pilot/` ou em outra pasta de módulos; o Checklist em `docs/14-Checklist-Sprints.md` e o `docs/15-Skeleton-Java.md` referenciam pacotes como `com.example.routing`.

---

## Mapa da documentação (`docs/`)

| Tema | Documento | O que você encontra |
|------|-----------|----------------------|
| Visão geral e evento | [01 - Visão Geral Event-Driven](../docs/01-Visao-Geral-Event-Driven.md) | Fluxo macro, topologia de serviços, NATS, latências |
| Domínio e contextos | [02 - Modelo de Domínio](../docs/02-Modelo-Dominio-Bounded-Contexts.md) | Bounded contexts, aggregates, value objects, invariantes |
| Planejamento de rota | [03 - RoutePlanning](../docs/03-Contexto-RoutePlanning.md) | RouteRequest, pontos, paradas, validações, API |
| Motor de otimização | [04 - OptimizationEngine](../docs/04-Contexto-OptimizationEngine.md) | Christofides, 2-opt, VRP, ForkJoin, GraphHopper |
| Código dos algoritmos | [04A - Código Algoritmos](../docs/04A-Codigo-Algoritmos-Otimizacao.md) | Implementação refatorada dos algoritmos |
| Performance do engine | [04B - Análise Performance](../docs/04B-Analise-Performance-Otimizacao.md) | Complexidade, memória, GC, 1000 veículos |
| Base geográfica | [04C - PostGIS + OSM](../docs/04C-Base-Geografica-PostGIS.md) | Import OSM, schema geo, osm2pgsql |
| Ingestão GPS | [05 - Ingestão GPS](../docs/05-Ingestao-GPS-Resiliencia.md) | API batch, offline, dedup, rate limit |
| Monitoramento da execução | [06 - ExecutionMonitoring](../docs/06-Contexto-ExecutionMonitoring.md) | Tracking, posição, estado, inatividade |
| ETA | [07 - ETA Engine](../docs/07-ETA-Engine-Otimizado.md) | ETA incremental; velocidade do veículo (speedMps) → EWMA; confiança, incidentes |
| Regras de negócio | [08 - Use Cases e Policies](../docs/08-UseCases-Policies.md) | Desvio, throttle, tráfego, chegada |
| Incidentes | [09 - Incidentes Crowdsourced](../docs/09-Incidentes-Crowdsourced.md) | Report, votos, quorum, TTL, impacto no ETA |
| Auditoria e erros | [10 - Auditoria e Erros](../docs/10-Auditoria-Observabilidade-Erros.md) | Audit trail, DLQ, retry |
| Contratos e estado | [11 - Contratos e Estado](../docs/11-Contratos-Eventos-Estado.md) | JSON Schema dos eventos, streams, máquina de estados |
| Escalabilidade | [12 - Escalabilidade](../docs/12-Escalabilidade-Performance.md) | Particionamento, hot/cold, capacity |
| Operação | [13 - SLOs e Runbooks](../docs/13-Operacao-SLO-Runbooks.md) | Métricas, alertas, runbooks |
| Checklist | [14 - Checklist Sprints](../docs/14-Checklist-Sprints.md) | Itens por Sprint, critérios de aceite. **\[E\]** = Especialista entrega pronto; **\[M\]** = Mentorado implementa (suas tarefas de aprendizado). |
| Skeleton Java | [15 - Skeleton Java](../docs/15-Skeleton-Java.md) | Pacotes, classes, config, Flyway |

---

## Onde está o quê no código (referência skeleton)

Com base no `docs/15-Skeleton-Java.md` e no Checklist:

| Responsabilidade | Camada | Exemplos (nomes típicos) |
|------------------|--------|---------------------------|
| Value objects, eventos, policies | `domain/` | `GeoPoint`, `EtaState`, `LocationUpdatedEvent`, `RouteDeviationPolicy` |
| Casos de uso, portas | `application/` | `ProcessLocationUpdateUseCase`, `CreateRouteRequestUseCase`, `EventPublisher`, `VehicleStateStore` |
| Algoritmos (ETA, otimização) | `engine/` | `EtaEngine`, `ParallelRouteEngine`, `GraphHopperSegmentRouter` |
| NATS, Redis, JPA, config | `infrastructure/` | `NatsConfig`, `NatsLocationListener`, `RedisVehicleStateStore`, repositórios JPA |
| REST, WebSocket | `api/` | `RouteRequestController`, `LocationIngestionController`, `EtaWebSocketHandler` |
| Migrations | `resources/db/migration/` | `V001__...sql` a `V004__...sql` |

---

## Ordem de leitura recomendada (por Sprint)

1. **Sprint 1** (fundação): docs 01, 02, 15, 04C + Checklist Sprint 1.  
2. **Sprint 2** (rotas): doc 03 + Checklist Sprint 2.  
3. **Sprint 3** (otimização): docs 04, 04A, 04B + Checklist Sprint 3.  
4. **Sprint 4** (GPS + ETA): docs 05, 06, 07 + Checklist Sprint 4.  
5. **Sprint 5** (policies): doc 08 + Checklist Sprint 5.  
6. **Sprint 6** (incidentes): doc 09 + Checklist Sprint 6.  
7. **Sprint 7** (escala + DLQ): docs 10, 12, 04B + Checklist Sprint 7.  
8. **Sprint 8** (observabilidade): doc 13 + Checklist Sprint 8.  

O doc **11** (contratos e estado) é transversal; vale ler cedo e usar como referência.

---

## Dica

Mantenha este mapa aberto quando for implementar um item do Checklist: assim você sabe qual doc abrir e em qual camada do código procurar.
