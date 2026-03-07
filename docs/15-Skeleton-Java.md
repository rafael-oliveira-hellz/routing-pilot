# 15 - Skeleton Java 25 + Spring Boot 4.1.0-SNAPSHOT

## Stack

- **Java 25** (LTS, GA set/2025)
- **Spring Boot 4.1.0-SNAPSHOT** (milestone M2+ disponível)
- **NATS JetStream** (broker open-source, baixo custo)
- **PostgreSQL 16+ / PostGIS** (geoespacial) + **Hibernate Spatial** (JTS Geometry types)
- **Redis** (estado quente)
- **JGraphT 1.5.2** (Edmonds Blossom V)
- **GraphHopper 9.1** (roteamento embarcado, CH, Matrix + Routing API)
- **AWS SDK v2** (S3 para grafo pré-processado em prod)
- **Flyway** (migrations, incluindo schema `geo` para dados OSM)
- **Resilience4j** (circuit breaker)
- **Micrometer + Prometheus** (métricas)

## Estrutura de pacotes

Caminho base no repositório: **`skeleton/src/main/java/com/example/routing/`** (pacote Java `com.example.routing`).

```text
skeleton/
├── pom.xml
└── src/main/
    ├── java/com/example/routing/
    │   ├── RoutingEngineApplication.java
    │   │
    │   ├── domain/
    │   │   ├── enums/
    │   │   │   ├── Decision.java
    │   │   │   ├── ImproveFor.java
    │   │   │   ├── IncidentSeverity.java
    │   │   │   ├── IncidentType.java
    │   │   │   ├── OptimizationStatus.java
    │   │   │   ├── OptimizationStrategy.java
    │   │   │   ├── ProcessingErrorCode.java
    │   │   │   ├── RecalcReason.java
    │   │   │   ├── RouteType.java
    │   │   │   ├── RouteTypeVariant.java
    │   │   │   ├── Traffic.java
    │   │   │   ├── TunnelCategory.java
    │   │   │   ├── Vehicle.java
    │   │   │   ├── VehicleStatus.java
    │   │   │   └── VoteType.java
    │   │   ├── model/
    │   │   │   ├── ActiveIncident.java
    │   │   │   ├── AlgorithmConfig.java
    │   │   │   ├── EtaState.java
    │   │   │   ├── GeoPoint.java
    │   │   │   ├── PolicyDecision.java
    │   │   │   ├── Polyline.java
    │   │   │   ├── ProcessingError.java
    │   │   │   ├── RegionTile.java
    │   │   │   ├── RouteProgress.java
    │   │   │   ├── SegmentMetrics.java
    │   │   │   ├── TimeWindow.java
    │   │   │   └── VehicleState.java
    │   │   ├── entity/
    │   │   │   ├── ExecutionEvent.java
    │   │   │   └── LivePosition.java
    │   │   ├── event/
    │   │   │   ├── DestinationReachedEvent.java
    │   │   │   ├── EtaDegradedEvent.java
    │   │   │   ├── EtaUpdatedEvent.java
    │   │   │   ├── IncidentActivatedEvent.java
    │   │   │   ├── IncidentExpiredEvent.java
    │   │   │   ├── IncidentReportedEvent.java
    │   │   │   ├── LocationUpdatedEvent.java
    │   │   │   ├── OptimizationFailedEvent.java
    │   │   │   ├── RecalculateRouteRequested.java
    │   │   │   ├── RouteChangedEvent.java
    │   │   │   ├── RouteOptimizationRequested.java
    │   │   │   ├── RouteRecalculatedEvent.java
    │   │   │   ├── SegmentIncidentDisplayEvent.java
    │   │   │   ├── SignalLostEvent.java
    │   │   │   └── SignalRecoveredEvent.java
    │   │   ├── exception/
    │   │   │   ├── CacheException.java
    │   │   │   ├── ConcurrencyLimitExceededException.java
    │   │   │   ├── DomainException.java
    │   │   │   ├── EventProcessingException.java
    │   │   │   ├── GraphHopperException.java
    │   │   │   ├── IncidentException.java
    │   │   │   ├── OptimizationException.java
    │   │   │   ├── RateLimitExceededException.java
    │   │   │   ├── ResourceNotFoundException.java
    │   │   │   ├── RoutingException.java
    │   │   │   └── VehicleStateException.java
    │   │   ├── policy/
    │   │   │   ├── DestinationArrivalPolicy.java
    │   │   │   ├── EtaUpdatePolicy.java
    │   │   │   ├── IncidentEtaAdjuster.java
    │   │   │   ├── IncidentImpactPolicy.java
    │   │   │   ├── RecalculationThrottlePolicy.java
    │   │   │   └── RouteDeviationPolicy.java
    │   │   └── validator/
    │   │       └── RouteRequestValidator.java
    │   │
    │   ├── application/
    │   │   ├── port/
    │   │   │   ├── in/
    │   │   │   │   ├── CreateRouteRequestPort.java
    │   │   │   │   ├── ProcessLocationUpdatePort.java
    │   │   │   │   └── ReportIncidentPort.java
    │   │   │   └── out/
    │   │   │       ├── DeadLetterPort.java
    │   │   │       ├── EventPublisher.java
    │   │   │       ├── ExecutionEventStore.java
    │   │   │       ├── IncidentQueryPort.java
    │   │   │       ├── LivePositionStore.java
    │   │   │       ├── LocationDedupPort.java
    │   │   │       ├── RateLimitPort.java
    │   │   │       └── VehicleStateStore.java
    │   │   └── usecase/
    │   │       ├── CreateRouteRequestUseCase.java
    │   │       ├── ExpireIncidentsUseCase.java
    │   │       ├── FinalizeRouteUseCase.java
    │   │       ├── InactivityDetectorJob.java
    │   │       ├── ProcessIncidentReportUseCase.java
    │   │       ├── ProcessIncidentVoteUseCase.java
    │   │       ├── ProcessLocationUpdateUseCase.java
    │   │       └── RecalculateRouteUseCase.java
    │   │
    │   ├── engine/
    │   │   ├── eta/
    │   │   │   └── EtaEngine.java
    │   │   └── optimization/
    │   │       ├── model/
    │   │       │   ├── Coordinate.java
    │   │       │   ├── CoordinatesWithDistance.java
    │   │       │   └── WaypointSequence.java
    │   │       ├── mst/
    │   │       │   ├── Graph.java
    │   │       │   ├── KruskalSpanningTree.java
    │   │       │   ├── NodeParents.java
    │   │       │   ├── ResultDTO.java
    │   │       │   └── SpanningTreeMaker.java
    │   │       ├── tsp/
    │   │       │   ├── ApproximateRouteCreator.java
    │   │       │   ├── ApproximationAlgorithm.java
    │   │       │   ├── ChristofidesRefactored.java
    │   │       │   ├── ChristofidesVertex.java
    │   │       │   ├── GreedyMatching.java
    │   │       │   ├── TwoOptOptimizer.java
    │   │       │   └── TwoThirdsApproximationRouteMaker.java
    │   │       ├── matrix/
    │   │       │   ├── DistanceCalculator.java
    │   │       │   ├── DistanceMatrixCache.java
    │   │       │   └── ParallelDistanceMatrix.java
    │   │       ├── vrp/
    │   │       │   ├── RouteAssigner.java
    │   │       │   └── VRPClusterer.java
    │   │       ├── routing/
    │   │       │   └── GraphHopperSegmentRouter.java
    │   │       └── orchestration/
    │   │           ├── HybridRouteStrategy.java
    │   │           └── ParallelRouteEngine.java
    │   │
    │   ├── infrastructure/
    │   │   ├── config/
    │   │   │   ├── AwsConfig.java
    │   │   │   ├── GraphHopperConfig.java
    │   │   │   ├── NatsConfig.java
    │   │   │   ├── RateLimitConfig.java
    │   │   │   └── WebSocketConfig.java
    │   │   ├── nats/
    │   │   │   ├── NatsDeadLetterPublisher.java
    │   │   │   ├── NatsEventPublisher.java
    │   │   │   ├── NatsIncidentListener.java
    │   │   │   ├── NatsLocationListener.java
    │   │   │   └── NatsRecalcListener.java
    │   │   ├── persistence/
    │   │   │   ├── entity/
    │   │   │   │   ├── DeadLetterEventJpaEntity.java
    │   │   │   │   ├── ExecutionEventJpaEntity.java
    │   │   │   │   ├── IncidentImpactJpaEntity.java
    │   │   │   │   ├── IncidentJpaEntity.java
    │   │   │   │   ├── IncidentVoteJpaEntity.java
    │   │   │   │   ├── LivePositionJpaEntity.java
    │   │   │   │   ├── OptimizationRunJpaEntity.java
    │   │   │   │   ├── OsmAddressEntity.java
    │   │   │   │   ├── OsmBoundaryEntity.java
    │   │   │   │   ├── OsmBuildingEntity.java
    │   │   │   │   ├── OsmPoiEntity.java
    │   │   │   │   ├── OsmRoadEntity.java
    │   │   │   │   ├── RouteConstraintJpaEntity.java
    │   │   │   │   ├── RouteExecutionJpaEntity.java
    │   │   │   │   ├── RouteOptimizationJpaEntity.java
    │   │   │   │   ├── RoutePointJpaEntity.java
    │   │   │   │   ├── RouteRequestJpaEntity.java
    │   │   │   │   ├── RouteResultJpaEntity.java
    │   │   │   │   ├── RouteSegmentJpaEntity.java
    │   │   │   │   ├── RouteStopJpaEntity.java
    │   │   │   │   ├── RouteWaypointJpaEntity.java
    │   │   │   │   └── ...
    │   │   │   ├── adapter/
    │   │   │   │   ├── ExecutionEventStoreAdapter.java
    │   │   │   │   └── LivePositionStoreAdapter.java
    │   │   │   ├── mapper/
    │   │   │   │   ├── ExecutionEventMapper.java
    │   │   │   │   └── LivePositionMapper.java
    │   │   │   └── repository/
    │   │   │       ├── DeadLetterEventRepository.java
    │   │   │       ├── ExecutionEventRepository.java
    │   │   │       ├── IncidentRepository.java
    │   │   │       ├── IncidentVoteRepository.java
    │   │   │       ├── LivePositionRepository.java
    │   │   │       ├── OsmAddressRepository.java
    │   │   │       ├── OsmBoundaryRepository.java
    │   │   │       ├── OsmPoiRepository.java
    │   │   │       ├── OsmRoadRepository.java
    │   │   │       ├── RouteExecutionRepository.java
    │   │   │       ├── RouteOptimizationRepository.java
    │   │   │       ├── RouteRequestRepository.java
    │   │   │       ├── RouteResultRepository.java
    │   │   │       ├── RouteSegmentRepository.java
    │   │   │       ├── RouteStopRepository.java
    │   │   │       ├── RouteWaypointRepository.java
    │   │   │       └── ...
    │   │   └── redis/
    │   │       ├── RedisIncidentCache.java
    │   │       ├── RedisLocationDedup.java
    │   │       └── RedisVehicleStateStore.java
    │   │
    │   └── api/
    │       ├── rest/
    │       │   ├── ErrorResponse.java
    │       │   ├── GlobalExceptionHandler.java
    │       │   ├── IncidentController.java
    │       │   ├── LocationIngestionController.java
    │       │   └── RouteRequestController.java
    │       └── websocket/
    │           ├── EtaWebSocketHandler.java
    │           └── IncidentAlertHandler.java
    │
    └── resources/
        ├── application.yml
        └── db/migration/
            ├── V001__create_incident_tables.sql
            ├── V002__create_route_tables.sql
            ├── V003__audit_and_dlq.sql
            └── V004__create_osm_geographic_tables.sql
```

## Camadas e responsabilidades

| Camada | Acessa | Não acessa |
|--------|--------|------------|
| `domain` | Nada (pura) | Infra, Spring, IO |
| `application` | `domain`, ports | Infra diretamente |
| `engine` | `domain` | Infra |
| `infrastructure` | `domain`, `application` (implementa ports) | - |
| `api` | `application` (via ports) | `domain` internals |

## Convenções

- **Records** para Value Objects e eventos (imutáveis).
- **Policies** são `@Component` stateless, injetados por Spring.
- **Use Cases** implementam ports `in` e dependem de ports `out`.
- **Infra** implementa ports `out` (Redis, NATS, JPA).
- **Configuração** via `application.yml` com valores padrão sensatos.
- **Flyway** para DDL versionado.
- **JetStream** com streams criados no startup (`NatsConfig`).

## Modo local vs AWS

`routing.graphhopper.local` controla o comportamento no startup:

| Variável | Local (dev) | AWS (prod) |
|----------|-------------|------------|
| `GRAPHHOPPER_LOCAL` | `true` (default) | `false` |
| Fonte do grafo | `.pbf` em `data/` (build na primeira execução, cache em `data/graph-cache/`) | Download do S3 (`s3://routing-data/graphhopper/brazil-latest/`) |
| Credenciais AWS | Opcional (só se precisar de S3) via env vars | IAM Role (DefaultCredentialsProvider) |
| Banco | PostgreSQL local (`localhost:5432`) | RDS PostgreSQL (via env/Parameter Store) |

**Desenvolvimento local**: baixar o `.pbf` do Geofabrik, colocar em `skeleton/data/brazil-latest.osm.pbf` e rodar. Na primeira execução o GraphHopper gera o grafo CH (~3-10 min). Nas seguintes, carrega do cache (~10 s).

## Para completar nas próximas sprints

- Sprint 3: `engine/optimization/` já subdividido em `model/`, `mst/`, `tsp/`, `matrix/`, `vrp/`, `routing/`, `orchestration/` (Christofides, Kruskal, TwoOpt, VRPClusterer)
- Sprint 4: Mais entidades JPA para route_*, repositórios correspondentes
- Sprint 5: R-tree para projeção de corredor
- Sprint 7: ForkJoinPool no engine, HybridRouteStrategy
