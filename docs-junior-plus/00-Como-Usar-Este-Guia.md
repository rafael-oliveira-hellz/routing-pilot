# 00 - Como usar este guia

## Objetivo

Este guia **complementa** a documentação em `docs/`. Ele não substitui os documentos técnicos; ele ajuda você a **entendê-los** e a **navegar** no projeto com confiança.

---

## Ordem ideal de leitura (use esta sequência)

| # | Documento | Quando ler |
|---|-----------|------------|
| 1 | **00 - Como usar este guia** (este) | Primeiro — para saber a ordem e a diferença entre 04 e 07. |
| 2 | [01 - Glossário e conceitos](./01-Glossario-e-Conceitos.md) | Logo em seguida — para não se perder nos termos dos outros docs. |
| 3 | [02 - Mapa do projeto e docs](./02-Mapa-Do-Projeto-e-Docs.md) | Depois do Glossário — para saber onde está cada tema (docs e código). |
| 4 | [06 - Perfil e competências Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md) | Em seguida — para alinhar o que se espera de um júnior+ e onde praticar. |
| 5 | **Escolha um:** [04] ou [07] (veja abaixo) | Para a parte prática: ou trilha resumida (04) ou tasks detalhadas (07). |
| 6 | [03 - Padrões de código explicados](./03-Padroes-de-Codigo-Explicados.md) | Quando for abrir o código — ports, records, policies. |
| 7 | [05 - FAQ e armadilhas comuns](./05-FAQ-e-Armadilhas-Comuns.md) | Sempre que tiver dúvida ou errar algo — consulta. |

**Resumo da ordem:** 00 → 01 → 02 → 06 → **(04 ou 07)** → 03 quando for codar → 05 quando precisar.

---

## 04 ou 07? Qual usar na prática?

Os dois cobrem a mesma jornada (do zero ao Júnior+, por Sprints), mas em **formatos diferentes**. Use **só um** como guia principal da implementação para não duplicar esforço.

| Doc | Formato | Melhor para quem… |
|-----|---------|--------------------|
| **[04 - Trilha prática Júnior+](./04-Trilha-Pratica-Junior-Plus.md)** | Visão **resumida** por Sprint: checkboxes, exercícios e checkpoints em texto livre. | Quem já tem um pouco de contexto no projeto e prefere **menos estrutura**, só um “roteiro” por Sprint. |
| **[07 - Tasks passo a passo (zero → Júnior+)](./07-Tasks-Passo-a-Passo-Junior-Plus.md)** | **Tasks numeradas** (Fase 0 a 10), cada uma com passos 1–2–3, entregável e critério de conclusão. | Quem está **do zero** ou prefere **checklist bem definido** (passo a passo, entregável claro, critério para marcar “concluído”). |

**Recomendação:** Se você está começando **do absoluto zero** no projeto, siga o **07**. Se você já conhece o repo e quer só um roteiro por Sprint, use o **04**. Não precisa seguir os dois em paralelo — escolha um e use o outro só como referência extra se quiser.

---

## Ordem sugerida de estudo (detalhada)

1. **Leia primeiro** (nesta pasta `docs-junior-plus/`):
   - [01 - Glossário e conceitos](./01-Glossario-e-Conceitos.md) — para não se perder nos termos.
   - [02 - Mapa do projeto e docs](./02-Mapa-Do-Projeto-e-Docs.md) — para saber onde está cada coisa.
   - [06 - Perfil e competências Júnior+](./06-Perfil-e-Competencias-Junior-Plus.md) — para saber o que se espera de um júnior+ e onde praticar.

2. **Escolha 04 ou 07** (veja a tabela acima) e use como guia da implementação. Consulte o outro só se precisar de visão alternativa.

3. **Em paralelo ao código**:
   - [03 - Padrões de código explicados](./03-Padroes-de-Codigo-Explicados.md) — ao abrir o skeleton/ código.

4. **Durante a implementação**:
   - [05 - FAQ e armadilhas comuns](./05-FAQ-e-Armadilhas-Comuns.md) — quando tiver dúvidas ou errar algo.

## Como usar a documentação principal (`docs/`)

- Os docs em `docs/` estão **numerados** e organizados por **Sprint** (veja `docs/README.md`).
- Para cada Sprint, o [Checklist](../docs/14-Checklist-Sprints.md) lista o que implementar e quais docs ler.
- **Não tente ler todos os docs de uma vez.** Siga a ordem do README + Checklist e use o glossário quando encontrar um termo novo.

## Relação entre este guia e os docs

| Você quer… | Use |
|------------|-----|
| Entender o que é “event-driven” ou “bounded context” | [01 - Glossário](./01-Glossario-e-Conceitos.md) |
| Saber em qual doc está cada tema (rotas, ETA, incidentes…) | [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) |
| Entender por que usamos “ports” e “records” | [03 - Padrões](./03-Padroes-de-Codigo-Explicados.md) |
| Ter um passo a passo por Sprint (resumido) | [04 - Trilha prática](./04-Trilha-Pratica-Junior-Plus.md) — roteiro por Sprint. |
| Ter tasks numeradas do zero ao Júnior+ (completas) | [07 - Tasks passo a passo](./07-Tasks-Passo-a-Passo-Junior-Plus.md) — use **04 ou 07**, não os dois em paralelo. |
| Evitar erros comuns e tirar dúvidas rápidas | [05 - FAQ](./05-FAQ-e-Armadilhas-Comuns.md) |
| Padrão de mensagens de commit (commit semântico) | [08 - Padrão de commit](./08-Padrao-Commit-Semantico.md) |
| Detalhes de implementação (NATS, algoritmos, contratos) | `docs/` (ex.: 01, 02, 03, 11, 15) |

## Dica

Marque este README e o [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) como referência rápida. Volte a eles sempre que precisar lembrar “onde isso está” ou “o que esse termo significa”.
