# Cards (substitui JIRA)

Cada card é um arquivo Markdown com **história** e **subtasks**, um por atividade. Organizado por sprint.

## Estrutura e índice de cards

| Sprint   | Card      | Título |
|----------|-----------|--------|
| Sprint 1 | APP-1001  | Estrutura do projeto e configuração |
| Sprint 1 | APP-1002  | Domínio (value objects, enums, exceções, DTOs) |
| Sprint 1 | APP-1003  | Segurança e rede (storage, JWT, Dio, traceId) |
| Sprint 1 | APP-1004  | Auth — Cadastro e Login (telas, remember me, splash) |
| Sprint 1 | APP-1005  | Auth — Logout, Refresh, Forgot/Reset/Change password |
| Sprint 1 | APP-1006  | Auth — Revogar todas as outras sessões |
| Sprint 1 | APP-1007  | Roles (USER/ADMIN) e Admin — Lista de usuários |
| Sprint 1 | APP-1008  | Tema, acessibilidade e testes |
| Sprint 2 | APP-2001  | Route Planning — API e modelos |
| Sprint 2 | APP-2002  | Route Planning — UI (Nova rota, paradas, constraints) |
| Sprint 3 | APP-3001  | Mapa — integração, polyline e marcadores |
| Sprint 3 | APP-3002  | Rota otimizada e recálculo (UX) |
| Sprint 4 | APP-4001  | Ingestão GPS — coleta e API (batch de posições) |
| Sprint 4 | APP-4002  | WebSocket ETA e tela "Em rota" |
| Sprint 5 | APP-5001  | Estados do veículo e políticas (chegada, desvio, throttle) |
| Sprint 6 | APP-6001  | Incidentes — reportar e votar |
| Sprint 6 | APP-6002  | Incidentes — listar, WebSocket e integração com rota |
| Sprint 7 | APP-7001  | Offline — buffer local e reconexão |
| Sprint 7 | APP-7002  | Rate limit, retry e inatividade |
| Sprint 8 | APP-8001  | Observabilidade — traceId e logging |
| Sprint 8 | APP-8002  | Tratamento de erros global e segurança em produção |
| Sprint 8 | APP-8003  | Acessibilidade e performance (release) |

```
CARDS/
├── README.md
├── Sprint-1/   APP-1001 … APP-1008
├── Sprint-2/   APP-2001, APP-2002
├── Sprint-3/   APP-3001, APP-3002
├── Sprint-4/   APP-4001, APP-4002
├── Sprint-5/   APP-5001
├── Sprint-6/   APP-6001, APP-6002
├── Sprint-7/   APP-7001, APP-7002
└── Sprint-8/   APP-8001, APP-8002, APP-8003
```

## Workflow

1. **Escolher o card** em que vai atuar (ex.: `Sprint-1/APP-1004.md`).
2. **Criar/checkout da branch do card:**  
   `git checkout -b feature/APP-1004`  
   (ou usar a branch já existente, se tiver sido criada).
3. **Implementar** as subtasks do card; marcar no MD com `[x]` ao concluir.
4. **Commit/Push** na branch `feature/APP-1004`; abrir PR para `sprint-1-fundacao` (ou branch da sprint).

Branches por card: `feature/APP-XXXX` (ex.: `feature/APP-1004`). Para atuar em um card, use:  
`git checkout feature/APP-1004` (ou `git checkout -b feature/APP-1004` se a branch ainda não existir).

## Referência

- **TODO-SPRINTS.md** — checklist completo por sprint.
- **Backend:** `docs/14-Checklist-Sprints.md` no repositório raiz.
