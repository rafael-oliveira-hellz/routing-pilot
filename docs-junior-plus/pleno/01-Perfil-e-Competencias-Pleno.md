# 01 - Perfil e competências Pleno

O que se espera de um **desenvolvedor pleno** neste projeto e como as tasks da trilha mapeiam para essas competências.

---

## Definição de Pleno (neste projeto)

Um pleno **entrega funcionalidade completa** (da especificação ao deploy e monitoramento), **toma decisões de desenho** dentro do escopo do time, **garante qualidade** com testes e revisão, e **reage a incidentes** usando runbooks e métricas. Pode **apoiar juniores** com revisão de código e explicação de padrões.

---

## Competências e evidências

| Competência | O que se espera | Onde você pratica (tasks) |
|-------------|------------------|---------------------------|
| **Ownership ponta a ponta** | Responsabilizar-se por uma feature desde o doc/contrato até deploy, testes e observabilidade. | Fase A |
| **Desenho e trade-offs** | Propor e documentar decisões (ADR), respeitar bounded contexts, evoluir contratos sem quebrar consumidores. | Fase B |
| **Qualidade e testes** | Definir estratégia de testes por camada (unit, integração, contrato), escrever testes que garantam critérios de aceite. | Fase C |
| **Operação** | Usar runbooks, métricas e alertas; participar de resolução de incidente e, se aplicável, post-mortem. | Fase D |
| **Performance e capacidade** | Medir gargalos (benchmark, profiling), propor e aplicar tuning (JVM, batch, particionamento). | Fase E |
| **Refatoração** | Melhorar código e estrutura com segurança (testes, compatibilidade de contrato). | Fase F |
| **Revisão e mentoria** | Revisar PRs com checklist consistente, dar feedback claro e construtivo, documentar padrões para o time. | Fase G |

---

## Nível Júnior+ vs Pleno (resumo)

| Aspecto | Júnior+ | Pleno |
|---------|---------|--------|
| Escopo | Implementa tarefas bem definidas dentro de um fluxo já desenhado. | Assume uma feature inteira (ou epic) e garante entrega completa. |
| Decisões | Segue padrões e docs; pergunta quando há dúvida. | Propõe e documenta decisões (ex.: ADR) dentro do escopo do time. |
| Testes | Escreve testes unitários para o que implementa. | Define onde testar (unit vs integração), garante critérios de aceite via testes. |
| Operação | Conhece runbooks e onde estão as métricas. | Usa runbooks em incidente real; sugere melhorias em alertas/runbooks. |
| Performance | Entende hot/cold path e throttle. | Mede, identifica gargalo e aplica tuning com critério. |
| Código alheio | Lê e segue o que existe. | Refatora com segurança e revisa código de outros com checklist. |

---

## Ordem sugerida das fases

- **Primeiro:** Fase A (ownership) e C (testes) — para consolidar “entregar feature completa com qualidade”.
- **Em seguida:** B (desenho) e D (operação) — decisões e resposta a incidentes.
- **Depois:** E (performance), F (refatoração) e G (revisão/mentoria) — conforme demanda do projeto e do time.

As tasks no [02 - Tasks passo a passo](./02-Tasks-Passo-a-Passo.md) estão numeradas para você marcar progresso e evidenciar cada competência.
