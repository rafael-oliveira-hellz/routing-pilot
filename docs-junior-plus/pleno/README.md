# Trilha Júnior+ → Pleno

Versão do guia focada em evoluir um **júnior+** até **pleno**: ownership de funcionalidade ponta a ponta, decisões de desenho, qualidade, operação e impacto no time.

---

## Pré-requisito

Você já concluiu (ou domina) a [Trilha prática Júnior+](../04-Trilha-Pratica-Junior-Plus.md): entende event-driven, bounded contexts, ports/adapters, policies, e implementou pelo menos até a Sprint 4 (ingestão + ETA). Este material **complementa** essa base com competências de nível pleno.

---

## O que você encontra aqui

| Documento | Conteúdo |
|-----------|----------|
| [01 - Perfil e competências Pleno](./01-Perfil-e-Competencias-Pleno.md) | O que caracteriza um pleno neste projeto; competências e evidências |
| [02 - Tasks passo a passo](./02-Tasks-Passo-a-Passo.md) | Tarefas numeradas com passo a passo, entregáveis e critérios de conclusão |

---

## Como usar

1. Leia o [01 - Perfil e competências](./01-Perfil-e-Competencias-Pleno.md) para alinhar expectativas.
2. Siga o [02 - Tasks passo a passo](./02-Tasks-Passo-a-Passo.md) na ordem sugerida (ou conforme prioridade do time).
3. Cada bloco de tasks tem **entregável** e **critério de conclusão**. Marque como concluído só quando o critério for atendido.
4. Use os docs em `docs/` e o [Checklist Sprints](../../docs/14-Checklist-Sprints.md) como referência técnica; as tasks indicam qual doc consultar quando necessário.

---

## Visão geral das fases (Tasks)

| Fase | Foco | Tasks (exemplo) |
|------|------|------------------|
| **A** | Ownership de feature ponta a ponta | Escolher uma feature, desenhar fluxo, implementar e documentar |
| **B** | Decisões de desenho e trade-offs | ADR, limites do contexto, evolução de contrato |
| **C** | Qualidade e testes | Estratégia de testes, cobertura por camada, testes de integração com NATS/Redis |
| **D** | Operação e resolução de incidentes | Runbooks, métricas, alertas, post-mortem |
| **E** | Performance e capacidade | Benchmarks, gargalos, tuning (JVM, NATS, batch) |
| **F** | Refatoração e dívida técnica | Refatorar com segurança, extrair componente, manter compatibilidade |
| **G** | Revisão de código e mentoria | Checklist de review, dar feedback construtivo, documentar padrões |

Detalhes e passos concretos estão no [02 - Tasks passo a passo](./02-Tasks-Passo-a-Passo.md).
