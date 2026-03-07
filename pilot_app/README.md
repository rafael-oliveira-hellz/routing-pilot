# Pilot App

App Flutter do **Pilot**: roteamento, ETA em tempo real, ingestão GPS e incidentes crowdsourced, alinhado ao backend event-driven (NATS, Redis, PostGIS).

## Estrutura

- **`lib/core/`** — Config, tema, erros, utils (traceId), segurança, rede (a implementar por sprint)
- **`lib/features/`** — Módulos por feature: auth, route_planning, tracking, incidents (ver `features/README.md`)
- **`lib/app.dart`** — Root widget e (futuro) configuração de rotas
- **`docs/TODO-SPRINTS.md`** — **Checklist completo por sprint** com todas as features e boas práticas

## Como rodar

```bash
cd pilot_app
flutter pub get
flutter run
```

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

Este app consome as APIs e WebSockets do projeto **pilot** (backend Spring Boot). Certifique-se de que o backend está rodando e que a `baseUrl` em `lib/core/config/app_config.dart` (ou via env) aponta para o servidor correto.
