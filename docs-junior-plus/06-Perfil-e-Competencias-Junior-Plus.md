# 06 - Perfil e competências Júnior+

O que se espera de um **desenvolvedor júnior+** neste projeto e onde cada competência é trabalhada na trilha e nos docs.

---

## Definição de Júnior+ (neste projeto)

Um júnior+ **implementa tarefas bem definidas** dentro de um fluxo já desenhado, **segue os padrões e a documentação** do projeto (event-driven, ports/adapters, policies), **escreve testes unitários** para o que implementa e **sabe onde está cada coisa** (docs, código, contratos). Consegue **ler e seguir** o que existe e **perguntar com contexto** quando há dúvida. É a base para evoluir para pleno (ownership de feature, decisões de desenho, operação).

---

## Competências e onde praticar


| Competência                          | O que se espera                                                                                                          | Onde você pratica                                                                                             |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **Leitura de documentação e código** | Encontrar no [Mapa](./02-Mapa-Do-Projeto-e-Docs.md) o doc e a camada certos; seguir um fluxo do controller até o evento. | [04 - Trilha prática](./04-Trilha-Pratica-Junior-Plus.md) (cada Sprint: “No código: localizar…”, “achar…”)    |
| **Conceitos de arquitetura**         | Explicar event-driven, bounded context, aggregate, value object, hot/cold path, throttle, DLQ, traceId.                  | [01 - Glossário](./01-Glossario-e-Conceitos.md) + checkpoints da [Trilha](./04-Trilha-Pratica-Junior-Plus.md) |
| **Respeito a padrões**               | Implementar usando ports/adapters, records para VOs e eventos, policies injetadas; não validar só no controller.         | [03 - Padrões](./03-Padroes-de-Codigo-Explicados.md) + [05 - FAQ/armadilhas](./05-FAQ-e-Armadilhas-Comuns.md) |
| **Contratos e invariantes**          | Seguir o [doc 11](../docs/11-Contratos-Eventos-Estado.md) para eventos; respeitar routeVersion, occurredAt, dedup.       | Trilha Sprints 2, 4, 5; [05 - Armadilhas](./05-FAQ-e-Armadilhas-Comuns.md)                                    |
| **Testes unitários**                 | Cobrir validações (ex.: RouteRequestValidator), cenários feliz/erro em use case com mocks.                               | Trilha Sprints 2, 5; [Checklist](../docs/14-Checklist-Sprints.md) por Sprint                                  |
| **Operação básica**                  | Conhecer runbooks e métricas do [doc 13](../docs/13-Operacao-SLO-Runbooks.md); explicar um runbook para um colega.       | Trilha Sprint 7/8; [04 - Checkpoint](./04-Trilha-Pratica-Junior-Plus.md) final                                |
| **Autonomia em tarefas**             | Com uma tarefa do Checklist, ler o doc indicado, implementar e marcar critério de aceite.                                | [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) + [Checklist](../docs/14-Checklist-Sprints.md) + Trilha           |


---

## Júnior vs Júnior+ (resumo)


| Aspecto       | Júnior                                      | Júnior+                                                                           |
| ------------- | ------------------------------------------- | --------------------------------------------------------------------------------- |
| Docs e código | Precisa de indicação clara de onde olhar.   | Sabe usar o Mapa e o Checklist para achar doc e camada.                           |
| Conceitos     | Ouviu falar de event-driven/DDD.            | Explica hot/cold path, throttle, bounded context, aggregate.                      |
| Implementação | Implementa com orientação passo a passo.    | Segue padrões (ports, records, policies) e evita armadilhas comuns.               |
| Contratos     | Pode ignorar routeVersion/occurredAt/dedup. | Respeita contratos (doc 11) e invariantes.                                        |
| Testes        | Escreve teste quando pedido.                | Escreve testes unitários para validações e cenários principais do que implementa. |
| Operação      | Não conhece runbooks.                       | Sabe onde estão runbooks e métricas e consegue explicar um.                       |


---

## Próximo passo: Pleno

Quando você estiver estável como júnior+ (trilha concluída até Sprint 6–8 e checkpoints atendidos), o próximo nível é **pleno**: ownership de feature ponta a ponta, decisões de desenho (ADR), estratégia de testes, operação em incidente real, performance e revisão de código.

- Perfil e competências pleno: [pleno/01-Perfil-e-Competencias-Pleno.md](./pleno/01-Perfil-e-Competencias-Pleno.md)
- Tasks passo a passo pleno: [pleno/02-Tasks-Passo-a-Passo.md](./pleno/02-Tasks-Passo-a-Passo.md)

