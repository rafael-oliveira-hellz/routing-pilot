# 02 - Tasks passo a passo (Júnior+ → Pleno)

Tarefas numeradas com **passo a passo**, **entregável** e **critério de conclusão**. Marque cada item ao concluir.

---

## Fase A – Ownership de feature ponta a ponta

### Task A.1 – Escolher e delimitar uma feature

**Objetivo:** Assumir uma feature de ponta a ponta (do contrato ao deploy).

**Passos:**

1. Com o time ou mentor, escolha uma feature do backlog que atravesse pelo menos 2 bounded contexts (ex.: “Notificar cliente quando ETA degradar” → ExecutionMonitoring + notificação).
2. Liste os **docs** que a cobrem (use o [Mapa do projeto](../02-Mapa-Do-Projeto-e-Docs.md)).
3. Escreva em 1 parágrafo: **entrada** (evento/API), **regras**, **saída** (evento/API/WebSocket) e **critério de aceite** em uma frase.
4. Registre isso em um arquivo `docs-junior-plus/pleno/features/<nome-da-feature>.md` (ou no formato que o time usar).

**Entregável:** Documento da feature com escopo, fluxo e critério de aceite.

**Critério de conclusão:** Outra pessoa consegue entender o que será entregue só lendo o documento.

---

### Task A.2 – Desenhar o fluxo ponta a ponta

**Objetivo:** Deixar explícito o fluxo de dados e os contratos.

**Passos:**

1. Desenhe um diagrama (ASCII ou ferramenta) do fluxo: **origem** → **eventos/APIs** → **serviços/use cases** → **persistência/publicação** → **destino**.
2. Para cada fronteira (entre serviços ou entre camadas), indique o **contrato** (nome do evento ou endpoint + payload mínimo). Use o [doc 11 - Contratos](../../docs/11-Contratos-Eventos-Estado.md) como referência.
3. Marque onde há **estado** (Redis, PG) e onde há **idempotência/dedup**.
4. Inclua o diagrama no mesmo doc da Task A.1 ou em anexo.

**Entregável:** Diagrama de fluxo + tabela de contratos nas fronteiras.

**Critério de conclusão:** Um desenvolvedor consegue implementar a feature seguindo o desenho sem ambiguidade.

---

### Task A.3 – Implementar a feature (backend)

**Objetivo:** Implementar a feature respeitando ports/adapters, policies e contratos.

**Passos:**

1. Crie/atualize **value objects e eventos** necessários (domain). Mantenha compatibilidade com o [doc 11](../../docs/11-Contratos-Eventos-Estado.md) se tocar em eventos existentes.
2. Implemente ou estenda **use case(s)** e **ports** (application). Não injete infra direto no use case.
3. Implemente ou estenda **adapters** (NATS, Redis, JPA) em infrastructure.
4. Exponha **API/WebSocket** se fizer parte da feature (api).
5. Adicione **métricas** relevantes (ex.: contador de notificação enviada, timer de processamento). Use o [doc 13](../../docs/13-Operacao-SLO-Runbooks.md) como referência de nomes.
6. Rode o checklist do Sprint correspondente para itens que sua feature cobre e marque o que foi feito.

**Entregável:** Código da feature (PR ou branch) com testes (ver Fase C) e métricas.

**Critério de conclusão:** A feature atende ao critério de aceite definido na Task A.1; build e testes passam.

---

### Task A.4 – Documentar e entregar

**Objetivo:** Deixar a feature documentada e rastreável.

**Passos:**

1. Atualize o doc da feature (A.1) com: **como testar manualmente** (ex.: request de exemplo, evento de exemplo) e **onde ver o resultado** (log, WebSocket, tabela).
2. Se criou novo evento ou mudou contrato, atualize ou aponte para o **doc 11** (ou documento de contratos do time).
3. Descreva em 2–3 linhas no PR (ou no doc) **o que foi feito** e **qual critério de aceite** a entrega atende.
4. Confirme que a feature está coberta por pelo menos um teste de integração ou E2E que valide o critério de aceite (ver Task C.2).

**Entregável:** Doc atualizado + PR com descrição e link para critério de aceite.

**Critério de conclusão:** Revisor consegue validar a entrega usando o doc e os testes.

---

## Fase B – Decisões de desenho e trade-offs

### Task B.1 – Escrever um ADR (Architecture Decision Record)

**Objetivo:** Documentar uma decisão de arquitetura com contexto e consequências.

**Passos:**

1. Escolha uma decisão real que você ou o time tomaram (ex.: “usar Redis para dedup de localização com TTL 2 min”, “throttle de recálculo 30 s / 2 por minuto”).
2. Crie um arquivo `docs-junior-plus/pleno/adr/ADR-XXX-titulo-curto.md` (ou na pasta que o time usar para ADRs).
3. Preencha: **Contexto**, **Decisão**, **Alternativas consideradas**, **Consequências** (positivas e negativas).
4. Indique **status** (aceito/obsoleto/supersedido por ADR-YYY).

**Entregável:** ADR completo e legível.

**Critério de conclusão:** Alguém que não participou da decisão entende o porquê e as consequências.

---

### Task B.2 – Delimitar um bounded context (ou evolução)

**Objetivo:** Justificar por que uma regra ou entidade pertence a um contexto (ou a um novo).

**Passos:**

1. Pegue uma regra ou agregado do projeto (ex.: “quorum de incidente”, “RouteRequest”).
2. Escreva em meio parágrafo: **por que** essa regra/agregado está no contexto X e não em Y. Use o [doc 02 - Modelo de domínio](../../docs/02-Modelo-Dominio-Bounded-Contexts.md).
3. Se a discussão for “deveríamos mover ou criar contexto?”, documente **prós e contras** em uma página e proponha uma decisão (pode virar ADR).

**Entregável:** Texto curto (ou ADR) com justificativa de fronteira de contexto.

**Critério de conclusão:** Fica claro onde a regra vive e por quê.

---

### Task B.3 – Evoluir um contrato sem quebrar consumidores

**Objetivo:** Adicionar campo ou novo evento sem quebrar quem já consome.

**Passos:**

1. Escolha um evento ou payload de API que precise evoluir (ex.: adicionar campo `confidence` em `EtaUpdatedEvent`).
2. Verifique no [doc 11](../../docs/11-Contratos-Eventos-Estado.md) o schema atual.
3. Proponha a mudança: **retrocompatível** (campo opcional, valor default) ou **nova versão** (novo subject ou novo endpoint). Documente em 1 página.
4. Se implementar: faça a alteração e garanta que consumidores antigos continuem funcionando (campo opcional ou novo subject). Atualize o doc 11 (ou equivalente).

**Entregável:** Proposta de evolução + implementação (se aplicável) + doc atualizado.

**Critério de conclusão:** Nenhum consumidor existente quebra; novo comportamento documentado.

---

## Fase C – Qualidade e testes

### Task C.1 – Estratégia de testes por camada

**Objetivo:** Definir o que testar em cada camada (domain, application, infrastructure, api).

**Passos:**

1. Liste as camadas do projeto (domain, application, engine, infrastructure, api) — use o [doc 15 - Skeleton](../../docs/15-Skeleton-Java.md).
2. Para cada camada, escreva: **tipo de teste** (unitário vs integração), **o que mockar** (ex.: ports em use case), **exemplo de um teste** que você considera representativo (nome da classe/cenário).
3. Coloque isso em `docs-junior-plus/pleno/test-strategy.md` (ou no repo do time).

**Entregável:** Documento de estratégia de testes por camada com exemplos.

**Critério de conclusão:** Um júnior consegue seguir o documento para decidir onde e como testar uma nova alteração.

---

### Task C.2 – Teste que garante critério de aceite

**Objetivo:** Escrever um teste (integração ou E2E) que valide explicitamente um critério de aceite de uma feature ou Sprint.

**Passos:**

1. Escolha um critério de aceite do [Checklist Sprints](../../docs/14-Checklist-Sprints.md) (ex.: Sprint 4: “Simular 10 veículos enviando batch de posições via API, ETA atualizado, pushado via WebSocket, execution_event auditável por traceId”).
2. Escreva um teste de integração (ou E2E) que: **arrange** (dados e ambiente), **act** (chamada API ou publicação de evento), **assert** (verificar ETA, evento, registro em `execution_event` por traceId). Use Testcontainers para NATS/Redis/PostgreSQL se necessário.
3. Documente no próprio teste (comentário ou docstring) qual critério de aceite ele cobre.
4. Rode o teste e garanta que está verde.

**Entregável:** Classe de teste + comentário ligando ao critério de aceite.

**Critério de conclusão:** O teste falha se o comportamento esperado for removido ou quebrado.

---

### Task C.3 – Cobertura mínima em um use case

**Objetivo:** Garantir que um use case tenha testes unitários cobrindo caminhos feliz, erro e edge cases.

**Passos:**

1. Escolha um use case (ex.: `ProcessLocationUpdateUseCase` ou `CreateRouteRequestUseCase`).
2. Liste **3–5 cenários**: caminho feliz, 1–2 erros (ex.: estado não encontrado, validação falha), 1 edge (ex.: routeVersion obsoleto).
3. Implemente testes unitários para cada cenário, mockando os ports.
4. Rode cobertura (JaCoCo ou ferramenta do projeto) e anote a cobertura desse use case antes/depois. Meta: pelo menos 80% de linha no use case (ou o padrão do time).

**Entregável:** Testes unitários do use case + número de cobertura.

**Critério de conclusão:** Todos os cenários listados estão cobertos; cobertura atinge a meta combinada.

---

## Fase D – Operação e resolução de incidentes

### Task D.1 – Executar um runbook de ponta a ponta

**Objetivo:** Simular um incidente e seguir o runbook até a “resolução”.

**Passos:**

1. Escolha um runbook do [doc 13 - Runbooks](../../docs/13-Operacao-SLO-Runbooks.md) (ex.: RB-01 Pico de recálculo, RB-03 Consumer lag).
2. Em ambiente de dev/staging (ou simulado): **reproduza o sintoma** (ex.: aumentar recálculos artificialmente, ou gerar lag no consumer).
3. Siga o runbook passo a passo: verificar config, métricas, ações sugeridas.
4. Documente em 1 página: **o que fez**, **o que observou** (métricas antes/depois), **o que ajustou**. Se algo do runbook estiver desatualizado, proponha alteração no doc 13.

**Entregável:** Relato da execução do runbook + eventual patch no doc 13.

**Critério de conclusão:** Você consegue explicar a um colega como executar esse runbook em um incidente real.

---

### Task D.2 – Propor uma métrica ou alerta

**Objetivo:** Adicionar uma métrica ou alerta que ajude a detectar ou diagnosticar um problema.

**Passos:**

1. Escolha um problema que já aconteceu ou pode acontecer (ex.: “muitos eventos indo para DLQ”, “circuit breaker abrindo sem aviso”).
2. Defina uma **métrica** (counter, gauge ou timer) ou um **alerta** (condição sobre métrica existente). Use a tabela de métricas do [doc 13](../../docs/13-Operacao-SLO-Runbooks.md) como referência.
3. Implemente a métrica no código (Micrometer) ou escreva a regra de alerta (ex.: Prometheus/Alertmanager) em um arquivo de config ou doc.
4. Documente: **nome da métrica/alerta**, **o que significa**, **ação sugerida** (link para runbook se houver).

**Entregável:** Código da métrica ou arquivo de alerta + documentação.

**Critério de conclusão:** A métrica aparece no Prometheus ou o alerta está configurado e documentado.

---

### Task D.3 – Escrever um post-mortem (template)

**Objetivo:** Preencher um post-mortem após um incidente (real ou simulado).

**Passos:**

1. Use um incidente real do projeto ou simule um (ex.: “recálculos em pico por 10 min, ETA atrasou”).
2. Preencha um template de post-mortem: **resumo**, **timeline**, **causa raiz**, **impacto**, **ações de mitigação**, **ações de follow-up** (evitar repetição).
3. Salve em `docs-junior-plus/pleno/postmortems/` (ou pasta do time) com data e título curto.
4. Se possível, vincule uma ação de follow-up a uma task ou melhoria no runbook/doc 13.

**Entregável:** Documento de post-mortem preenchido.

**Critério de conclusão:** O time consegue usar o documento para aprender e evitar repetição.

---

## Fase E – Performance e capacidade

### Task E.1 – Rodar um benchmark e registrar baseline

**Objetivo:** Estabelecer um benchmark reproduzível para um fluxo crítico.

**Passos:**

1. Escolha um fluxo (ex.: “processar 1000 LocationUpdatedEvent em sequência”, “otimizar rota com 500 pontos”).
2. Defina **carga** (número de eventos/pontos, número de veículos), **ambiente** (local/docker, recursos) e **métrica** (latência p95, throughput, tempo total).
3. Implemente um script ou teste de carga (ex.: JMeter, k6, ou código Java que publica eventos e mede tempo). Rode 3 vezes e anote média e desvio.
4. Documente em `docs-junior-plus/pleno/benchmarks/baseline-<nome>.md`: objetivo, ambiente, resultado, como reproduzir.

**Entregável:** Script ou procedimento de benchmark + documento de baseline.

**Critério de conclusão:** Outra pessoa consegue reproduzir o benchmark e obter resultados na mesma ordem de grandeza.

---

### Task E.2 – Identificar um gargalo e propor tuning

**Objetivo:** Medir, identificar gargalo e aplicar um ajuste com critério.

**Passos:**

1. Com base no benchmark (E.1) ou em métricas existentes, escolha um **gargalo** (ex.: tempo no GraphHopper, GC pause, lock no Redis).
2. Use profiler (JFR, JProfiler) ou métricas (Prometheus, logs) para **confirmar** que esse é o gargalo.
3. Proponha **uma** mudança de tuning (ex.: aumentar pool de threads, ajustar tamanho de batch, habilitar ZGC). Documente em 1 página: hipótese, mudança, como medir de novo.
4. Aplique a mudança, rode o benchmark novamente e registre antes/depois. Se não houver melhoria, documente e reverta se necessário.

**Entregável:** Relato do gargalo + proposta de tuning + resultado antes/depois (e patch de config se aplicável).

**Critério de conclusão:** Há evidência numérica da melhoria (ou conclusão de que o tuning não ajudou).

---

## Fase F – Refatoração e dívida técnica

### Task F.1 – Refatorar um trecho com testes de segurança

**Objetivo:** Melhorar estrutura ou legibilidade sem quebrar comportamento.

**Passos:**

1. Escolha um trecho de código com dívida (ex.: método muito longo, duplicação, nome confuso). Priorize algo que você já testou (Fase C) ou que tenha testes existentes.
2. Liste o que vai mudar (extrair método, renomear, mover classe) e **garanta** que há testes cobrindo o comportamento atual.
3. Faça a refatoração em passos pequenos: rode os testes após cada passo.
4. No PR, descreva **o que mudou** e **por que**; confirme que nenhum contrato (API, evento) foi alterado.

**Entregável:** PR de refatoração + testes verdes.

**Critério de conclusão:** Comportamento inalterado (testes passam); código mais legível ou mais fácil de evoluir.

---

### Task F.2 – Extrair um componente reutilizável

**Objetivo:** Extrair lógica repetida ou complexa para um componente com interface clara.

**Passos:**

1. Identifique lógica duplicada ou complexa em 2+ lugares (ex.: cálculo de distância ao corredor, formatação de payload para WebSocket).
2. Defina a **interface** do novo componente (método público, parâmetros, retorno) e onde ele vive (domain, engine ou infrastructure).
3. Extraia para uma classe/componente; substitua as chamadas antigas pela nova interface. Mantenha contratos e testes.
4. Documente em 1 parágrafo: **o que o componente faz**, **quando usar**, **exemplo de uso**.

**Entregável:** Novo componente + uso nos pontos antigos + documentação curta.

**Critério de conclusão:** Duplicação removida; componente testado e documentado.

---

## Fase G – Revisão de código e mentoria

### Task G.1 – Checklist de revisão de PR

**Objetivo:** Ter um checklist consistente para revisar PRs.

**Passos:**

1. Crie um arquivo `docs-junior-plus/pleno/code-review-checklist.md` com uma lista de itens que você verifica em todo PR (ex.: “domain não depende de infra”, “eventos seguem doc 11”, “traceId propagado”, “testes para caminho feliz e pelo menos um erro”, “sem catch genérico”).
2. Use o checklist em pelo menos **2 PRs** (próprios ou de colega) e anote o que faltou em cada um.
3. Ajuste o checklist com base no que você encontrou (adicionar ou remover itens).
4. Proponha ao time adotar o checklist (ou merge com o que já existir).

**Entregável:** Documento do checklist + evidência de uso em 2 PRs.

**Critério de conclusão:** O checklist cobre os pontos críticos do projeto (contratos, camadas, testes, erros).

---

### Task G.2 – Dar feedback construtivo em um PR

**Objetivo:** Revisar um PR e dar feedback que ajude o autor a evoluir.

**Passos:**

1. Pegue um PR de um júnior ou júnior+ (ou um PR seu revisado por outro).
2. Na revisão: para cada comentário, **classifique** se é: bug, violação de padrão, sugestão de melhoria, ou dúvida. Escreva o comentário de forma **clara e objetiva** (o que está errado, por que importa, sugestão de como corrigir).
3. Inclua pelo menos **um** comentário positivo (o que está bom).
4. Ao final, escreva um **resumo** em 2–3 linhas: principais pontos a ajustar e um reforço positivo.

**Entregável:** Revisão feita com comentários classificados e resumo.

**Critério de conclusão:** O autor do PR consegue entender o que mudar e por quê, sem se sentir só criticado.

---

### Task G.3 – Documentar um padrão do projeto

**Objetivo:** Deixar explícito um padrão que juniores costumam errar ou não conhecer.

**Passos:**

1. Escolha um padrão (ex.: “sempre validar routeVersion antes de processar evento”, “novos eventos devem ter JSON Schema no doc 11”, “políticas não acessam repositório direto”).
2. Escreva em 1 página: **nome do padrão**, **regra**, **exemplo correto**, **anti-exemplo** (o que evitar), **onde está no código/docs**.
3. Salve em `docs-junior-plus/pleno/padroes/<nome-do-padrao>.md` (ou na pasta de padrões do time).
4. Compartilhe com o time (ex.: no README do pleno ou no onboarding).

**Entregável:** Documento do padrão com exemplo e anti-exemplo.

**Critério de conclusão:** Um júnior consegue seguir o padrão após ler o documento.

---

## Resumo das entregas por fase

| Fase | Entregas principais |
|------|----------------------|
| A | Doc da feature + diagrama + código + doc atualizado + PR |
| B | ADR + texto de contexto + evolução de contrato (e doc) |
| C | Estratégia de testes + teste de critério de aceite + testes do use case |
| D | Relato de runbook + métrica/alerta + post-mortem |
| E | Baseline de benchmark + análise de gargalo + tuning |
| F | PR de refatoração + componente extraído e documentado |
| G | Checklist de review + revisão com feedback + doc de padrão |

Use este documento como lista de tarefas: marque cada task ao concluir e guarde os entregáveis no repositório ou na pasta indicada. Ao completar as fases A, B, C e D (e pelo menos uma de E, F, G), você terá evidências sólidas de perfil pleno neste projeto.
