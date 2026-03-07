# 14 - Checklist de Implementacao por Sprint

## Responsabilidade: Especialista vs Mentorado

Nenhum código de negócio está implementado ainda. O checklist indica **quem faz o quê**: o **Especialista** prepara só o **esqueleto** do projeto; o **Mentorado** implementa o **código** (domínio, use cases, APIs, engine, etc.) para aprender do zero ao pleno.

| Sigla | Responsável | Significado |
|-------|-------------|-------------|
| **[E]** | **Especialista** | Você entrega: (1) **esqueleto** (projeto, Docker, config, pacotes, NatsConfig mínimo); (2) **código complexo** (ex.: algoritmos do motor de otimização — TSP, Christofides, 2-opt, GraphHopper, cache de matriz). O mentorado **não** implementa esses algoritmos; a tarefa dele é **entender** (ver [M] “lição de casa”). |
| **[M]** | **Mentorado** | **Implementa** em código: domínio, entidades, use cases, APIs, consumers, policies, testes, etc. Para itens [E] que são código complexo (ex.: engine de otimização), o mentorado faz **lição de casa**: estudar estrutura, estruturas de dados e o **por quê** de cada algoritmo (docs 04, 04A, 04B; desenhar pipeline; explicar ao mentor). Guia: `docs-junior-plus/` e `docs-junior-plus/pleno/`. |

**Resumo:** [E] = esqueleto mínimo + **código complexo** (ex.: conjunto de algoritmos do motor de otimização — Christofides, 2-opt, GraphHopper, etc.): você implementa; o mentorado **não** implementa essa parte. [M] = implementação pelo mentorado **ou**, quando o item for [E] complexo, **lição de casa**: entender o que está feito (estrutura, estruturas de dados, por quê de cada algoritmo) — estudar docs e código, desenhar pipeline, explicar para o mentor.

---

## Visao geral

| Sprint | Foco | Docs relacionados | Duracao |
|--------|------|-------------------|---------|
| Sprint 1 | Fundacao: projeto, dominio, infra base + base geográfica OSM | 01, 02, 15, 04C | 2 semanas |
| Sprint 2 | RoutePlanning: API + persistencia | 03 | 2 semanas |
| Sprint 3 | OptimizationEngine: Christofides + 2-opt + GraphHopper | 04, 04A, 04B | 2 semanas |
| Sprint 4 | Ingestao GPS + ExecutionMonitoring + ETA + Auditoria | 05, 06, 07 | 2 semanas |
| Sprint 5 | Policies e regras de negocio | 08 | 2 semanas |
| Sprint 6 | Incidentes crowdsourced | 09 | 2 semanas |
| Sprint 7 | Escala 1000x1000 + DLQ + Inatividade | 10, 12, 04B | 2 semanas |
| Sprint 8 | Observabilidade, SLO, hardening | 13 | 2 semanas |
| Ref | Contratos de eventos, checklist, skeleton | 11, 14, 15 | - |

---

## Sprint 1 - Fundacao (docs 01, 02, 15, 04C)

**Esqueleto (só você faz):**

- [ ] [E] Criar projeto Spring Boot 4.1.0-SNAPSHOT + Java 25 (`pom.xml` com dependências base: Spring Boot, Flyway, PostgreSQL, Redis, NATS; sem GraphHopper/JGraphT ainda)
- [ ] [E] Docker Compose (`compose.yaml`: PostgreSQL/PostGIS, Redis, NATS) + `.gitignore`
- [ ] [E] Habilitar extensões PostGIS no init do Postgres (`docker/postgres/init.sql`: `postgis`, `pg_trgm`)
- [ ] [E] Estrutura de pacotes vazia por bounded context: `domain/` (enums, model, event, policy), `application/` (port/in, port/out, usecase), `engine/` (eta, optimization), `infrastructure/` (config, nats, persistence, redis), `api/` (rest, websocket). No skeleton: `skeleton/src/main/java/com/example/routing/`.
- [ ] [E] `application.yml` com placeholders/conexões para PostgreSQL, Redis, NATS (e profile local)
- [ ] [E] Classe principal `RoutingEngineApplication` + Flyway habilitado; pasta `src/main/resources/db/migration/` (no skeleton: `skeleton/src/main/resources/db/migration/`; pode ter um `V000__placeholder.sql` vazio ou um V001 mínimo para o app subir)
- [ ] [E] `NatsConfig.java` mínimo: criar streams/subjects no JetStream ao subir (conforme doc 11), para o app não falhar ao conectar

**Mentorado implementa (código que agrega):**

- [ ] [M] Value objects: `GeoPoint`, `RegionTile`, `EtaState`, `RouteProgress`, `VehicleState`, `TimeWindow`, `SegmentMetrics`, `AlgorithmConfig`, `Polyline` (doc 02)
- [ ] [M] Enums: `IncidentType`, `IncidentSeverity`, `VehicleStatus`, `RouteType`, `Traffic`, `Vehicle`, `TunnelCategory`, `OptimizationStrategy`, `OptimizationStatus`, `VoteType`, `Decision`, `RecalcReason`, `ImproveFor`, `ProcessingErrorCode`
- [ ] [M] `DomainException` e hierarquia de exceções (ex.: `RoutingException` abstrata)
- [ ] [M] Flyway migrations V001–V004: tabelas de incident, route_*, execution_*, dead_letter, schema `geo` + tabelas OSM (doc 04C)
- [ ] [M] Entidades JPA Geo: `OsmRoadEntity`, `OsmPoiEntity`, `OsmAddressEntity`, `OsmBoundaryEntity`, `OsmBuildingEntity` + repositórios
- [ ] [E] Configs complexas: `AwsConfig.java` (S3Client, env vs DefaultCredentialsProvider), `GraphHopperConfig.java` (carregar grafo: .pbf local vs S3, perfil CH). Júnior normalmente não domina SDK AWS v2 nem API do GraphHopper; o especialista entrega ou faz em par.
- [ ] [M] Adicionar no `pom.xml` as dependências GraphHopper, Hibernate Spatial, AWS SDK v2, JGraphT (versões e artefatos conforme doc 15 ou `skeleton/pom.xml`; júnior segue a lista para não errar versão, ex.: GraphHopper 9.1 no Central, sem `graphhopper-reader-osm` 9.1)
- [ ] [M] CI/CD pipeline básico (build + test); `infra/osm2pgsql/osm2pgsql-flex.lua`; GitHub Actions import OSM; import inicial Brasil (.pbf) para PostGIS

**Auth e CRUD de Usuários (fluxo completo de autenticação):**

- [ ] [M] **Roles:** dois papéis no sistema — `USER` (usuário normal do app) e `ADMIN` (dono/administrador da aplicação). Enum `UserRole` (USER, ADMIN). Na tabela `app_user` incluir coluna `role` (VARCHAR ou ENUM: USER, ADMIN). Cadastro público (POST /users) cria sempre **USER**; o primeiro **ADMIN** (dono da aplicação) é criado via seed/migration ou ferramenta interna — apenas um ADMIN existente (ou seed) pode criar ou promover outro usuário a ADMIN, para evitar escalação de privilégio.
- [ ] [M] Flyway migration **V006** em `pilot/src/main/resources/db/migration/V006__create_auth_user_tables.sql`: enum `user_role_enum` (USER, ADMIN); tabela `app_user` (id UUID, email UNIQUE, password_hash, name, vehicle_id nullable, role NOT NULL DEFAULT 'USER', remember_me_token nullable, remember_me_expires_at nullable, active, created_at, updated_at); tabela `refresh_token` (id, user_id FK app_user, token_hash, expires_at, revoked); tabela `password_reset_token` (id, user_id FK app_user, token_hash, expires_at, used_at nullable). Índices em email, role, user_id e expires_at conforme arquivo.
- [ ] [M] Entidades JPA: `UserJpaEntity` (com campo role), `RefreshTokenJpaEntity`, `PasswordResetTokenJpaEntity` + repositórios
- [ ] [M] **CRUD Users:** `CreateUserUseCase` (cria sempre como USER; admin pode criar outro admin se necessário), `GetUserUseCase`, `UpdateUserUseCase`, `DeleteUserUseCase` (soft delete ou hard). **Autorização por role:**
  - **USER:** só acessa `GET /api/v1/users/me` e `PUT /api/v1/users/{id}` quando id = próprio; não pode listar todos usuários nem deletar outros.
  - **ADMIN:** pode `GET /api/v1/users` (listar todos), `GET /api/v1/users/{id}` (qualquer id), `PUT /api/v1/users/{id}` (qualquer, exceto alterar role de outro admin com cuidado), `DELETE /api/v1/users/{id}` (remover/desativar qualquer usuário, inclusive USER). Admin não pode remover o último admin (ou: apenas o “owner” pode promover/rebaixar outros admins — regra de negócio a definir).
- [ ] [M] API REST: `POST /api/v1/users` (registro público, role = USER); `GET /api/v1/users/me` (Bearer, qualquer role); `GET /api/v1/users` **(admin-only)** listar usuários; `GET /api/v1/users/{id}` (próprio ou admin); `PUT /api/v1/users/{id}` (próprio ou admin, com restrições acima); `DELETE /api/v1/users/{id}` **(admin-only)** remover/desativar usuário. Validações (email único, senha forte, etc.).
- [ ] [M] **Login:** `LoginUseCase` (validar credenciais, gerar access JWT + refresh token, opcionalmente gerar/persistir remember_me_token); `POST /api/v1/auth/login` (body: email, password, rememberMe boolean); resposta: accessToken, refreshToken, expiresIn, user (id, email, name, vehicleId); quando rememberMe=true, enviar cookie/setar remember_me_token com TTL longo (ex.: 30 dias) e retornar no body se necessário para o client guardar
- [ ] [M] **Remember me:** persistir `remember_me_token` (hash) e `remember_me_expires_at` na tabela user; na renovação de sessão (ex.: endpoint que valida remember-me), validar token e expiração e emitir novo par access+refresh
- [ ] [M] **Logout:** `LogoutUseCase` (invalidar refresh token e, se aplicável, remember_me_token); `POST /api/v1/auth/logout` (Bearer obrigatório); revogar o refresh token da sessão atual. **Revogar acesso ao access token (JWT):** o JWT é stateless — após o logout ele continua válido até expirar. Para revogar de fato: (1) **Access token com vida curta** (ex.: 15 min). (2) **Blocklist:** ao fazer logout, adicionar o **jti** do access token atual no Redis com TTL = tempo restante (ex.: `token_revoked:{jti}`); no filtro JWT, consultar blocklist e retornar 401 se existir. Incluir claim **jti** (UUID) em todo access token gerado no login e no refresh.
- [ ] [M] **Revogar todas as outras sessões (caso perda/roubo do celular):** o usuário, a partir de outro dispositivo (ou após recuperar a conta), deve poder encerrar o acesso em **todos os outros** aparelhos. `RevokeAllOtherSessionsUseCase`; `POST /api/v1/auth/revoke-all-other-sessions` (Bearer obrigatório; opcional: body com refreshToken da sessão atual). Comportamento: revogar **todos** os refresh tokens do usuário; gerar um **novo** refresh token para a sessão atual e retorná-lo no body (ex.: `{ "refreshToken": "..." }`) para o app atualizar o storage — assim o dispositivo de onde a requisição foi feita permanece logado e todos os outros (ex.: celular perdido/roubado) deixam de conseguir renovar o access token. Opcional: limpar também `remember_me_token` do user para forçar novo login em "lembrar de mim" em todos os dispositivos. Opcional (revogação imediata nos outros): ao emitir access token, guardar o `jti` no registro do refresh_token; ao revogar as outras sessões, colocar os jtis dos refresh tokens revogados na blocklist no Redis (TTL = tempo restante de cada token) para que os access tokens do celular perdido deixem de valer na hora.
- [ ] [M] **Refresh token:** `RefreshTokenUseCase` (validar refresh token, gerar novo access + opcionalmente novo refresh); `POST /api/v1/auth/refresh` (body: refreshToken); resposta: accessToken, expiresIn; rate limit e rotação de refresh token (invalidar o antigo após uso)
- [ ] [M] **Forgot password:** `RequestPasswordResetUseCase` (gerar token único, persistir em password_reset_token com TTL ex.: 1 h, enviar link/email); `POST /api/v1/auth/forgot-password` (body: email); resposta genérica (não revelar se email existe); `ResetPasswordUseCase` (validar token, atualizar senha, marcar token como usado); `POST /api/v1/auth/reset-password` (body: token, newPassword)
- [ ] [M] **Change password (logado):** `ChangePasswordUseCase` (validar senha atual, atualizar hash); `POST /api/v1/auth/change-password` (Bearer obrigatório; body: currentPassword, newPassword); resposta 204 ou 200
- [ ] [M] JWT: access token com claims sub (userId), email, vehicle_id (se houver), **role** (USER ou ADMIN), **jti** (UUID, para blocklist no logout), exp; vida curta recomendada (ex.: 15 min) para revogação efetiva após logout; assinatura RS256; refresh token opaco ou JWT com exp longo, armazenado em DB/Redis para revogação
- [ ] [M] **Admin-only no backend:** proteger rotas com `@PreAuthorize("hasRole('ADMIN')")` (ou equivalente): listar usuários, deletar usuário, futuras ações de gestão (ex.: ver auditoria global, DLQ, métricas). Resposta 403 para USER que tentar acessar recurso admin.
- [ ] [M] Documentar fluxos de autenticação (ver seção "Documentação — Fluxos de Auth" abaixo) e **matriz User vs Admin** (seção abaixo); garantir que todos os endpoints estejam no OpenAPI

**Criterio de aceite**: `./mvnw verify` passa, conexões PG/Redis/NATS OK, tabelas `geo.*` existentes (populadas se fizer import OSM). CRUD de users funcional; login com remember me; logout invalida sessão; **revogar todas as outras sessões** encerra acesso nos outros dispositivos (ex.: celular perdido/roubado) e mantém o dispositivo atual logado; refresh token renova access; forgot password envia token e reset altera senha; change password (logado) altera senha com validação da atual.

---

## Sprint 2 - RoutePlanning (doc 03)

- [ ] [M] Flyway migration V002: tabelas `route_request`, `route_point`, `route_stop`, `route_constraint`
- [ ] [M] Entidades JPA: `RouteRequestJpaEntity`, `RoutePointJpaEntity`, `RouteStopJpaEntity`, `RouteConstraintJpaEntity`
- [ ] [M] Repositórios: `RouteRequestRepository`, `RouteStopRepository`
- [ ] [M] `RouteRequestValidator` (2 points, max 1000 stops, departure_at >= created_at) — doc 03
- [ ] [M] Event `RouteOptimizationRequested` (record) e port `CreateRouteRequestPort` (in)
- [ ] [M] `CreateRouteRequestUseCase`: validar, persistir, publicar evento via port out
- [ ] [M] Adapter: publicar `RouteOptimizationRequested` no NATS (subject conforme doc 11)
- [ ] [M] API REST: `POST /api/v1/route-requests` (`RouteRequestController` → use case)
- [ ] [M] Testes unitários: `RouteRequestValidator` (válido 2 pts + 10 stops; inválido 1001 stops)
- [ ] [M] Testes de integração: POST com 100 stops → evento publicado no NATS
- [ ] [M] Documentação OpenAPI; opcional: PG ENUMs para `optimization_strategy`

**Criterio de aceite**: Criar request com 100 stops via API, evento publicado no NATS.

---

## Sprint 3 - OptimizationEngine (docs 04, 04A, 04B)

Algoritmos aqui são **complexos** (conjunto otimizado: TSP, MST, matching, 2-opt, GraphHopper). Você [E] implementa o motor; o mentorado [M] integra (use case, listener, entidades) e tem **lição de casa** para entender o que está feito.

**Especialista implementa (motor de otimização):**

- [ ] [E] Modelos internos: `Coordinate`, `CoordinatesWithDistance`, `WaypointSequence`, `ResultDTO`, `ChristofidesVertex`, `NodeParents`, etc.
- [ ] [E] `DistanceCalculator` (Haversine + round + batch); `Graph` (grafo completo + Union-Find)
- [ ] [E] `KruskalSpanningTree` (MST); interfaces `SpanningTreeMaker`, `ApproximationAlgorithm`, `ApproximateRouteCreator`
- [ ] [E] `ChristofidesRefactored` (Edmonds Blossom V via JGraphT); fallback `GreedyMatching` (O(n²))
- [ ] [E] `TwoOptOptimizer` (first-improvement); warm-start com `previousRoute`
- [ ] [E] `VRPClusterer` (K-means), `RouteAssigner`, `TwoThirdsApproximationRouteMaker` (orquestrador)
- [ ] [E] `ParallelRouteEngine` (ForkJoinPool + RecursiveTask), `HybridRouteStrategy` (cluster + parallelStream), `Semaphore` bounded concurrency
- [ ] [E] `ParallelDistanceMatrix` (GraphHopper CH paralelo + k-nearest + fallback Haversine); `GraphHopperSegmentRouter` (rota por par, paralelo)
- [ ] [E] `DistanceMatrixCache` (L1 ConcurrentHashMap + L2 Redis + L3 depot)

**Mentorado implementa (integração + testes):**

- [ ] [M] Entidades JPA: `RouteOptimizationJpaEntity`, `RouteResultJpaEntity`, `RouteSegmentJpaEntity`, `RouteWaypointJpaEntity`, `OptimizationRunJpaEntity` + repositórios
- [ ] [M] Events: `RouteRecalculatedEvent`, `OptimizationFailedEvent`; `application.yml` config graphhopper (local/S3), k-nearest
- [ ] [M] `RecalculateRouteUseCase`: chamar o engine (você entrega), persistir resultado, `@CircuitBreaker` + Resilience4j, métrica `optimization.duration`
- [ ] [M] `NatsRecalcListener` consumer `route.recalc.requested.>` → use case
- [ ] [M] Testes que **usam** o engine (ex.: integração com 100 pontos); benchmark 100/300/500/1000 pts (opcional); pipeline S3 / ZGC (opcional)

**Lição de casa (mentorado) — entender o que está feito:**

- [ ] [M] Ler docs 04, 04A, 04B: papel de cada algoritmo (Kruskal, Christofides, 2-opt, VRP cluster, GraphHopper), por quê da ordem do pipeline, complexidade e trade-offs
- [ ] [M] No código [E]: identificar estruturas de dados (grafo, MST, matching, waypoint sequence); desenhar o fluxo entrada → clusterização → Christofides por cluster → 2-opt → segmentos GraphHopper → saída
- [ ] [M] Explicar para o mentor em 5–10 min: o que é TSP, por que Christofides + 2-opt, o que o GraphHopper faz no pipeline e onde está o cache de matriz

**Criterio de aceite**: Rota de 1000 pontos otimizada em < 2 s (GH embarcado); resultado persistido com path_geometry; Blossom < 120 ms por cluster. Mentorado consegue explicar o pipeline e o por quê dos algoritmos.

---

## Sprint 4 - Ingestao + Tracking + ETA + Auditoria (docs 05, 06, 07)

- [ ] [M] Flyway migration V003: tabelas route_execution, live_position, execution_event (audit cols), dead_letter_event
- [ ] [M] Entidades JPA: `RouteExecutionJpaEntity`, `LivePositionJpaEntity`, `ExecutionEventJpaEntity` + repositórios
- [ ] [M] Port `VehicleStateStore`; implementação `RedisVehicleStateStore` (estado por vehicleId em Redis)
- [ ] [M] Events: `LocationUpdatedEvent`, `EtaUpdatedEvent` (conforme doc 11); port `EventPublisher`
- [ ] [M] `EtaEngine` (incremental, EWMA, clamping, incidentFactor); entrada `observedSpeedMps` = evento.payload.speedMps (velocidade reportada pelo veículo) — doc 07
- [ ] [M] Port `ProcessLocationUpdatePort`; `ProcessLocationUpdateUseCase`: ler estado, calcular ETA, auditoria (traceId, sourceEventId, decision, durationMs), publicar EtaUpdated, salvar estado
- [ ] [M] Dedup: `RedisLocationDedup` (vehicleId + occurredAt, TTL 2 min); rate limit: `RateLimitConfig.isLocationRateLimited()` via Redis
- [ ] [M] `NatsLocationListener` (consumer `route.location.>`): captura payload raw, chama use case, propaga traceId (header X-Trace-Id)
- [ ] [M] `LocationIngestionController`: POST /api/v1/locations (batch), validar, publicar LocationUpdatedEvent por posição (ou enfileirar para NATS)
- [ ] [M] WebSocket: `EtaWebSocketHandler` (push ETA ao cliente)
- [ ] [M] Batch insert para `live_position` (opcional); JWT no controller (opcional); testes de integração NATS + Redis (Testcontainers)

**Criterio de aceite**: Simular 10 veículos enviando batch de posições via API, ETA atualizado, push via WebSocket, execution_event auditável por traceId.

---

## Sprint 5 - Policies (doc 08)

- [ ] [M] `DestinationArrivalPolicy` (raio 20m); `RecalculationThrottlePolicy` (30s intervalo, max 2/min)
- [ ] [M] `RouteDeviationPolicy` (corredor + heading; consultar `OsmRoadRepository.findNearestRoad()` para highway) — doc 08
- [ ] [M] `IncidentImpactPolicy` (factor >= 1.4 → recalculo); `IncidentEtaAdjuster` (penalidade por severidade); `EtaUpdatePolicy` (wrapper EtaEngine)
- [ ] [M] Máquina de estados: IN_PROGRESS, DEGRADED_ESTIMATE, RECALCULATING, ARRIVED, STOPPED, FAILED (enum/record)
- [ ] [M] `ActiveIncident` (record) com `affectsSegment()`: haversine + projeção perpendicular no segmento (evitar stub que retorna true)
- [ ] [M] Integrar policies no `ProcessLocationUpdateUseCase`: ordem desvio → throttle → chegada → ETA; disparar recálculo ou publicar EtaUpdated
- [ ] [M] `FinalizeRouteUseCase` (marca ARRIVED, zera ETA); events: `EtaDegradedEvent`, `SignalLostEvent`, `SignalRecoveredEvent`
- [ ] [M] R-tree (JTS STRtree) para segmento mais próximo (opcional); testes de cenários (desvio, chegada, throttle)

**Criterio de aceite**: Simular desvio → recálculo → novo ETA. Simular chegada → ARRIVED.

---

## Sprint 6 - Incidentes Crowdsourced (doc 09)

- [ ] [M] Flyway migration V001: tabelas `incident`, `incident_vote` (e `incident_impact` se usar)
- [ ] [M] Entidades JPA: `IncidentJpaEntity`, `IncidentVoteJpaEntity`, `IncidentImpactJpaEntity` + repositórios (tile range, expire)
- [ ] [M] Events: `IncidentReportedEvent`, `IncidentActivatedEvent`, `IncidentExpiredEvent` (doc 11)
- [ ] [M] `ProcessIncidentReportUseCase` (report + dedup por tile); `ProcessIncidentVoteUseCase` (voto + quorum); `ExpireIncidentsUseCase` (scheduled)
- [ ] [M] `RedisIncidentCache` (incidentes ativos por tile, TTL 5 min); `RateLimitConfig.isIncidentRateLimited()` (max 5/min por usuário)
- [ ] [M] `NatsIncidentListener` (incident.reported.>) → use case; port `ReportIncidentPort` (retornar incidentId real, não eventId)
- [ ] [M] API REST: POST /api/v1/incidents (report), POST /api/v1/incidents/{id}/vote, GET /api/v1/incidents?lat=&lon=&radius=
- [ ] [M] WebSocket: `IncidentAlertHandler`, endpoint `/ws/incidents` (push INCIDENT_ALERT)
- [ ] [M] Integração incident + engine (penalidade nos segmentos); testes de integração (report → quorum → ETA)

**Criterio de aceite**: Reportar incidente → quorum → ETA ajustado para veículos na região; incidente visível no trecho.

---

## Sprint 7 - Escala 1000x1000 + DLQ + Inatividade (docs 10, 12, 04B)

- [ ] [M] Stream DEAD_LETTER no NATS; `DeadLetterPublisher`; entidade `DeadLetterEventJpaEntity` + repositório (persistir payload raw)
- [ ] [M] Nos listeners (Location, Recalc, Incident): em falha após retry, publicar na DLQ com `ProcessingError` (não chamar publish com assinatura errada: usar `(ProcessingError, String, String)`)
- [ ] [M] `InactivityDetectorJob` (scheduled): scan ativo (ex.: Redis SCAN), detectar SIGNAL_LOST / STOPPED / ABANDONED, emitir eventos e auditoria
- [ ] [M] Retry policy em `application.yml` (max-attempts, backoff-base-ms, backoff-multiplier)
- [ ] [M] Refatorar `Graph` para `double[][]` (opcional); cluster size dinâmico (opcional); particionamento NATS / MaxAckPending (opcional, pleno)
- [ ] [M] Batch insert `live_position`; testes de carga (1000 veículos x 10 updates/s; rota 1000 pts); profiling JFR (pleno)

**Criterio de aceite**: 1000 veículos simulados, ETA p95 <= 200 ms; DLQ captura erros com payload; InactivityJob detecta inativos em < 15s.

---

## Sprint 8 - Observabilidade + Hardening (doc 13)

- [ ] [M] Adicionar ao `pom.xml`: Micrometer + Prometheus, `logstash-logback-encoder`; Actuator (health, info, prometheus, metrics) em `application.yml`
- [ ] [M] `logback-spring.xml`: LogstashEncoder (JSON em prod, texto em dev/local); campos: vehicleId, routeId, traceId, decision, processingMs
- [ ] [M] OpenTelemetry tracing: propagar traceId mobile → API → NATS → tracking → WebSocket (opcional, pleno)
- [ ] [M] Dashboards Grafana (ETA latency, recalc rate, incidents, consumer lag, DLQ); dashboard auditoria (traceId, sourceEventId, vehicleId)
- [ ] [M] Alertas (recalc spike, degraded, consumer lag, circuit breaker, DLQ growth) e runbooks doc 13 vinculados
- [ ] [M] Chaos testing (opcional, pleno); review SLOs; documentação final

**Criterio de aceite**: Dado um erro, rastrear pelo traceId: payload de entrada, decisão, onde falhou; dado original na DLQ.

---

## Pontos de atenção ao implementar (mentorado [M])

Ao codar, evite estes erros (foram problemas comuns em versões anteriores). Use como checklist de qualidade.

- [ ] [M] `GraphHopperSegmentRouter.routeSegments()`: usar `Arrays.asList(array)` e não `List.of(array)` (List.of de array retorna lista com 1 elemento)
- [ ] [M] `ExecutionEventJpaEntity.executionId`: deixar `nullable=true` (InactivityJob pode não ter execution associada)
- [ ] [M] `IncidentController.report()`: retornar o **incidentId** real (UUID) via port, não o eventId
- [ ] [M] `ActiveIncident.affectsSegment()`: implementar verificação espacial (haversine + projeção no segmento), não stub que retorna sempre true
- [ ] [M] `IncidentImpactPolicy` e `IncidentEtaAdjuster`: assinatura com `GeoPoint vehiclePosition` (não só segmentIndex)
- [ ] [M] DLQ: `DeadLetterPublisher.publish(ProcessingError, String, String)` — construir `ProcessingError`, não passar três strings
- [ ] [M] `application.yml`: um único bloco `routing.optimization` (com `cache` como sub-chave); não duplicar (segundo sobrescreve)
- [ ] [M] Exceções: não usar `catch (Exception e)` genérico; usar exceções nomeadas (`DomainException`, `OptimizationException`, etc.) + `GlobalExceptionHandler` com `ErrorResponse` (timestamp, status, errorCode, message, path, traceId)
- [ ] [M] Hierarquia: `RoutingException` (abstract) → exceções de domínio/infra
- [ ] [M] TraceId: propagar do header (ex.: X-Trace-Id) → NATS header → MDC no listener; `ProcessLocationUpdateUseCase` ler do MDC, não gerar aleatório
- [ ] [M] `InactivityDetectorJob`: implementar com stateStore.scanActiveVehicleIds(), thresholds, emissão de eventos
- [ ] [M] `RouteDeviationPolicy.isHighway()`: usar `OsmRoadRepository.findNearestRoad()` e checar tipo (motorway/trunk/primary), não heurística por distância

## Documentação — Fluxos de Auth (para não esquecer)

Checklist de fluxos a implementar e documentar (backend + app):

| Fluxo | Backend | App (Flutter) |
|-------|---------|----------------|
| **Cadastro** | POST /api/v1/users (criar usuário) | Tela de registro; enviar email, senha, nome; após sucesso → login ou tela de login |
| **Login** | POST /api/v1/auth/login (email, password, rememberMe); retorna accessToken, refreshToken, user | Tela de login; checkbox "Lembrar de mim"; guardar tokens em secure storage; se rememberMe, guardar refresh/remember conforme backend |
| **Remember me** | Cookie ou token persistido com TTL longo; endpoint para renovar sessão com remember-me | Ao abrir app, se só tiver remember-me (sem access válido), chamar renovação e obter novo access ou redirecionar para login |
| **Logout** | POST /api/v1/auth/logout (Bearer); revogar refresh token; opcional: blocklist do access token (jti no Redis com TTL) para revogar acesso na hora; access token curto (ex. 15 min) reduz janela em que o token ainda vale após logout | Botão sair; chamar logout (envia Bearer para o backend revogar); limpar tokens e storage; navegar para login |
| **Revogar todas as outras sessões** | POST /api/v1/auth/revoke-all-other-sessions (Bearer); revogar todos os refresh tokens do usuário; emitir novo refresh token para a sessão atual e retornar no body; dispositivo atual atualiza o refresh no storage e permanece logado; outros dispositivos (ex. celular perdido/roubado) deixam de renovar. Caso de uso: usuário perdeu ou foi roubado o celular e acessa de outro aparelho para encerrar as sessões nos outros. | Tela Segurança/Sessões (ex. em Perfil ou Configurações): botão "Encerrar sessões em todos os outros dispositivos"; chamar revoke-all-other-sessions; se backend retornar novo refreshToken, atualizar no storage; mensagem de sucesso (ex. "As outras sessões foram encerradas. Este aparelho continua logado.") |
| **Refresh token** | POST /api/v1/auth/refresh (refreshToken); retorna novo accessToken; invalidar refresh usado | Interceptor: em 401, chamar refresh; se OK, reenviar request; se falha → logout e tela de login |
| **Forgot password** | POST /api/v1/auth/forgot-password (email); POST /api/v1/auth/reset-password (token, newPassword) | Tela "Esqueci a senha" → email; tela de reset (link com token) → nova senha |
| **Change password** | POST /api/v1/auth/change-password (Bearer; currentPassword, newPassword) | Tela "Alterar senha" (dentro do app, logado); enviar senha atual + nova; após sucesso, opcionalmente re-login ou apenas feedback |

**Endpoints de referência (backend):**

- `POST /api/v1/users` — registro (Create user; role = USER)
- `GET /api/v1/users/me` — usuário logado (qualquer role)
- `GET /api/v1/users` — **admin-only** listar todos os usuários
- `GET /api/v1/users/{id}` — por id (próprio ou admin)
- `PUT /api/v1/users/{id}` — atualizar (próprio ou admin; regras de role)
- `DELETE /api/v1/users/{id}` — **admin-only** desativar/remover usuário
- `POST /api/v1/auth/login` — login (email, password, rememberMe)
- `POST /api/v1/auth/logout` — logout (Bearer); revoga só a sessão atual
- `POST /api/v1/auth/revoke-all-other-sessions` — revogar todas as outras sessões (Bearer); retorna novo refreshToken para a sessão atual; uso: perda/roubo do celular
- `POST /api/v1/auth/refresh` — refresh token (body: refreshToken)
- `POST /api/v1/auth/forgot-password` — solicitar reset (email)
- `POST /api/v1/auth/reset-password` — resetar com token (token, newPassword)
- `POST /api/v1/auth/change-password` — trocar senha logado (currentPassword, newPassword)

**Roles (User vs Admin):**

| Ação | USER | ADMIN |
|------|------|-------|
| Cadastrar-se (POST /users) | ✅ | ✅ |
| Login, logout, refresh, forgot/change password | ✅ | ✅ |
| GET /users/me, PUT /users/{id} (próprio) | ✅ | ✅ |
| GET /users (listar todos) | ❌ 403 | ✅ |
| GET /users/{id} (outro usuário) | ❌ 403 | ✅ |
| PUT /users/{id} (outro usuário) | ❌ 403 | ✅ |
| DELETE /users/{id} (remover usuário) | ❌ 403 | ✅ |
| Demais features admin-only (auditoria, DLQ, etc.) | ❌ 403 | ✅ |

O **ADMIN** é o dono da aplicação (você); apenas admin pode remover usuários e acessar gestão do sistema.

---

## Legenda

- `[ ]` = Item a fazer (nada implementado ainda)
- **[E] Especialista** = Você faz: (1) esqueleto (repo, Docker, config, pacotes, NatsConfig); (2) **código complexo** (ex.: algoritmos do OptimizationEngine — Christofides, 2-opt, GraphHopper, cache). Para (2), o mentorado **não** implementa; a tarefa dele é **entender** (estrutura, estruturas de dados, por quê).
- **[M] Mentorado** = Implementa em código (domínio, APIs, use cases, policies, testes, etc.) **ou**, nos itens [E] complexos, **lição de casa**: estudar docs/código, desenhar pipeline, explicar ao mentor. Guia: `docs-junior-plus/` e `docs-junior-plus/pleno/`.
