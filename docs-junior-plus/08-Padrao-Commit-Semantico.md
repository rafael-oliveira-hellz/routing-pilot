# 08 - Padrão de commit e commit semântico

## Objetivo

Padronizar mensagens de commit neste repositório para facilitar histórico legível, changelog automático e revisão de código. Usamos **Conventional Commits** (commit semântico).

---

## Formato básico

```text
<tipo>(<escopo opcional>): <descrição curta>

[corpo opcional]

[rodapé opcional]
```

- **tipo**: o que mudou (feat, fix, docs, refactor, etc.).
- **escopo**: parte do projeto afetada (ex.: skeleton, pilot, docs).
- **descrição**: em imperativo, sem ponto no final; ~50 caracteres na primeira linha.

---

## Tipos principais

| Tipo       | Uso |
|-----------|------|
| **feat**  | Nova funcionalidade ou capacidade. |
| **fix**   | Correção de bug (comportamento ou build). |
| **docs**  | Só documentação (README, docs/, comentários de doc). |
| **refactor** | Refatoração sem mudar comportamento visível. |
| **test**  | Adição ou alteração de testes. |
| **chore** | Tarefas de construção, CI, dependências, config (ex.: pom, gradle, compose). |
| **style** | Formatação, espaços, aspas; sem mudança de lógica. |
| **perf**  | Melhoria de performance. |

---

## Escopo (opcional)

Use quando ajudar a filtrar no histórico:

- **skeleton** – código em `skeleton/`
- **pilot** – código em `pilot/`
- **docs** – pasta `docs/`
- **docs-junior-plus** – pasta `docs-junior-plus/`
- **checklist** – `docs/14-Checklist-Sprints.md`
- Nome do módulo/camada (ex.: **rate-limit**, **flyway**)

---

## Exemplos

```text
feat(skeleton): add RedisRateLimitAdapter and routing.rate-limit.backend
```

```text
fix(pilot): use GraphHopper 9.1 and remove graphhopper-reader-osm
```

```text
docs(docs-junior-plus): add semantic commit guide (08)
```

```text
refactor(skeleton): make rate limit port agnostic (Redis adapter in infrastructure/redis)
```

```text
docs(checklist): Sprint 1 - [E] AwsConfig/GraphHopperConfig, [M] pom deps
```

```text
chore(pilot): align application name and package comment in application.yaml
```

---

## Boas práticas

1. **Imperativo:** “add feature” e não “added feature” ou “adds feature”.
2. **Primeira linha curta:** idealmente ≤ 72 caracteres; detalhes no corpo.
3. **Um conceito por commit:** evite “fix X and add Y and update Z” em um só commit; se fizer sentido, divida.
4. **Corpo opcional:** use para explicar *por quê* ou *como*, quebras incompatíveis, refs a issues.

Exemplo com corpo:

```text
fix(pilot): set graphhopper.version to 9.1

graphhopper-reader-osm 9.1 does not exist on Maven Central (only up to 3.0-pre3).
Use only graphhopper-core 9.1 for routing.
```

---

## Referência rápida

- [Conventional Commits](https://www.conventionalcommits.org/)
- Changelog automático: ferramentas como **standard-version**, **semantic-release** usam esse padrão.
