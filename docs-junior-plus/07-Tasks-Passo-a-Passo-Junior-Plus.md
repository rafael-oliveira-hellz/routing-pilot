# 07 - Tasks passo a passo (do zero ao Júnior+)

Tarefas numeradas para levar você do **absoluto zero** (sem conhecimento do projeto) até **júnior+**: conceitos, ambiente, leitura de docs, implementação por Sprint e checkpoints. Cada task tem **passos**, **entregável** e **critério de conclusão**. Marque ao concluir.

> **04 vs 07:** Use **um dos dois** como guia principal, não os dois em paralelo. Este doc (07) é a **versão completa** (Fases 0–10, tasks numeradas). Se você prefere um **roteiro resumido** por Sprint, use o [04 - Trilha prática Júnior+](./04-Trilha-Pratica-Junior-Plus.md). A ordem ideal de leitura de todos os MDs está no [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md).

---

## Visão geral das fases

| Fase | Foco | Onde você chega |
|------|------|------------------|
| **0** | Primeiro contato | Repo conhecido, ambiente no ar |
| **1** | Conceitos e mapa | Glossário e Mapa na cabeça; expectativa de Júnior+ alinhada |
| **2** | Visão do sistema | Fluxo macro desenhado; hot/cold path e NATS explicados |
| **3** | Sprint 1 – Fundação | Domínio base, infra, valor de “por que NATS” |
| **4** | Sprint 2 – RoutePlanning | API de rota, validação, evento publicado |
| **5** | Sprint 3 – OptimizationEngine | Pipeline de otimização entendido e rodando |
| **6** | Sprint 4 – Ingestão + ETA | GPS → ETA → WebSocket e auditoria por traceId |
| **7** | Sprint 5 – Policies | Desvio, throttle, chegada; testes de cenário |
| **8** | Sprint 6 – Incidentes | Report, quorum, impacto no ETA |
| **9** | Sprint 7 e 8 – Escala e operação | DLQ, runbooks, métricas; explicar um runbook |
| **10** | Hábitos Júnior+ | Autonomia com Mapa + Checklist; próximo passo = Pleno |

---

## Fase 0 – Primeiro contato (do zero)

### Task 0.1 – Conhecer o repositório e esta pasta

**Objetivo:** Saber onde está a documentação de pessoas (docs-junior-plus) e a documentação técnica (docs).

**Passos:**

1. Abra a raiz do repositório (pasta do projeto). Liste as pastas principais: `docs/`, `docs-junior-plus/`, `pilot/` (ou onde estiver o código).
2. Entre em `docs-junior-plus/`. Leia só o **README** (primeira seção “Trilha Júnior → Júnior+” e a tabela de documentos). Não precisa ler tudo ainda.
3. Abra `docs/README.md` e leia o primeiro bloco (“Motor de Roteamento e ETA”) e a tabela “Mapa de documentação”. Anote: quantos Sprints existem e qual o doc 01 e 02.
4. Crie um arquivo de anotações (bloco de notas ou `docs-junior-plus/minhas-anotacoes.md`) e escreva em 3 linhas: “O que é este projeto?” e “Onde fica o guia para júnior?”.

**Entregável:** Anotações com visão mínima do repo e localização do guia.

**Critério de conclusão:** Você consegue dizer a alguém onde está o guia júnior+ e quantos Sprints o projeto tem.

---

### Task 0.2 – Subir o ambiente

**Objetivo:** Ter PostgreSQL/PostGIS, Redis e NATS (e a aplicação, se houver) rodando localmente.

**Passos:**

1. Verifique se você tem **Docker** (e Docker Compose) instalado. Se não, instale ou use o ambiente que o time indicar.
2. Localize o arquivo de Compose do projeto (em geral `pilot/compose.yaml` ou `docker-compose.yml` na raiz). Abra e anote quais serviços estão definidos (postgres, redis, nats, app).
3. Na pasta onde está o compose, rode o comando para subir os serviços (ex.: `docker compose up -d` ou `docker-compose up -d`). Aguarde os containers subirem.
4. Confira que os serviços estão de pé (ex.: `docker compose ps`). Se houver aplicação Java, rode o build/start conforme o README do projeto e confira que a aplicação sobe sem erro de conexão (PG, Redis, NATS).
5. No seu arquivo de anotações, registre: “Comando que usei para subir o ambiente” e “O que deu errado (se deu)” para poder repetir ou pedir ajuda.

**Entregável:** Ambiente no ar; anotação do comando e de possíveis erros.

**Critério de conclusão:** Você consegue subir o ambiente de novo sozinho; conexões com PG/Redis/NATS OK (ou erro documentado para o time).

---

### Task 0.3 – Primeira leitura do guia e do projeto

**Objetivo:** Saber como usar o guia e qual o objetivo do projeto em uma frase.

**Passos:**

1. Leia o [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md) do início ao fim.
2. Leia a seção “Objetivo do projeto (resumo)” do [README](./README.md) de docs-junior-plus (e, se quiser, o primeiro parágrafo do [docs/README.md](../docs/README.md)).
3. Escreva em uma frase no seu arquivo de anotações: “Objetivo do projeto: …”. Escreva também: “Ordem que vou seguir: primeiro … depois …” (use o 00 como referência).

**Entregável:** Uma frase sobre o objetivo do projeto e a ordem de estudo que você vai seguir.

**Critério de conclusão:** Você sabe que deve começar pelo Glossário e pelo Mapa e que o projeto é motor de roteamento/ETA em tempo real para 1000+ veículos.

---

## Fase 1 – Conceitos e mapa

### Task 1.1 – Ler o Glossário e anotar termos

**Objetivo:** Ter referência dos termos que aparecem nos docs e no código.

**Passos:**

1. Leia o [01 - Glossário e conceitos](./01-Glossario-e-Conceitos.md) do início ao fim.
2. Para cada seção (Arquitetura e domínio, Infraestrutura e mensageria, Performance e operação, Domínio do projeto), anote **2 termos** que você não dominava ou que são centrais (ex.: event-driven, bounded context, hot path, ETA, traceId).
3. Leia a “Resumo rápido” no final. Copie a tabela para seu arquivo de anotações ou marque como “consultar quando esquecer”.
4. Quando encontrar um termo novo em qualquer doc daqui pra frente, volte ao Glossário e leia a definição.

**Entregável:** Lista de termos anotados (por seção) e tabela de resumo acessível.

**Critério de conclusão:** Você consegue explicar em uma frase: event-driven, bounded context, hot path e traceId.

---

### Task 1.2 – Usar o Mapa do projeto e dos docs

**Objetivo:** Saber onde está cada tema (qual doc, qual camada de código).

**Passos:**

1. Leia o [02 - Mapa do projeto e docs](./02-Mapa-Do-Projeto-e-Docs.md) inteiro.
2. Na “Estrutura de pastas”, confira no seu repo se as pastas batem (docs, docs-junior-plus, pilot ou skeleton). Anote qualquer diferença (ex.: “código está em X em vez de pilot”).
3. Na “Mapa da documentação”, escolha 3 temas (ex.: Visão geral, RoutePlanning, ETA). Para cada um, anote: **nome do doc**, **caminho do arquivo** e **em uma linha o que você encontra lá**.
4. Na “Onde está o quê no código”, leia a tabela de responsabilidades (domain, application, engine, infrastructure, api). Anote: “Onde ficam as validações de domínio?” e “Onde ficam os listeners NATS?”.

**Entregável:** Anotações sobre estrutura do repo, 3 docs mapeados e onde ficam domínio vs infra.

**Critério de conclusão:** Dado um tema (ex.: “ingestão GPS”), você sabe qual doc abrir e em qual camada procurar no código.

---

### Task 1.3 – Alinhar expectativa: perfil Júnior+

**Objetivo:** Saber o que se espera de um júnior+ e onde cada competência é trabalhada.

**Passos:**

1. Leia o [06 - Perfil e competências Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md).
2. Na tabela “Competências e onde praticar”, marque quais itens você já acha que domina (mesmo que pouco) e quais são totalmente novos.
3. Leia a tabela “Júnior vs Júnior+”. Escreva em 2 linhas: “O que preciso evoluir mais para me sentir júnior+?” (ex.: testes, contratos, runbooks).
4. Guarde esse doc como referência: ao fim de cada Sprint, você pode reler e ver o que já pratica.

**Entregável:** Nota sobre o que você vai priorizar para chegar ao perfil júnior+.

**Critério de conclusão:** Você sabe que júnior+ implementa tarefas com padrões, testes e conhecimento de docs/contratos, e sabe onde vai praticar cada coisa.

---

## Fase 2 – Visão do sistema (docs 01 e 02)

### Task 2.1 – Doc 01: fluxo macro e desenho

**Objetivo:** Entender o fluxo de ponta a ponta (GPS → evento → tracking → ETA → cliente).

**Passos:**

1. Abra o [doc 01 - Visão Geral Event-Driven](../docs/01-Visao-Geral-Event-Driven.md).
2. Leia a seção “Fluxo macro”. Desenhe no papel ou em um arquivo (ASCII ou desenho) o fluxo: **Mobile/GPS** → **LocationUpdatedEvent** → **NATS** → **Tracking Service** → **EtaUpdated** (e os outros serviços mencionados) → **WebSocket/Push**.
3. Leia a tabela “Topologia de serviços”. Anote: qual serviço é “hot path”, qual é “cold path” e por quê (uma linha cada).
4. Leia “Broker: NATS JetStream” e “Subjects recomendados”. Copie ou anote 3 subjects que você vai ver no código (ex.: `route.location.{vehicleId}`, `route.eta.{vehicleId}`).
5. Leia “Latência alvo (p95)” e “Decisão de performance”. Escreva em uma frase: por que a maioria dos eventos não recalcula rota?

**Entregável:** Desenho do fluxo + anotações (hot/cold, 3 subjects, por que não recalcular sempre).

**Critério de conclusão:** Você consegue explicar em 1 minuto o fluxo desde o GPS até o ETA no cliente e por que existe hot path e cold path.

---

### Task 2.2 – Doc 02: bounded contexts e aggregates

**Objetivo:** Saber os 4 contextos e um aggregate root de cada; saber o que é value object.

**Passos:**

1. Abra o [doc 02 - Modelo de Domínio e Bounded Contexts](../docs/02-Modelo-Dominio-Bounded-Contexts.md).
2. Leia o “Mapa de contextos” (diagrama). Liste os **4 bounded contexts** e, para cada um, **1 aggregate root** e **1 value object** da tabela.
3. Leia a seção “Value Objects principais”. Escolha `GeoPoint` e `EtaState`: copie a assinatura (ou definição) e anote onde cada um é usado (qual contexto/entidade).
4. Leia “Invariantes de domínio”. Anote 2 invariantes (ex.: “exatamente 1 origem + 1 destino”, “máximo 1000 stops”).
5. No código (pilot ou skeleton), localize a classe `GeoPoint` (ou equivalente). Confira se há validação no construtor (lat/lon dentro do intervalo). Se não houver, anote “falta validação” para discutir com o time.

**Entregável:** Lista dos 4 contextos com aggregate root e VO; 2 invariantes; confirmação de onde está GeoPoint no código.

**Critério de conclusão:** Você consegue dizer qual contexto cuida de “planejamento de rota”, qual de “otimização”, qual de “execução/ETA” e qual de “incidentes”, e o que é um value object neste projeto.

---

### Task 2.3 – Checkpoint: hot path, cold path e NATS

**Objetivo:** Consolidar os conceitos que diferenciam júnior de júnior+ na visão do sistema.

**Passos:**

1. Sem olhar os docs, escreva em 2–3 frases: “O que é hot path e cold path neste projeto? Dê um exemplo de cada.”
2. Escreva em 1 frase: “Por que o projeto usa NATS em vez de um serviço chamar o outro por HTTP?”
3. Se tiver dúvida, releia o [01 - Glossário](./01-Glossario-e-Conceitos.md) (hot path, cold path) e o doc 01 (decisão de performance). Corrija suas frases.
4. Guarde essas respostas no seu arquivo de anotações como “Checkpoint Fase 2”.

**Entregável:** Texto curto com suas respostas (hot/cold, NATS).

**Critério de conclusão:** Você consegue explicar para um colega em 1 minuto: hot path vs cold path e por que NATS.

---

## Fase 3 – Sprint 1 – Fundação

**Docs de referência:** [docs 01, 02, 15, 04C](../docs/README.md); [Checklist Sprint 1](../docs/14-Checklist-Sprints.md).

### Task 3.1 – Ler docs da Sprint 1 e localizar no código

**Objetivo:** Saber o que a Sprint 1 entrega e onde está no código.

**Passos:**

1. Abra o [Checklist Sprint 1](../docs/14-Checklist-Sprints.md). Leia a lista de itens (value objects, enums, DomainException, pacotes, Docker, Flyway, PostGIS, etc.). Marque mentalmente o que já existe no repo e o que falta.
2. Abra o [doc 15 - Skeleton Java](../docs/15-Skeleton-Java.md). Confira a “Estrutura de pacotes” e a tabela “Camadas e responsabilidades”. No código, ache a pasta `domain/` (ou equivalente) e pelo menos um arquivo em `domain/model/` e um em `domain/enums/`.
3. Abra o [doc 02](../docs/02-Modelo-Dominio-Bounded-Contexts.md) de novo e confira a lista de value objects. No código, localize pelo menos **GeoPoint**, **EtaState** e **VehicleStatus** (enum). Anote o caminho do pacote/classe.
4. Rode as migrations Flyway (se o projeto tiver). Confira que as tabelas existem (incl. `geo.*` se aplicável). Anote o caminho das migrations (`resources/db/migration/` ou similar).

**Entregável:** Anotações: itens do Checklist que existem vs faltam; caminho de domain/model e enums; migrations rodadas.

**Critério de conclusão:** Você sabe onde estão value objects, enums e migrations e consegue rodar as migrations com sucesso.

---

### Task 3.2 – Implementar ou revisar um value object (TimeWindow)

**Objetivo:** Praticar padrão de value object com validação no construtor.

**Passos:**

1. Leia o [03 - Padrões de código](./03-Padroes-de-Codigo-Explicados.md), seção “Records para value objects”.
2. No doc 02, veja a menção a `TimeWindow` (RouteStop). No código, verifique se já existe uma classe/record `TimeWindow` (start, end). Se não existir, crie em `domain/model/` (ou onde o time definir): record com `Instant start`, `Instant end` e validação no construtor compacto: `start` deve ser antes de `end`; caso contrário, lance exceção de domínio.
3. Escreva um teste unitário para `TimeWindow`: (a) start &lt; end → válido; (b) start = end ou start &gt; end → exceção.
4. Rode os testes e confira que passam.

**Entregável:** Classe/record `TimeWindow` (se criada) + teste unitário.

**Critério de conclusão:** TimeWindow existe com validação e tem pelo menos 2 cenários de teste (válido e inválido).

---

### Task 3.3 – Critério de aceite Sprint 1

**Objetivo:** Fechar a Sprint 1 com o critério de aceite atendido.

**Passos:**

1. Leia o “Critério de aceite” da Sprint 1 no [Checklist](../docs/14-Checklist-Sprints.md): `./mvnw verify` passa, conexões PG/Redis/NATS OK, tabelas `geo.*` populadas (se aplicável).
2. Rode `./mvnw verify` (ou o comando de build do projeto). Se falhar, anote o erro e corrija (ou peça ajuda). Até que passe.
3. Confira conexões: a aplicação sobe e não dá erro de conexão com PostgreSQL, Redis e NATS. Se houver health check (Actuator), abra e confira.
4. Se o projeto tiver import OSM e tabelas `geo.*`, confira que existem e estão populadas (ou documente “falta import” como pendência). Caso contrário, considere o critério atendido se verify e conexões estiverem OK.
5. No seu arquivo de anotações, escreva: “Sprint 1 – critério de aceite: [uma frase descrevendo o que você validou].”

**Entregável:** Build verde, conexões OK, anotação do critério de aceite.

**Critério de conclusão:** `./mvnw verify` passa e você consegue explicar o que a Sprint 1 entrega (fundação: domínio, infra, migrations).

---

## Fase 4 – Sprint 2 – RoutePlanning

**Docs:** [03 - RoutePlanning](../docs/03-Contexto-RoutePlanning.md); [Checklist Sprint 2](../docs/14-Checklist-Sprints.md).

### Task 4.1 – Doc 03 e validações

**Objetivo:** Saber o que é RouteRequest, quais validações existem e onde estão no código.

**Passos:**

1. Leia o [doc 03 - Contexto RoutePlanning](../docs/03-Contexto-RoutePlanning.md) inteiro.
2. Anote: (a) o que é o aggregate root; (b) quais tabelas/entidades existem (route_request, route_point, route_stop, route_constraint); (c) as validações do `RouteRequestValidator` (ex.: exatamente 2 pontos, máx 1000 stops, departure_at >= created_at).
3. No código, localize `RouteRequestValidator` (ou equivalente). Confronte com o doc: as validações batem? Anote qualquer diferença.
4. Localize o controller que expõe `POST /api/v1/route-requests` (ou similar). Trace: request HTTP → controller → use case → validação → persistência → publicação de evento. Anote os nomes das classes em cada passo.

**Entregável:** Resumo do doc 03 + rota request → controller → use case → evento.

**Critério de conclusão:** Você sabe quais validações o RouteRequestValidator faz e por onde passa um POST de rota até o evento.

---

### Task 4.2 – Teste unitário para RouteRequestValidator

**Objetivo:** Garantir cobertura de cenário válido e inválido (máximo de stops).

**Passos:**

1. Crie (ou abra) a classe de teste para `RouteRequestValidator`.
2. Cenário 1: request com **exatamente 2 pontos** (origem e destino) e **10 stops** → deve passar (sem exceção). Implemente o teste.
3. Cenário 2: request com **1001 stops** → deve lançar exceção de domínio (mensagem ou tipo que o projeto usar). Implemente o teste.
4. Rode os testes. Ajuste até que ambos passem.
5. Opcional: adicione um cenário com 0 pontos ou 1 ponto (inválido) e confira que a validação rejeita.

**Entregável:** Testes unitários para RouteRequestValidator (válido com 10 stops; inválido com 1001 stops).

**Critério de conclusão:** Os testes falham se você remover ou quebrar a validação de “máximo 1000 stops” ou “exatamente 2 pontos”.

---

### Task 4.3 – Critério de aceite Sprint 2

**Objetivo:** Criar um request com muitos stops e confirmar que o evento é publicado.

**Passos:**

1. Leia o “Critério de aceite” da Sprint 2 no Checklist: criar request com 100 stops via API e evento publicado no NATS.
2. Via Postman, curl ou teste de integração: envie um `POST /api/v1/route-requests` com payload válido (2 pontos + 100 stops). Use coordenadas e dados compatíveis com o contrato do doc 03.
3. Confira a resposta (ex.: 201 ou 202 e ID do request). Confira no NATS (ou em log/metrica) que o evento correspondente (ex.: RouteOptimizationRequested) foi publicado. Se não tiver como inspecionar NATS diretamente, confira no código que o use case chama o publisher e que um teste de integração cobre esse fluxo.
4. Anote no seu arquivo: “Sprint 2 – critério de aceite: request com N stops criado; evento publicado.”

**Entregável:** Request de 100 stops executado com sucesso; evidência de evento publicado (ou teste de integração que valide).

**Critério de conclusão:** Você consegue criar um request com 100 stops pela API e demonstrar (ou testar) que o evento é publicado.

---

## Fase 5 – Sprint 3 – OptimizationEngine

**Docs:** [04, 04A, 04B](../docs/README.md); [Checklist Sprint 3](../docs/14-Checklist-Sprints.md).

Os **algoritmos** do motor (Kruskal, Christofides, 2-opt, GraphHopper, cache de matriz) são implementados pelo **Especialista** [E] — são complexos demais para serem tarefa de implementação do mentorado. Sua parte aqui é: **(1)** **entender** o que está feito (estrutura, estruturas de dados, por quê de cada algoritmo); **(2)** implementar a **integração** (entidades JPA, `RecalculateRouteUseCase`, `NatsRecalcListener`, config, testes que usam o engine). Veja no Checklist a seção “Lição de casa (mentorado)” da Sprint 3.

### Task 5.1 – Entender o pipeline de otimização

**Objetivo:** Saber o papel do Kruskal, Christofides, 2-opt e GraphHopper no fluxo.

**Passos:**

1. Leia o [doc 04 - Contexto OptimizationEngine](../docs/04-Contexto-OptimizationEngine.md) até a seção que explica cada algoritmo (Kruskal, Christofides, 2-opt, VRP cluster). Para cada um, escreva em **uma linha** o papel (ex.: “Kruskal: gerar MST para o Christofides”).
2. No código, localize o orquestrador (ex.: `ParallelRouteEngine` ou `TwoThirdsApproximationRouteMaker`). Abra o método principal que recebe pontos e devolve rota. Anote a ordem das chamadas: clusterização → … → Christofides → 2-opt → GraphHopper (ou equivalente).
3. Desenhe um pipeline em texto ou diagrama: **entrada** (lista de pontos) → **clusterização** → **Christofides por cluster** → **2-opt** → **GraphHopper segmentos** → **saída** (rota com geometria/distância/duração).
4. Leia um trecho do [doc 04B](../docs/04B-Analise-Performance-Otimizacao.md) sobre complexidade ou “1000 veículos”. Anote em uma frase o que “1000 veículos x 1000 pontos” implica (carga, tempo, memória).

**Entregável:** Resumo de cada algoritmo em 1 linha + pipeline desenhado + 1 frase sobre escala.

**Critério de conclusão:** Você consegue explicar em 2 minutos: o que é TSP, por que Christofides + 2-opt, e em que ordem o código executa.

---

### Task 5.2 – Rodar uma otimização e ver resultado

**Objetivo:** Validar que o motor de otimização roda e persiste resultado.

**Passos:**

1. Garanta que o ambiente está no ar (incl. GraphHopper/config se necessário). Veja no Checklist ou no doc 04 como rodar uma otimização (pode ser via evento de recálculo ou API).
2. Dispare uma otimização com **cerca de 100 pontos** (ou o mínimo que o projeto permitir). Aguarde o fim do processamento.
3. Confira que o resultado foi persistido: tabela de rota/segmentos/waypoints (conforme doc 02 e Checklist). Opcional: anote o tempo de resposta (ms ou s).
4. Anote: “Sprint 3 – otimização com N pontos; resultado persistido em [tabela/entidade]; tempo aproximado X.”

**Entregável:** Evidência de otimização executada e resultado persistido (e, se possível, tempo).

**Critério de conclusão:** Você rodou uma otimização de ~100 pontos e viu o resultado no banco (ou em resposta da API).

---

## Fase 6 – Sprint 4 – Ingestão + Tracking + ETA

**Docs:** [05, 06, 07](../docs/README.md); [Checklist Sprint 4](../docs/14-Checklist-Sprints.md).

### Task 6.1 – Contrato de ingestão e ETA incremental

**Objetivo:** Saber o contrato do batch de posições (incl. **speedMps** obrigatório), dedup, e a fórmula do ETA (velocidade do veículo → EWMA, confidence).

**Passos:**

1. Leia o [doc 05 - Ingestão GPS](../docs/05-Ingestao-GPS-Resiliencia.md): endpoint, contrato do batch (vehicleId, routeId, positions com lat, lon, occurredAt), dedup (vehicleId + occurredAt), rate limit.
2. Leia o [doc 07 - ETA Engine](../docs/07-ETA-Engine-Otimizado.md): origem da velocidade (payload.speedMps reportado pelo veículo), camadas do ETA, ETA incremental (sem recálculo), EWMA, confidence, degraded. Copie a fórmula de “remainingSeconds” (distância restante / velocidade suavizada × fatores); a velocidade suavizada vem do speedMps recebido em cada evento.
3. No código, localize `ProcessLocationUpdateUseCase` e o listener NATS que consome `LocationUpdatedEvent`. Trace: mensagem NATS → listener → use case → (leitura estado, EtaEngine, publicação EtaUpdatedEvent). Anote os nomes das classes.
4. Localize onde o `EtaEngine` é chamado (parâmetros: estado atual, progresso, velocidade, trafficFactor, incidentFactor). Anote a assinatura ou o trecho.

**Entregável:** Resumo do contrato de ingestão e do ETA incremental + fluxo listener → use case → EtaEngine → evento.

**Critério de conclusão:** Você sabe o formato do batch de posições, a chave de dedup e como o ETA é atualizado incrementalmente (sem recalcular rota).

---

### Task 6.2 – Dedup e auditoria por traceId

**Objetivo:** Ver na prática dedup (duplicata descartada) e um registro de auditoria por traceId.

**Passos:**

1. Envie **duas posições** para o mesmo veículo com o **mesmo occurredAt** (ex.: mesmo timestamp em ms). A segunda deve ser considerada duplicata (resposta ou contador de “duplicates”). Confira no código onde está a lógica de dedup (Redis, chave vehicleId + occurredAt).
2. Envie um batch “válido” (posições com occurredAt distintos). Obtenha o **traceId** da resposta ou do header/log. Consulte a tabela de auditoria (ex.: `execution_event`) filtrando por esse traceId. Deve haver pelo menos um registro com a decisão (ex.: ETA_ONLY) e o source_event_id.
3. Anote: “Dedup: chave X; auditoria: tabela Y, filtro por traceId.”

**Entregável:** Evidência de dedup (duplicata rejeitada) e de 1 registro de auditoria encontrado por traceId.

**Critério de conclusão:** Você demonstrou dedup e consegue encontrar no banco a decisão tomada para um evento usando o traceId.

---

### Task 6.3 – Critério de aceite Sprint 4

**Objetivo:** 10 veículos, batch de posições, ETA atualizado e visível (WebSocket ou log), auditoria por traceId.

**Passos:**

1. Leia o critério de aceite da Sprint 4 no Checklist: simular 10 veículos enviando batch de posições; ETA atualizado; push via WebSocket (ou log); execution_event auditável por traceId.
2. Simule 10 veículos (scripts, Postman, ou teste de integração): cada um envia um batch de 1–3 posições. Use vehicleId e routeId válidos.
3. Confira que o ETA é atualizado (log de EtaUpdatedEvent ou leitura do estado no Redis/banco). Se houver WebSocket, conecte e confira que recebe atualização de ETA.
4. Para pelo menos um dos veículos, pegue o traceId e consulte a tabela de auditoria. Deve haver registro com esse traceId.
5. Anote: “Sprint 4 – critério: 10 veículos, ETA atualizado, auditoria por traceId OK.”

**Entregável:** Simulação de 10 veículos + confirmação de ETA + 1 consulta de auditoria por traceId.

**Critério de conclusão:** Você atendeu ao critério de aceite da Sprint 4 (batch, ETA, auditoria).

---

## Fase 7 – Sprint 5 – Policies

**Docs:** [08 - Use Cases e Policies](../docs/08-UseCases-Policies.md); [Checklist Sprint 5](../docs/14-Checklist-Sprints.md).

### Task 7.1 – Policies: ordem e decisão

**Objetivo:** Saber quais policies existem e em que ordem o use case as chama (desvio, throttle, chegada, incidente).

**Passos:**

1. Leia o [doc 08 - Use Cases e Policies](../docs/08-UseCases-Policies.md). Anote: **quais policies** existem (ex.: RouteDeviationPolicy, RecalculationThrottlePolicy, DestinationArrivalPolicy, IncidentImpactPolicy) e **em que ordem** são avaliadas no fluxo de processamento de localização.
2. No código, abra o use case que processa localização (ex.: `ProcessLocationUpdateUseCase`). Localize as chamadas às policies: primeiro desvio? Depois throttle? Depois chegada? Anote a ordem.
3. Abra `RouteDeviationPolicy` e `RecalculationThrottlePolicy`. Para cada uma, anote: **entrada** (parâmetros) e **saída** (boolean ou decisão). Ex.: “Throttle: recebe vehicleId e lastRecalcAt; retorna true se pode recalcular.”
4. Escreva um cenário em texto: “Veículo desvia 60 m do corredor; último recálculo foi há 10 s. O throttle permite recálculo? Decisão esperada: …” Confira no código (valores de MIN_INTERVAL_SECONDS, etc.) e responda.

**Entregável:** Lista de policies + ordem no use case + cenário desvio + throttle com resposta.

**Critério de conclusão:** Você sabe a ordem das policies e consegue prever a decisão para “desvio + último recálculo há 10 s”.

---

### Task 7.2 – Simular desvio e chegada

**Objetivo:** Ver recálculo (ou throttle bloqueando) e status ARRIVED.

**Passos:**

1. Simule um **desvio**: posições fora do corredor (acima do threshold da RouteDeviationPolicy). Confira que o sistema dispara recálculo (ou que o throttle bloqueia se já houve recálculo recente). Veja em log, métrica ou estado (ex.: RECALCULATING).
2. Simule **chegada ao destino**: posição dentro do raio da DestinationArrivalPolicy. Confira que o status passa para ARRIVED e que o ETA vai a zero (ou evento DestinationReached).
3. Anote: “Sprint 5 – desvio: [o que observei]; chegada: [o que observei].”

**Entregável:** Evidência de comportamento em desvio e em chegada (log, métrica ou estado).

**Critério de conclusão:** Você viu na prática o efeito das policies de desvio e de chegada.

---

## Fase 8 – Sprint 6 – Incidentes

**Docs:** [09 - Incidentes Crowdsourced](../docs/09-Incidentes-Crowdsourced.md); [Checklist Sprint 6](../docs/14-Checklist-Sprints.md).

### Task 8.1 – Fluxo report → quorum → ativação → ETA

**Objetivo:** Entender o fluxo de incidentes e onde o ETA é ajustado.

**Passos:**

1. Leia o [doc 09 - Incidentes Crowdsourced](../docs/09-Incidentes-Crowdsourced.md): tipos de incidente, tabelas (incident, incident_vote), fluxo report → votos → quorum → ativação, TTL, impacto no ETA.
2. No código, localize `ProcessIncidentReportUseCase` e `ProcessIncidentVoteUseCase`. Anote: o que cada um recebe e o que faz (persiste, publica evento, verifica quorum).
3. Localize onde `IncidentEtaAdjuster` (ou equivalente) é usado: em que momento do fluxo de ETA o fator de incidente é aplicado? Anote a classe que chama o adjuster.
4. Escolha um tipo de incidente (ex.: BLITZ) e anote: quorum mínimo, TTL padrão, fator de impacto no ETA (se documentado).

**Entregável:** Resumo do fluxo de incidentes + onde o ETA é ajustado + 1 tipo com quorum/TTL.

**Critério de conclusão:** Você sabe como um report vira incidente ativo e como isso afeta o ETA.

---

### Task 8.2 – Report e voto até quorum

**Objetivo:** Reportar incidente, dar voto(s) e ver ativação (e impacto no ETA se aplicável).

**Passos:**

1. Via API: `POST /api/v1/incidents` (ou equivalente) com payload válido (lat, lon, incidentType, reportedBy). Anote o `incidentId` retornado.
2. Dê um ou mais votos (conforme quorum do tipo): `POST /api/v1/incidents/{id}/vote`. Use o incidentId do passo 1. Quando o quorum for atingido, o incidente deve ser ativado (campo ou evento IncidentActivatedEvent).
3. Confira no banco ou em métrica que o incidente está ativo. Se possível, envie posição de um veículo na região do incidente e confira que o ETA é ajustado (fator > 1.0) ou que a métrica de incidente ativo aumenta.
4. Anote: “Sprint 6 – report + voto(s) → quorum → ativação; [impacto no ETA observado ou N/A].”

**Entregável:** 1 incidente reportado, votado até quorum, ativação verificada (e impacto no ETA se possível).

**Critério de conclusão:** Você completou o fluxo report → quorum → ativação e, se possível, viu impacto no ETA.

---

## Fase 9 – Sprint 7 e 8 – Escala e operação

**Docs:** [10, 12, 13](../docs/README.md); [Checklist Sprints 7 e 8](../docs/14-Checklist-Sprints.md).

### Task 9.1 – DLQ, auditoria e runbooks

**Objetivo:** Saber onde eventos falhos vão (DLQ), como auditar e o que fazer em “recalc spike” e “consumer lag”.

**Passos:**

1. Leia o [doc 10 - Auditoria e Erros](../docs/10-Auditoria-Observabilidade-Erros.md): modelo de auditoria, propagação de traceId, DLQ (quando vai, o que guarda).
2. No código, localize onde eventos com falha são publicados na DLQ (ex.: no listener NATS, após retry). Anote a classe e o stream/subject da DLQ.
3. Localize o `InactivityDetectorJob` (ou equivalente): o que ele faz (detectar veículos inativos, emitir evento, etc.)? Anote em 2 linhas.
4. Leia o [doc 13 - Operação, SLOs e Runbooks](../docs/13-Operacao-SLO-Runbooks.md): runbooks RB-01 (pico de recálculo), RB-02 (ETA degradado), RB-03 (consumer lag). Para cada um, anote: **sintoma** e **primeiras 2 ações**.
5. Escolha **RB-01** ou **RB-03**. Escreva em 5–10 linhas um “resumo executivo” do runbook: quando usar, o que verificar primeiro, o que fazer em seguida. Praticar explicar isso para um colega.

**Entregável:** Onde está a DLQ e o InactivityDetectorJob + resumo de RB-01 ou RB-03.

**Critério de conclusão:** Você sabe onde falhas vão parar (DLQ) e consegue explicar um runbook (RB-01 ou RB-03) para outra pessoa.

---

### Task 9.2 – Opcional: métrica no Prometheus/Actuator

**Objetivo:** Ver uma métrica do projeto em Prometheus ou Actuator.

**Passos:**

1. Se o projeto expõe Actuator com `/actuator/prometheus` (ou `/metrics`), abra no navegador e procure por uma métrica mencionada no doc 13 (ex.: `route_eta_update_duration`, `route_recalc_count`). Copie um exemplo de linha.
2. Se tiver Prometheus configurado, confira se essa métrica aparece lá. Caso contrário, anote “Actuator OK; Prometheus não configurado” ou “métrica X vista em Y”.
3. Anote no seu arquivo: “Observabilidade: onde vi métricas (Actuator/Prometheus) e qual métrica exemplar.”

**Entregável:** Evidência de que você acessou métricas (print ou anotação).

**Critério de conclusão:** Você sabe onde ver métricas do projeto (Actuator ou Prometheus).

---

## Fase 10 – Hábitos Júnior+ e próximo passo

### Task 10.1 – Autonomia com Mapa e Checklist

**Objetivo:** Consolidar o hábito de usar Mapa e Checklist para qualquer tarefa nova.

**Passos:**

1. Releia o [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) (seção “Onde está o quê no código”). Escreva em 2 linhas: “Quando me pedirem uma tarefa relacionada a [ex.: incidentes], eu abro o doc X e procuro na camada Y.”
2. Abra o [Checklist Sprints](../docs/14-Checklist-Sprints.md). Escolha **um item não feito** de qualquer Sprint (ex.: “Testes unitários para RouteRequestValidator” ou “OpenAPI”). Siga: (a) qual doc ler; (b) em qual camada implementar; (c) qual critério de aceite. Implemente o item ou documente “o que faria” em 5 passos.
3. Ao terminar uma tarefa no dia a dia, anote no seu arquivo: “Tarefa X – doc Y, camada Z, critério: …”. Faça isso pelo menos 2 vezes (para 2 tarefas diferentes).

**Entregável:** Regra “tarefa → doc + camada” + 1 item do Checklist resolvido (ou plano em 5 passos) + 2 anotações de tarefas reais.

**Critério de conclusão:** Você usa o Mapa e o Checklist de forma consistente para decidir onde ler e onde codar.

---

### Task 10.2 – Resposta ao critério de aceite por Sprint

**Objetivo:** Ter uma frase por Sprint que resume o que foi entregue/validado.

**Passos:**

1. Para cada Sprint que você percorreu (1 a 8), escreva **uma frase** que responda ao “Critério de aceite” do Checklist. Ex.: “Sprint 1: verify passa, PG/Redis/NATS OK, migrations rodadas.” “Sprint 4: 10 veículos, ETA atualizado, auditoria por traceId.”
2. Onde você não executou o critério na prática (ex.: não tem 1000 pontos para testar), escreva: “Sprint X: entendido; critério não executado porque …”.
3. Guarde esse resumo no seu arquivo de anotações como “Critérios de aceite – meu status”.

**Entregável:** Uma frase por Sprint (1–8) com seu status em relação ao critério de aceite.

**Critério de conclusão:** Qualquer pessoa consegue ver o que você validou em cada Sprint.

---

### Task 10.3 – Próximo passo: Pleno

**Objetivo:** Saber o que vem depois de Júnior+ e onde estão as tasks de Pleno.

**Passos:**

1. Releia o [06 - Perfil e competências Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md), seção “Próximo passo: Pleno”.
2. Abra o [pleno/README.md](./pleno/README.md) e o [pleno/02-Tasks-Passo-a-Passo.md](./pleno/02-Tasks-Passo-a-Passo.md). Leia a “Visão geral das fases” do doc de tasks pleno (Fases A a G).
3. Escreva no seu arquivo: “Para evoluir a pleno, vou priorizar as fases: … (ex.: A ownership, C testes, D operação). Onde estão as tasks: pleno/02-Tasks-Passo-a-Passo.md.”

**Entregável:** Nota sobre próximos passos (Pleno) e onde estão as tasks.

**Critério de conclusão:** Você sabe que o próximo nível é pleno (ownership, desenho, testes, operação) e sabe onde está o passo a passo das tasks pleno.

---

## Resumo: do zero ao Júnior+

Você percorreu:

- **Fase 0:** Repo, ambiente, primeira leitura do guia.
- **Fase 1:** Glossário, Mapa, Perfil Júnior+.
- **Fase 2:** Visão do sistema (fluxo, contextos, checkpoint hot/cold e NATS).
- **Fases 3–9:** Sprints 1 a 8 com tasks de leitura, código, teste e critério de aceite.
- **Fase 10:** Hábitos (Mapa + Checklist) e próximo passo (Pleno).

Use este documento como lista de tarefas: marque cada task ao concluir e guarde os entregáveis (anotações, código, testes). Ao completar até a Fase 10, você terá saído do zero e estará em condições de atuar como **júnior+** neste projeto e seguir para a [trilha Pleno](./pleno/02-Tasks-Passo-a-Passo.md).
