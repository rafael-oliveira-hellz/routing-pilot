# Motor de Roteamento e ETA em Tempo Real

> **Escala-alvo**: 1000+ veiculos simultaneos, cada um com 1000+ rotas/pontos.
> **Stack**: Java 25 (LTS) + Spring Boot 4.1.0-SNAPSHOT + NATS JetStream + PostgreSQL/PostGIS + Redis

---

## Mapa de documentacao (ordem de implementacao)

### Sprint 1 - Fundacao e dominio
| # | Documento | Conteudo |
|---|-----------|----------|
| 01 | [Visao Geral e Arquitetura Event-Driven](./01-Visao-Geral-Event-Driven.md) | Topologia, principios, fluxo macro |
| 02 | [Modelo de Dominio e Bounded Contexts](./02-Modelo-Dominio-Bounded-Contexts.md) | Aggregates, entidades, value objects |

### Sprint 2 - Planejamento de rota
| # | Documento | Conteudo |
|---|-----------|----------|
| 03 | [Contexto RoutePlanning](./03-Contexto-RoutePlanning.md) | Request, pontos, paradas, constraints |

### Sprint 3 - Motor de otimizacao
| # | Documento | Conteudo |
|---|-----------|----------|
| 04 | [Contexto OptimizationEngine](./04-Contexto-OptimizationEngine.md) | Pipeline, Christofides, 2-opt, VRP, ForkJoinPool, rede viária (OSM + GraphHopper) |
| 04A | [Codigo Algoritmos de Otimizacao](./04A-Codigo-Algoritmos-Otimizacao.md) | Codigo completo refatorado |
| 04B | [Análise de Performance e Otimização](./04B-Analise-Performance-Otimizacao.md) | Complexidade, memória, GC, gargalos, modelo matemático, 1000 veículos |
| 04C | [Base Geográfica PostGIS + OSM](./04C-Base-Geografica-PostGIS.md) | Import .pbf, schema, osm2pgsql, diffs, GitHub Actions, queries de enriquecimento |

### Sprint 4 - Ingestao GPS, tracking e ETA
| # | Documento | Conteudo |
|---|-----------|----------|
| 05 | [Ingestao GPS e Resiliencia](./05-Ingestao-GPS-Resiliencia.md) | API batch, offline, dedup, rate limit |
| 06 | [Contexto ExecutionMonitoring](./06-Contexto-ExecutionMonitoring.md) | Tracking, posicao, estado, inatividade, auditoria |
| 07 | [ETA Engine Otimizado](./07-ETA-Engine-Otimizado.md) | Algoritmo incremental, EWMA, confianca |

### Sprint 5 - Regras de negocio e policies
| # | Documento | Conteudo |
|---|-----------|----------|
| 08 | [Use Cases e Policies](./08-UseCases-Policies.md) | Desvio, throttle, trafego, chegada, incidentes |

### Sprint 6 - Incidentes crowdsourced
| # | Documento | Conteudo |
|---|-----------|----------|
| 09 | [Incidentes Crowdsourced](./09-Incidentes-Crowdsourced.md) | Blitz, acidente, transito, pista molhada, quorum |

### Sprint 7 - Escala 1000x1000 + DLQ + resiliencia
| # | Documento | Conteudo |
|---|-----------|----------|
| 10 | [Auditoria e Tratamento de Erros](./10-Auditoria-Observabilidade-Erros.md) | Audit trail, DLQ, structured errors, retry |
| 12 | [Escalabilidade e Performance](./12-Escalabilidade-Performance.md) | Particionamento, hot/cold path, capacity planning |

### Sprint 8 - Observabilidade e operacao
| # | Documento | Conteudo |
|---|-----------|----------|
| 13 | [Operacao, SLOs e Runbooks](./13-Operacao-SLO-Runbooks.md) | Metricas, alertas, runbooks |

### Referencia (transversal)
| # | Documento | Conteudo |
|---|-----------|----------|
| 11 | [Contratos de Eventos e Estado](./11-Contratos-Eventos-Estado.md) | JSON Schema, streams NATS, maquina de estados |
| 14 | [Checklist de Implementacao por Sprint](./14-Checklist-Sprints.md) | Sprints 1-8, criterios de aceite |
| 15 | [Skeleton Java 25 + Spring Boot 4.1](./15-Skeleton-Java.md) | Estrutura de pacotes, classes, configs |

---

## Principios arquiteturais

- **Event-driven first**: NATS JetStream como backbone (open-source, baixo custo).
- **Stateless compute**: servicos escalam horizontalmente.
- **State externalizado**: PostgreSQL/PostGIS + Redis.
- **Hot path otimizado**: 90-95% dos eventos apenas atualizam ETA.
- **Recalculo controlado**: throttle + debounce + politica de impacto.
- **Incidentes crowdsourced**: usuarios reportam eventos reais que influenciam rota/ETA.
- **Auditoria ponta a ponta**: cada decisao rastreavel por traceId ate o payload original.

## Escala: 1000 veiculos x 1000 rotas

- Cada veiculo pode gerenciar ate 1000+ waypoints por rota.
- Clusterizacao + solve paralelo para rotas grandes.
- Particionamento por `vehicleId` no broker para consistencia.
- ETA incremental por veiculo (sem reprocessar rota inteira).
- Incidentes espacialmente indexados (R-tree) para impacto em O(log n).
- DLQ para eventos com falha, com payload original preservado.

## Artefatos relacionados

- Modelo Excel completo: [`../DDD_Route_Architecture_Full_Model.xlsx`](../DDD_Route_Architecture_Full_Model.xlsx)
- Skeleton Java: [`../skeleton/`](../skeleton/)
