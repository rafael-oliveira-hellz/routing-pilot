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

```text
skeleton/
├── pom.xml
└── src/main/
    ├── java/com/example/routing/
    │   ├── RoutingEngineApplication.java
    │   │
    │   ├── domain/
    │   │   ├── enums/
    │   │   │   ├── ImproveFor.java
    │   │   │   ├── IncidentSeverity.java
    │   │   │   ├── IncidentType.java
    │   │   │   ├── RecalcReason.java
    │   │   │   ├── RouteType.java
    │   │   │   ├── RouteTypeVariant.java
    │   │   │   ├── Traffic.java
    │   │   │   ├── TunnelCategory.java
    │   │   │   ├── Vehicle.java
    │   │   │   └── VehicleStatus.java
    │   │   ├── model/
    │   │   │   ├── ActiveIncident.java         (record)
    │   │   │   ├── EtaState.java               (record)
    │   │   │   ├── GeoPoint.java               (record, validated)
    │   │   │   ├── PolicyDecision.java         (enum)
    │   │   │   ├── RegionTile.java             (record, tile math)
    │   │   │   ├── RouteProgress.java          (record)
    │   │   │   └── VehicleState.java           (record, immutable)
    │   │   ├── event/
    │   │   │   ├── DestinationReachedEvent.java
    │   │   │   ├── EtaUpdatedEvent.java
    │   │   │   ├── IncidentActivatedEvent.java
    │   │   │   ├── IncidentReportedEvent.java
    │   │   │   ├── LocationUpdatedEvent.java
    │   │   │   └── RecalculateRouteRequested.java
    │   │   └── policy/
    │   │       ├── DestinationArrivalPolicy.java
    │   │       ├── IncidentImpactPolicy.java
    │   │       ├── RecalculationThrottlePolicy.java
    │   │       └── RouteDeviationPolicy.java
    │   │
    │   ├── application/
    │   │   ├── port/
    │   │   │   ├── in/
    │   │   │   │   ├── ProcessLocationUpdatePort.java
    │   │   │   │   └── ReportIncidentPort.java
    │   │   │   └── out/
    │   │   │       ├── EventPublisher.java
    │   │   │       ├── IncidentQueryPort.java
    │   │   │       └── VehicleStateStore.java
    │   │   └── usecase/
    │   │       ├── ProcessIncidentReportUseCase.java
    │   │       └── ProcessLocationUpdateUseCase.java
    │   │
    │   ├── engine/
    │   │   ├── eta/
    │   │   │   └── EtaEngine.java              (EWMA, confidence, clamping; observedSpeedMps = LocationUpdatedEvent.payload.speedMps)
    │   │   └── optimization/
    │   │       ├── ParallelDistanceMatrix.java  (GH CH paralelo + k-nearest + fallback Haversine)
    │   │       ├── GraphHopperSegmentRouter.java (rota por par → geometry, dist, duration)
    │   │       └── (Christofides, Kruskal, TwoOpt - Sprint 3)
    │   │
    │   ├── infrastructure/
    │   │   ├── config/
    │   │   │   ├── NatsConfig.java             (stream creation)
    │   │   │   ├── GraphHopperConfig.java      (local .pbf vs S3 graph, CH profile)
    │   │   │   ├── AwsConfig.java              (S3Client, credentials local vs IAM)
    │   │   │   └── WebSocketConfig.java
    │   │   ├── nats/
    │   │   │   ├── NatsEventPublisher.java      (implements EventPublisher)
    │   │   │   └── NatsLocationListener.java    (JetStream push consumer)
    │   │   ├── persistence/
    │   │   │   ├── entity/
    │   │   │   │   ├── IncidentJpaEntity.java
    │   │   │   │   ├── OsmRoadEntity.java       (geo.osm_roads, LineString)
    │   │   │   │   └── OsmPoiEntity.java        (geo.osm_pois, Point)
    │   │   │   └── repository/
    │   │   │       ├── IncidentRepository.java
    │   │   │       ├── OsmRoadRepository.java   (PostGIS spatial queries)
    │   │   │       └── OsmPoiRepository.java    (nearby POIs by amenity/radius)
    │   │   └── redis/
    │   │       └── RedisVehicleStateStore.java   (implements VehicleStateStore)
    │   │
    │   └── api/
    │       ├── rest/
    │       │   └── IncidentController.java
    │       └── websocket/
    │           └── EtaWebSocketHandler.java
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

- Sprint 3: `engine/optimization/` (Christofides, Kruskal, TwoOpt, VRPClusterer)
- Sprint 4: Mais entidades JPA para route_*, repositórios correspondentes
- Sprint 5: R-tree para projeção de corredor
- Sprint 7: ForkJoinPool no engine, HybridRouteStrategy
