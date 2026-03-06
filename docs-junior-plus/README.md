# Guia Júnior → Júnior+ → Pleno

Documentação para **evoluir** no projeto: de **júnior** a **júnior+** (conceitos e prática) e de **júnior+** a **pleno** (ownership, desenho, qualidade, operação e impacto no time).

---

## Trilha Júnior → Júnior+

Para quem já programa em Java/Spring e quer entender **arquitetura event-driven**, **DDD** e **escala** com conceitos, mapa do projeto e trilha prática.

### Ordem ideal de leitura (Júnior+)

1. [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md) — ordem completa e **diferença entre 04 e 07**
2. [01 - Glossário](./01-Glossario-e-Conceitos.md) → [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) → [06 - Perfil Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md)
3. **Escolha um:** [04 - Trilha prática](./04-Trilha-Pratica-Junior-Plus.md) (resumida por Sprint) **ou** [07 - Tasks passo a passo](./07-Tasks-Passo-a-Passo-Junior-Plus.md) (do zero, tasks numeradas) — use só um como guia principal
4. [03 - Padrões](./03-Padroes-de-Codigo-Explicados.md) ao codar; [05 - FAQ](./05-FAQ-e-Armadilhas-Comuns.md) quando tiver dúvida

### O que você encontra aqui (júnior+)

| Documento | Conteúdo |
|-----------|----------|
| [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md) | **Comece aqui.** Ordem de leitura e quando usar 04 vs 07. |
| [01 - Glossário e conceitos](./01-Glossario-e-Conceitos.md) | Event-driven, bounded context, aggregate, NATS, hot/cold path, etc. |
| [02 - Mapa do projeto e docs](./02-Mapa-Do-Projeto-e-Docs.md) | Onde está cada doc, onde está cada parte do código |
| [03 - Padrões de código explicados](./03-Padroes-de-Codigo-Explicados.md) | Ports & adapters, records, policies, use cases com exemplos |
| [04 - Trilha prática Júnior+](./04-Trilha-Pratica-Junior-Plus.md) | Roteiro **resumido** por Sprint (checkpoints e exercícios). Use **04 ou 07**, não os dois. |
| [05 - FAQ e armadilhas comuns](./05-FAQ-e-Armadilhas-Comuns.md) | Perguntas frequentes e erros que devs júnior costumam cometer |
| [06 - Perfil e competências Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md) | O que caracteriza um júnior+; competências e onde praticar; Júnior vs Júnior+ |
| [07 - Tasks passo a passo (zero → Júnior+)](./07-Tasks-Passo-a-Passo-Junior-Plus.md) | **Do zero:** tasks numeradas (Fase 0–10), passos + entregáveis + critérios. Use **04 ou 07**, não os dois. |

---

## Trilha Júnior+ → Pleno

Versão separada para **evoluir até pleno**: ownership de feature, decisões de desenho, testes, operação, performance, refatoração e revisão de código. Tudo com **tasks passo a passo** e entregáveis claros.

| Documento | Conteúdo |
|-----------|----------|
| [Pleno - README](./pleno/README.md) | Índice da trilha pleno e como usar |
| [Pleno - Perfil e competências](./pleno/01-Perfil-e-Competencias-Pleno.md) | O que caracteriza um pleno; competências e evidências |
| [Pleno - Tasks passo a passo](./pleno/02-Tasks-Passo-a-Passo.md) | Todas as tarefas por fase (A a G) com passos, entregáveis e critérios de conclusão |

## Documentação principal (referência)

A documentação “oficial” do projeto fica em **`docs/`**. Ela é técnica e assume certa maturidade em arquitetura. Use este guia para **preparar o terreno** antes (ou em paralelo) à leitura dos docs em `docs/`.

- Índice geral: [`docs/README.md`](../docs/README.md)
- Ordem sugerida de implementação: por Sprints no README e no [Checklist](../docs/14-Checklist-Sprints.md).

## Objetivo do projeto (resumo)

- **Motor de roteamento e ETA em tempo real** para 1000+ veículos, cada um com até 1000+ pontos/rotas.
- **Stack**: Java 25, Spring Boot 4.x, NATS JetStream, PostgreSQL/PostGIS, Redis.
- **Arquitetura**: event-driven, serviços stateless, estado em PG + Redis, hot path (ETA) separado do cold path (recálculo de rota).

- **Júnior → Júnior+:** comece pelo [00 - Como usar este guia](./00-Como-Usar-Este-Guia.md) e pelo [01 - Glossário e conceitos](./01-Glossario-e-Conceitos.md).
- **Júnior+ → Pleno:** após a trilha júnior+, use o [Pleno - README](./pleno/README.md) e o [Pleno - Tasks passo a passo](./pleno/02-Tasks-Passo-a-Passo.md).
