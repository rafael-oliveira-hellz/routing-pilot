# 04 - Trilha prática Júnior+

Passo a passo para estudar e implementar o projeto, com **checkpoints** e **exercícios** por Sprint (visão **resumida**).

> **04 vs 07:** Use **um dos dois** como guia principal, não os dois em paralelo. Este doc (04) é um **roteiro enxuto** por Sprint. Se você está **do zero** no projeto e prefere **tasks numeradas** com passos, entregável e critério de conclusão, use o [07 - Tasks passo a passo (zero → Júnior+)](./07-Tasks-Passo-a-Passo-Junior-Plus.md). A ordem de leitura está no [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md).

---

## Antes de codar

- [ ] Ler [01 - Glossário](./01-Glossario-e-Conceitos.md) e anotar termos que ainda não domina.
- [ ] Ler [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) e abrir o [README de docs](../docs/README.md).
- [ ] Subir o ambiente: `compose.yaml` (PostgreSQL/PostGIS, Redis, NATS) e conferir que a aplicação sobe (se houver `pilot` ou módulo principal).

**Checkpoint:** Conseguir explicar em uma frase: o que é “hot path” e “cold path” neste projeto?

---

## Sprint 1 – Fundação

**Docs:** 01, 02, 15, 04C. **Checklist:** [14 - Sprint 1](../docs/14-Checklist-Sprints.md).

- [ ] Ler doc 01 (Visão Geral) e desenhar no papel o fluxo: GPS → evento → tracking → ETA → WebSocket.
- [ ] Ler doc 02 (Modelo de Domínio) e listar os 4 bounded contexts e um aggregate root de cada.
- [ ] No código: localizar um **value object** (ex.: `GeoPoint`) e um **enum** (ex.: `VehicleStatus`). Ver como são usados em uma entidade ou evento.
- [ ] Rodar migrations Flyway e conferir tabelas (incl. `geo.*` se aplicável).

**Exercício:** Criar um value object `TimeWindow` (start, end) com validação no construtor compacto (start &lt; end). Onde ele seria usado no domínio? (R: doc 02 – RouteStop.)

**Checkpoint:** Explicar por que o projeto usa NATS em vez de “um serviço chamar o outro por HTTP”.

---

## Sprint 2 – RoutePlanning

**Docs:** 03. **Checklist:** Sprint 2.

- [ ] Ler doc 03 e anotar: quais validações o `RouteRequestValidator` faz?
- [ ] No código: achar o `CreateRouteRequestUseCase` e o controller que expõe `POST /api/v1/route-requests`. Seguir um request do controller até a publicação do evento.
- [ ] Escrever um teste unitário para `RouteRequestValidator`: request com 2 pontos (origem/destino) e 10 stops → válido; 1001 stops → exceção.

**Exercício:** Se o limite de stops mudar de 1000 para 500, em quantos lugares você precisaria alterar? (Objetivo: perceber validação centralizada e doc como referência.)

**Checkpoint:** Criar um request com 100 stops via API (ou teste de integração) e confirmar que o evento correspondente é publicado no NATS.

---

## Sprint 3 – OptimizationEngine

**Docs:** 04, 04A, 04B. **Checklist:** Sprint 3.

- [ ] Ler doc 04 (Contexto) e resumir em 3 linhas: papel do Kruskal, do Christofides e do 2-opt.
- [ ] No código: localizar `ParallelRouteEngine` ou orquestrador equivalente. Ver onde ele usa ForkJoinPool e onde chama GraphHopper.
- [ ] Ler trecho do doc 04B sobre complexidade e memória; anotar o que “1000 veículos x 1000 pontos” implica.

**Exercício:** Desenhar um pipeline simplificado: entrada (lista de pontos) → clusterização → Christofides por cluster → 2-opt → GraphHopper segmentos → saída (rota com geometria).

**Checkpoint:** Rodar uma otimização com 100 pontos e ver o resultado persistido (e tempo de resposta, se possível).

---

## Sprint 4 – Ingestão + Tracking + ETA

**Docs:** 05, 06, 07. **Checklist:** Sprint 4.

- [ ] Ler doc 05 (Ingestão): contrato do batch, dedup, rate limit. Doc 07: velocidade do veículo (speedMps) no payload; camadas do ETA e fórmula incremental (EWMA, confidence).
- [ ] No código: achar `ProcessLocationUpdateUseCase` e o listener NATS que o chama. Ver onde o `EtaEngine` é chamado e onde o evento `EtaUpdatedEvent` é publicado.
- [ ] Simular 2 posições do mesmo veículo com `occurredAt` idêntico e verificar que a segunda é considerada duplicata (dedup).

**Exercício:** Calcular na mão um passo do ETA: distância restante 5000 m, velocidade suavizada 15 m/s, trafficFactor 1.0, incidentFactor 1.2. Qual `remainingSeconds`? (Fórmula no doc 07.)

**Checkpoint:** 10 veículos enviando batch de posições; ETA atualizado e visível via WebSocket (ou log); um registro de auditoria encontrado por `traceId`.

---

## Sprint 5 – Policies

**Docs:** 08. **Checklist:** Sprint 5.

- [ ] Ler doc 08: quais policies existem (desvio, throttle, chegada, incidente) e em que ordem são avaliadas?
- [ ] No código: abrir `RouteDeviationPolicy` e `RecalculationThrottlePolicy`. Ver como o use case de location as chama antes de decidir “recalcular” ou “só ETA”.
- [ ] Escrever um cenário (em texto ou teste): “veículo desvia 60 m do corredor; último recálculo há 10 s” → decisão esperada (throttle bloqueia?).

**Checkpoint:** Simular desvio e ver recálculo (ou throttle bloqueando); simular chegada e ver status ARRIVED.

---

## Sprint 6 – Incidentes

**Docs:** 09. **Checklist:** Sprint 6.

- [ ] Ler doc 09: fluxo report → votos → quorum → ativação; TTL e impacto no ETA.
- [ ] No código: `ProcessIncidentReportUseCase`, `ProcessIncidentVoteUseCase`, e onde `IncidentEtaAdjuster` é usado no fluxo de ETA.
- [ ] Fazer um report de incidente via API e outro usuário (ou mesmo) dar voto; conferir que o incidente ativa quando atinge quorum.

**Checkpoint:** Reportar incidente → quorum → ETA de um veículo na região ajustado (ou métrica de incidente ativo aumentando).

---

## Sprint 7 e 8 – Escala e operação

**Docs:** 10, 12, 13. **Checklist:** Sprints 7 e 8.

- [ ] Ler doc 10 (DLQ, auditoria) e doc 13 (métricas, SLOs, runbooks). Saber o que fazer quando “recalc spike” ou “consumer lag”.
- [ ] No código: onde eventos falhos vão para a DLQ? Onde está o `InactivityDetectorJob`?
- [ ] Opcional: configurar uma métrica Micrometer e ver no Prometheus/Actuator.

**Checkpoint:** Conseguir explicar o runbook RB-01 (pico de recálculo) ou RB-03 (consumer lag) para um colega.

---

## Hábito júnior+

- **Sempre que abrir um doc novo:** anotar 3 termos que você procuraria no glossário.
- **Sempre que implementar um item do Checklist:** marcar o doc correspondente no [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) e qual camada (domain, application, engine, infrastructure, api) você está tocando.
- **Ao terminar uma Sprint:** responder ao “critério de aceite” do Checklist em uma frase e, se possível, escrever um teste que demonstre esse critério.

No fim da trilha você terá percorrido todos os contextos, eventos e padrões do projeto e estará pronto para evoluir tarefas sozinho e com qualidade júnior+.
