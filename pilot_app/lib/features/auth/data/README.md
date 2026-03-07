# auth/data

API client, DTOs, repositórios concretos da feature auth. APP-1004, APP-1005.

## Endpoints e fluxos (Sprint 1)

Referência: `docs/14-Checklist-Sprints.md` / TODO-SPRINTS — tabela de endpoints.

| Método | Endpoint | Bearer | Uso |
|--------|----------|--------|-----|
| POST | `/api/v1/users` | Não | Cadastro (register). |
| POST | `/api/v1/auth/login` | Não | Login (email, password, rememberMe). |
| POST | `/api/v1/auth/refresh` | Não | Renovar access/refresh token (body: refreshToken). Usado no splash e no interceptor em 401. |
| POST | `/api/v1/auth/logout` | Sim | Logout; em seguida limpar storage e ir para login. |
| POST | `/api/v1/auth/forgot-password` | Não | Esqueci a senha (body: email). Mensagem genérica de sucesso. |
| POST | `/api/v1/auth/reset-password` | Não | Redefinir senha (body: token, newPassword). Rota: `/reset-password?token=...`. |
| POST | `/api/v1/auth/change-password` | Sim | Alterar senha logado (body: currentPassword, newPassword). |
| POST | `/api/v1/auth/revoke-all-other-sessions` | Sim | Revoga todas as outras sessões; resposta pode trazer novo refreshToken (e accessToken) para manter este aparelho logado. |
| GET | `/api/v1/users` | Sim (ADMIN) | Lista usuários (admin-only). 403 → Sem permissão. |
| DELETE | `/api/v1/users/{id}` | Sim (ADMIN) | Remove/desativa usuário (admin-only). Backend pode impedir remover último admin ou a si mesmo. |

**Caso de uso (revoke-all-other-sessions):** usuário perdeu ou foi roubado o celular; a partir de outro dispositivo (ex.: computador) faz login e aciona "Encerrar sessões em todos os outros dispositivos". O backend invalida os refresh tokens dos outros aparelhos e pode devolver um novo refreshToken para o dispositivo atual; o app atualiza o storage e exibe mensagem de sucesso.

Fluxos: login → tokens + user em secure storage; 401 → interceptor tenta refresh, se falhar logout e redirecionar; logout → POST logout + clear storage + go login.