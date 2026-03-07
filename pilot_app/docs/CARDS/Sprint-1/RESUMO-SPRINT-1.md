# Resumo — Sprint 1 (Pilot App)

Sprint de fundação: estrutura, domínio, segurança, auth completa, roles, tema e qualidade.

---

## Visão geral

| Card      | Tema                          | Entregas principais |
|-----------|-------------------------------|----------------------|
| APP-1001  | Estrutura e configuração      | Pastas core/features/shared, go_router, get_it, flutter_dotenv, AppConfig (env, timeouts, GPS) |
| APP-1002  | Domínio                       | Value objects, enums, exceções, DTOs (auth + route) |
| APP-1003  | Segurança e rede              | Secure storage, JWT parse, Dio + interceptors, traceId, 401/429/503, ErrorResponse |
| APP-1004  | Auth — Cadastro e login       | Telas registro/login, splash, remember me, persistência de tokens e user |
| APP-1005  | Auth — Logout e senhas        | Logout POST, refresh em 401, forgot/reset/change password, README auth |
| APP-1006  | Revogar outras sessões       | Tela Segurança, revoke-all-other-sessions, novo refreshToken no storage |
| APP-1007  | Roles e admin                 | USER/ADMIN, 403 “Sem permissão”, tela lista usuários (GET/DELETE), menu admin-only |
| APP-1008  | Tema e testes                 | Material 3 claro/escuro, i18n pt-BR+en, validators, unit tests, CI, README |

---

## Estrutura de pastas (após Sprint 1)

```
lib/
├── app.dart, main.dart
├── core/
│   ├── config/       AppConfig, .env (BASE_URL, ENV)
│   ├── di/           serviceLocator (GetIt)
│   ├── domain/       value_objects, enums, dto, domain.dart
│   ├── error/        PilotException, AuthException, NetworkException, ValidationException
│   ├── l10n/         AppStrings (pt-BR, en)
│   ├── network/      ApiClient (Dio), ErrorResponse
│   ├── router/       go_router, splash, home, login, register, security, admin, etc.
│   ├── security/     SecureTokenStorage, JwtParser, RememberMePrefs
│   ├── theme/        AppTheme (Material 3 light/dark)
│   └── util/         trace_id, validators
└── features/
    ├── admin/        Lista usuários (AdminRepository, AdminUsersPage)
    └── auth/         Login, register, forgot/reset/change password, security (AuthRepository, telas)
```

---

## Autenticação e segurança

- **Fluxo:** Splash → verifica token / refresh → Home ou Login. Login/Register persistem tokens e user em secure storage; logout faz POST e limpa storage.
- **Interceptor 401:** Tenta refresh (tryRefreshAndSave); se sucesso, reenvia a requisição; se falha, logout e rejeita.
- **Endpoints usados:** POST login, refresh, logout, register (users), forgot-password, reset-password, change-password, revoke-all-other-sessions; GET/DELETE users (admin).
- **Roles:** USER e ADMIN; menu e tela admin só para `user.isAdmin`; 403 → “Sem permissão”.

---

## Qualidade e operação

- **Testes:** Unit tests para GeoPoint, TimeWindow, validators (email, senha forte); widget test (app inicia e mostra splash).
- **CI:** `.github/workflows/flutter.yml` — `flutter analyze` e `flutter test` em push/PR para main e develop.
- **README:** Como rodar, variáveis de ambiente (ENV, BASE_URL), estrutura de pastas, referência a docs.

---

## Branches e referências

- Cada card tem branch `feature/APP-XXXX` (ex.: `feature/APP-1008`).
- Cards em `docs/CARDS/Sprint-1/APP-1001.md` … `APP-1008.md`.
- Checklist geral: `docs/TODO-SPRINTS.md`.
- Auth (endpoints e fluxos): `lib/features/auth/data/README.md`.
