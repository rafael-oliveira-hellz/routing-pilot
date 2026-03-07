# Pilot App

App Flutter do **Pilot**: roteamento, ETA em tempo real, ingestão GPS e incidentes crowdsourced, alinhado ao backend event-driven (NATS, Redis, PostGIS).

## Estrutura de pastas

```
lib/
├── app.dart                 # Root widget, tema, rotas
├── main.dart                # Entry point
├── core/
│   ├── config/              # AppConfig, .env (BASE_URL, ENV)
│   ├── di/                  # GetIt (serviceLocator)
│   ├── domain/              # value_objects, enums, dto, domain.dart
│   ├── error/               # PilotException, AuthException, etc.
│   ├── l10n/                # Strings pt-BR / en (APP-1008)
│   ├── network/             # ApiClient (Dio), ErrorResponse
│   ├── router/              # go_router, páginas placeholder
│   ├── security/            # SecureTokenStorage, JwtParser, RememberMePrefs
│   ├── theme/               # AppTheme (Material 3 claro/escuro)
│   └── util/                # trace_id, validators
└── features/
    ├── admin/               # Lista usuários (admin-only)
    ├── auth/                # login, register, forgot/reset/change password, security
    ├── incidents/           # (Sprint 6+)
    ├── route_planning/      # (Sprint 2+)
    └── tracking/            # (Sprint 4+)
```

- **`docs/CARDS/`** — Cards por sprint (APP-1001…); **`docs/TODO-SPRINTS.md`** — checklist completo.

## Como rodar

```bash
cd pilot_app
flutter pub get
flutter run
```

### Mapa (OpenStreetMap)

O app usa **flutter_map** com tiles do **OpenStreetMap**: gratuito e **sem necessidade de chave de API**. Não é necessário configurar Google Maps.

### Variáveis de ambiente

| Variável   | Descrição                          | Exemplo (local)           |
|-----------|-------------------------------------|---------------------------|
| `ENV`     | Ambiente: local, dev, staging, prod | `local`                   |
| `BASE_URL`| URL do backend                      | `http://10.0.2.2:8080` (Android) ou `http://localhost:8080` (iOS/Chrome) |

Copie `.env.example` para `.env` e ajuste se necessário.

### Rodar localmente (backend na sua máquina)

1. **Crie o `.env`:** `cp .env.example .env`
2. Suba o backend (pilot) e execute: `flutter run` (emulador Android Studio ou dispositivo).
3. **iOS / Chrome:** no `.env` use `BASE_URL=http://localhost:8080`.

Se o `.env` não existir, o app usa `ENV=local` e `BASE_URL=http://10.0.2.2:8080` (emulador Android).

## Documento principal: TODO por sprint

O arquivo **`docs/TODO-SPRINTS.md`** contém:

- **8 sprints** alinhadas ao backend (docs 01–11 e 14)
- **Todas as features**: Route Planning, Optimization/Mapa, Ingestão GPS, WebSocket ETA, Policies, Incidentes, Offline/DLQ, Observabilidade
- **Funcionamento de cada feature** (APIs, eventos, UI, validações)
- **Boas práticas** de desenvolvimento mobile, performance e segurança
- **Critérios de aceite** por sprint
- **Tabela de referência** de endpoints e eventos

Recomendação: começar pela **Sprint 1** (fundação, auth, tema) e seguir a ordem do documento.

## Dependências (a adicionar por sprint)

O `pubspec.yaml` inclui comentários com os pacotes sugeridos para cada sprint (dio, flutter_secure_storage, go_router, geolocator, web_socket_channel, sqflite/hive, etc.). Adicione conforme for implementando.

## Testes

```bash
flutter test
```

## Backend

Este app consome as APIs e WebSockets do projeto **pilot** (backend Spring Boot). A URL da API é definida no `.env` (`BASE_URL`). Padrão local: `http://10.0.2.2:8080` (Android Studio/emulador). Para iOS ou Chrome: `http://localhost:8080`.
