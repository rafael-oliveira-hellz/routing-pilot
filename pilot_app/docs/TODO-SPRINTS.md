# Pilot App — TODO por Sprint

Checklist de implementação do app Flutter que contempla **todas as features do backend Pilot** (roteamento, ETA, ingestão GPS, incidentes crowdsourced, policies, observabilidade). Organizado por sprint, com foco em **boas práticas mobile**, **performance** e **segurança**.

---

## Visão geral das sprints

| Sprint | Foco | Duração sugerida |
|--------|------|------------------|
| Sprint 1 | Fundação: projeto, domínio, infra, auth, tema | 2 semanas |
| Sprint 2 | Route Planning: criar rota, paradas, constraints | 2 semanas |
| Sprint 3 | Mapa, rota otimizada e recálculo (UX) | 2 semanas |
| Sprint 4 | Ingestão GPS, tracking, ETA em tempo real, WebSocket | 2 semanas |
| Sprint 5 | Policies (chegada, desvio, throttle) + estados do veículo | 2 semanas |
| Sprint 6 | Incidentes crowdsourced (reportar, votar, listar, alertas) | 2 semanas |
| Sprint 7 | Offline, buffer local, DLQ/retry, inatividade | 2 semanas |
| Sprint 8 | Observabilidade, traceId, auditoria, hardening | 2 semanas |

---

## Sprint 1 — Fundação

**Objetivo:** Projeto Flutter estruturado, domínio compartilhado, infra base, autenticação e tema.

### Estrutura do projeto
- [ ] Estrutura de pastas: `lib/core/`, `lib/features/`, `lib/shared/`
- [ ] `core/`: `config/`, `di/`, `error/`, `network/`, `security/`, `theme/`, `utils/`
- [ ] `features/`: um módulo por feature (auth, route_planning, tracking, incidents, etc.)
- [ ] Por feature: `data/` (api, models, repositories), `domain/` (entities, repositories interfaces, use cases), `presentation/` (pages, widgets, bloc/cubit ou provider)
- [ ] Navegação: go_router ou auto_route com rotas nomeadas e deep links
- [ ] Injeção de dependência: get_it + injectable (ou provider) registrando APIs, repositórios, use cases

### Domínio (value objects e enums alinhados ao backend)
- [ ] Value objects: `GeoPoint`, `RegionTile` (fromGeoPoint), `EtaState`, `RouteProgress`, `VehicleState`, `TimeWindow`, `SegmentMetrics`, `Polyline`
- [ ] Enums: `IncidentType`, `IncidentSeverity`, `VehicleStatus`, `RouteType`, `Traffic`, `OptimizationStrategy`, `OptimizationStatus`, `VoteType`, `RecalcReason`, `ProcessingErrorCode`
- [ ] Exceções de domínio: `PilotException` base, `AuthException`, `NetworkException`, `ValidationException`
- [ ] Modelos DTO/request/response para APIs (RouteRequest, RoutePoint, RouteStop, RouteConstraint, etc.)

### Configuração e ambiente
- [ ] `flutter_dotenv` ou `--dart-define` para base URL, env (dev/staging/prod)
- [ ] Configuração de timeouts, retry e tamanho máximo de payload (100 KB) alinhada ao backend
- [ ] Constantes: intervalos de envio GPS (3–5 s movimento, 1 s curva, 10 s parado, 30 s heartbeat), batch max 10 posições ou 5 s

### Segurança
- [ ] Armazenamento seguro: `flutter_secure_storage` para tokens (access + refresh)
- [ ] JWT: parse de claims (`vehicleId`/`sub`, exp), refresh antes de expirar (ex.: 1 h)
- [ ] HTTPS obrigatório; certificate pinning (opcional, configurável por env)
- [ ] Não logar tokens nem dados sensíveis; obfuscar em builds release

### Rede
- [ ] Cliente HTTP: Dio com interceptors para: Auth (Bearer), X-Trace-Id, Content-Type, timeout
- [ ] Geração e propagação de `traceId` (UUID v4) em todas as requisições para o backend
- [ ] Tratamento de 401 (refresh ou logout), 429 (Retry-After), 503 (backoff)
- [ ] Tipagem de erros (ErrorResponse: timestamp, status, errorCode, message, path, traceId)

### Autenticação (feature auth) — fluxo completo

**Documentação dos fluxos (referência para implementar tudo):**

| Fluxo | Endpoint / ação | O que o app faz |
|-------|-----------------|-----------------|
| **Cadastro** | POST /api/v1/users | Tela de registro: email, senha, nome (e vehicleId se aplicável); validação client-side; após sucesso → login automático ou redirecionar para login |
| **Login** | POST /api/v1/auth/login (email, password, rememberMe) | Tela de login; checkbox "Lembrar de mim"; guardar accessToken + refreshToken em secure storage; se rememberMe, guardar flag ou token longo conforme backend; extrair user (id, email, vehicleId) |
| **Remember me** | Renovação com remember-me ou refresh ao abrir app | Splash/start: se não há access válido mas há refresh/remember válido, chamar refresh ou endpoint de renovação; obter novo access e ir para home; senão → tela de login |
| **Logout** | POST /api/v1/auth/logout (Bearer) | Botão "Sair"; chamar logout; limpar access, refresh e dados de user do secure storage; navegar para tela de login |
| **Revogar todas as outras sessões** | POST /api/v1/auth/revoke-all-other-sessions (Bearer); backend revoga outros dispositivos e retorna novo refreshToken para este | Tela Segurança/Sessões (Perfil ou Configurações): botão "Encerrar sessões em todos os outros dispositivos"; chamar API; se retornar novo refreshToken, atualizar no storage; mensagem "As outras sessões foram encerradas. Este aparelho continua logado." Caso de uso: celular perdido/roubado. |
| **Refresh token** | POST /api/v1/auth/refresh (body: refreshToken) | Interceptor Dio: em 401, tentar refresh; se 200, guardar novo access e reenviar request original; se 401 no refresh → logout e navegar para login |
| **Forgot password** | POST /api/v1/auth/forgot-password (email); POST /api/v1/auth/reset-password (token, newPassword) | Tela "Esqueci a senha": campo email → chamar forgot-password; tela "Nova senha" (deep link ou rota com token): campo nova senha → reset-password; feedback de sucesso/erro |
| **Change password** | POST /api/v1/auth/change-password (Bearer; currentPassword, newPassword) | Tela "Alterar senha" (dentro do app, logado): senha atual + nova senha + confirmação; chamar API; sucesso → mensagem e opcionalmente re-login ou apenas OK |

**Tarefas de implementação (Sprint 1):**

- [ ] **Cadastro:** Tela de registro (email, senha, confirmação de senha, nome); validação (email válido, senha forte, iguais); POST /api/v1/users; tratamento de erro (email já existe, etc.); após sucesso redirecionar para login ou fazer login automático
- [ ] **Login:** Tela de login (email, senha); checkbox "Lembrar de mim"; POST /api/v1/auth/login com body email, password, rememberMe; persistir accessToken, refreshToken (e user básico) em flutter_secure_storage; guardar preferência rememberMe (SharedPreferences ou no próprio storage)
- [ ] **Remember me:** Na abertura do app (splash): se accessToken expirado/inválido e refreshToken ou remember-me presente, chamar POST /api/v1/auth/refresh (ou endpoint de renovação) antes de redirecionar; se sucesso → home; se falha → tela de login
- [ ] **Logout:** Botão/logout no menu; POST /api/v1/auth/logout com Bearer; limpar secure storage (tokens + user); navegar para rota de login e limpar stack
- [ ] **Revogar todas as outras sessões (perda/roubo do celular):** Tela de Segurança ou Sessões (ex.: dentro de Perfil ou Configurações) com botão "Encerrar sessões em todos os outros dispositivos"; POST /api/v1/auth/revoke-all-other-sessions com Bearer; se a resposta trouxer novo refreshToken, atualizar no secure storage para que **este** aparelho continue logado; exibir mensagem de sucesso (ex.: "As outras sessões foram encerradas. Este aparelho continua logado."). Caso de uso: usuário perdeu ou foi roubado o celular e, a partir de outro dispositivo, encerra o acesso no aparelho perdido/roubado.
- [ ] **Refresh token:** Interceptor Dio: em resposta 401, interceptar; chamar POST /api/v1/auth/refresh com refreshToken; se 200, salvar novo accessToken e reenviar a requisição original; se 401/403 na refresh → limpar storage e redirecionar para login (evitar loop)
- [ ] **Forgot password:** Tela "Esqueci a senha" com campo email; POST /api/v1/auth/forgot-password; mensagem genérica de sucesso ("Se o email existir, você receberá instruções"); Tela "Redefinir senha" (rota com query param ou path token): campos nova senha + confirmação; POST /api/v1/auth/reset-password com token e newPassword; sucesso → redirecionar para login com mensagem
- [ ] **Change password:** Tela "Alterar senha" (ex.: dentro de perfil/configurações): senha atual, nova senha, confirmar nova senha; POST /api/v1/auth/change-password com Bearer e body currentPassword, newPassword; validação client-side (senhas iguais, tamanho); feedback de sucesso ou erro (senha atual incorreta)
- [ ] Tela de splash: verificar token válido (ou refresh) e redirecionar para home ou login conforme fluxo acima
- [ ] Claims: extrair e guardar userId, email, vehicleId, **role** (do user ou do JWT) para uso em locations, rotas e controle de UI (admin-only)
- [ ] **Roles no app:** dois papéis — `USER` e `ADMIN`. Modelo de user (e JWT) deve incluir `role` (enum ou string: "USER", "ADMIN"). Admin = dono da aplicação; apenas admin vê telas e ações admin-only.
- [ ] **Admin-only (Flutter):** exibir telas/ações de administração somente quando `user.role == ADMIN`. Usuário comum (USER) não vê menu "Administração"; em 403 em rota admin, redirecionar ou mostrar "Sem permissão".
- [ ] **Tela Admin — Lista de usuários:** (visível só para ADMIN) GET /api/v1/users; listar usuários (id, email, name, role, active); opção de desativar/remover (DELETE /api/v1/users/{id}) com confirmação; não permitir remover a si mesmo ou último admin (conforme regra do backend).
- [ ] **Demais features admin-only:** futuras telas (auditoria global, DLQ, métricas) só acessíveis quando role == ADMIN; guardar role no estado global (auth state) para esconder/mostrar rotas e itens de menu.
- [ ] Documentar no código ou em README da feature auth os endpoints e fluxos (link para esta tabela) para não esquecer nenhum passo

### Tema e acessibilidade
- [ ] Tema claro/escuro (Material 3), cores primárias e superfícies
- [ ] Tipografia escalável (text scaling), contraste mínimo (WCAG)
- [ ] Suporte a localização (i18n): pt-BR como padrão, estrutura para en

### Testes e qualidade
- [ ] `flutter_test` + unit tests para value objects e validadores
- [ ] CI: análise estática (flutter analyze), testes (flutter test)
- [ ] README do app: como rodar, variáveis de ambiente, estrutura de pastas

**Critério de aceite:** App abre, faz login (mock ou real), navega para home; todas as requisições saem com traceId e Bearer; tema e estrutura prontos para próximas features.

---

## Sprint 2 — Route Planning

**Objetivo:** Criar solicitação de rota (origem, destino, até 1000 paradas, constraints) via API.

### API Route Requests
- [ ] Modelos: `RouteRequest`, `RoutePoint` (origem/destino), `RouteStop` (paradas com sequence_order), `RouteConstraint` (max_vehicle_count, max_duration_s, max_distance_m, avoid_tolls, avoid_tunnels)
- [ ] Validação no app: exatamente 2 points (1 origem, 1 destino); máximo 1000 stops; `departure_at >= created_at`; coordenadas dentro de lat/lon válidos
- [ ] POST ` /api/v1/route-requests`: body com points, stops, constraints, departure_at; enviar traceId no header
- [ ] Resposta: id da route_request, status (ex.: CREATED); tratar 4xx com mensagem de validação

### UI Route Planning
- [ ] Tela “Nova rota”: seleção de origem e destino (busca por endereço ou mapa)
- [ ] Adicionar paradas (até 1000), reordenar por arrastar; cada parada com endereço/coordenada
- [ ] Constraints opcionais: evitar pedágio, túneis, duração máxima, distância máxima
- [ ] Data/hora de partida (opcional); validação de >= agora
- [ ] Botão “Calcular rota”: validar no client, chamar API, navegar para tela de resultado ou mapa
- [ ] Loading e tratamento de erro (ex.: “Máximo de 1000 paradas excedido”)

### Persistência local (opcional)
- [ ] Cache da última route_request criada (SharedPreferences ou Hive) para retomar ou reenviar
- [ ] Histórico de requests (lista simples) para reutilizar origem/destino

**Critério de aceite:** Usuário informa origem, destino e N paradas; validação client-side; POST com 100 paradas retorna sucesso; evento RouteOptimizationRequested é disparado no backend (validável no backend).

---

## Sprint 3 — Mapa, rota otimizada e recálculo (UX)

**Objetivo:** Exibir rota otimizada no mapa, polyline e waypoints; solicitar recálculo quando o backend indicar ou o usuário mudar destino.

### Mapa
- [ ] Integração com mapa (google_maps_flutter ou mapbox): exibir polyline da rota (path_geometry)
- [ ] Marcadores: origem, destino, paradas na ordem; clustering se muitos pontos
- [ ] Atualizar vista do mapa ao receber nova rota (RouteRecalculatedEvent ou GET de rota)
- [ ] Permissões de localização para “minha posição” e futuro tracking

### Dados da rota otimizada
- [ ] Modelos: `RouteResult`, `RouteSegment`, `RouteWaypoint`, `OptimizationRun`; polyline como lista de GeoPoint
- [ ] Obter resultado: polling GET ou resposta após WebSocket/evento (conforme contrato backend)
- [ ] Exibir totais: distância total, duração estimada, número de waypoints
- [ ] Estados: LOADING, OPTIMIZED, RECALCULATING, FAILED (OptimizationFailedEvent)

### Recálculo (UX)
- [ ] Botão “Recalcular rota” que envia RecalculateRouteRequested (reason: MANUAL ou STRATEGIC_REOPTIMIZATION)
- [ ] Quando backend enviar recálculo (desvio, incidente): mostrar indicador “Recalculando…” e atualizar rota quando RouteRecalculatedEvent chegar
- [ ] Exibir motivo quando disponível (ROUTE_DEVIATION, INCIDENT_CRITICAL, etc.)

### Performance
- [ ] Polyline simplificada no mapa se muitos pontos (Douglas–Peucker ou limite de pontos renderizados)
- [ ] Não bloquear UI ao desenhar rota longa (isolate ou debounce de atualização)

**Critério de aceite:** Rota de 100+ pontos exibida no mapa; usuário pode solicitar recálculo; estado RECALCULATING e nova rota refletidos na UI.

---

## Sprint 4 — Ingestão GPS, tracking e ETA em tempo real

**Objetivo:** Enviar posições em batch (POST /api/v1/locations), receber ETA atualizado via WebSocket e exibir em tempo real.

### Coleta de posição
- [ ] `geolocator` (ou similar): posição com lat, lon, speed (m/s), heading, accuracy
- [ ] Garantir envio de **speedMps** em cada posição (obrigatório para ETA no backend)
- [ ] Frequência adaptativa: movimento normal 3–5 s; curva/desvio 1 s; parado (speed < 1 m/s) 10 s; sem movimento > 2 min 30 s (heartbeat)
- [ ] Batching: acumular até 10 posições ou 5 s (o que vier primeiro); cada posição com `occurredAt` (timestamp do GPS)

### API de ingestão
- [ ] POST `/api/v1/locations`: body `vehicleId`, `routeId`, `routeVersion`, `positions[]` (lat, lon, speedMps, heading, accuracyMeters, occurredAt)
- [ ] Header: Authorization Bearer, X-Trace-Id
- [ ] Resposta: `accepted`, `duplicates`, `rejected`; tratar 202, 429 (Retry-After), 401
- [ ] vehicleId do JWT; rejeitar no client se vehicleId do body != claim (evitar engano)

### WebSocket ETA
- [ ] Conexão WebSocket ao endpoint de ETA (ex.: `/ws/eta` ou conforme backend); autenticação (token ou query)
- [ ] Receber eventos EtaUpdatedEvent: remainingSeconds, confidence, degraded, distanceRemainingMeters
- [ ] Atualizar UI: countdown (ETA), barra de progresso ou distância restante; indicador “degraded” quando aplicável
- [ ] Reconexão com backoff em caso de queda; re-subscribe por vehicleId/routeId se necessário

### UI tracking
- [ ] Tela “Em rota”: mapa com rota + posição atual em tempo real
- [ ] Card/topo com ETA (ex.: “Chegada em 12 min”), confiança e estado (normal / degradado)
- [ ] Atualização contínua da posição no mapa e do ETA sem travar a UI
- [ ] Indicador de “enviando posições” (opcional) para debug

**Critério de aceite:** 10 posições enviadas em batch; ETA recebido via WebSocket e exibido; alteração de posição reflete no ETA (backend processando LocationUpdatedEvent).

---

## Sprint 5 — Policies e estados do veículo

**Objetivo:** Refletir no app as políticas do backend: chegada ao destino, desvio, throttle de recálculo, estados (IN_PROGRESS, DEGRADED_ESTIMATE, RECALCULATING, ARRIVED, STOPPED, FAILED).

### Estados do veículo
- [ ] Enum/local state: IN_PROGRESS, DEGRADED_ESTIMATE, RECALCULATING, ARRIVED, STOPPED, FAILED
- [ ] Atualizar estado a partir de eventos: EtaUpdatedEvent (degraded), RouteRecalculatedEvent (IN_PROGRESS), DestinationReachedEvent (ARRIVED), EtaDegradedEvent (DEGRADED_ESTIMATE), SignalLostEvent / SignalRecoveredEvent
- [ ] UI por estado: “Em rota”, “Sinal fraco – ETA aproximado”, “Recalculando rota”, “Você chegou”, “Veículo parado”, “Rota interrompida”

### Chegada ao destino
- [ ] Quando backend enviar ARRIVED / DestinationReachedEvent: remainingSeconds = 0, tela de “Chegada confirmada” e opção de finalizar
- [ ] Parar envio de posições quando status = ARRIVED (ou conforme regra de negócio)

### Desvio e recálculo
- [ ] Exibir mensagem quando recálculo for por desvio (ROUTE_DEVIATION): “Saiu da rota. Recalculando…”
- [ ] Respeitar throttle no client: não disparar múltiplos “Recalcular” em sequência (ex.: desabilitar botão por 30 s ou 2/min conforme backend)

### Indicadores de qualidade
- [ ] Exibir “ETA degradado” quando degraded = true ou estado DEGRADED_ESTIMATE
- [ ] Exibir confiança do ETA (ex.: “Alta / Média / Baixa”) com base em confidence
- [ ] FinalizeRouteUseCase no backend: app pode chamar endpoint de finalização se existir (marca ARRIVED, zera ETA)

**Critério de aceite:** Estados do veículo refletidos na UI; chegada ao destino mostra tela de conclusão; mensagens de desvio e ETA degradado corretas.

---

## Sprint 6 — Incidentes crowdsourced

**Objetivo:** Reportar incidentes, votar (CONFIRM/DENY/GONE), listar incidentes próximos e receber alertas em tempo real.

### Reportar incidente
- [ ] POST `/api/v1/incidents`: body lat, lon, incidentType, severity (opcional), description (opcional), reportedBy (userId/deviceId)
- [ ] Tipos: BLITZ, ACCIDENT, HEAVY_TRAFFIC, WET_ROAD, FLOOD, ROAD_WORK, BROKEN_TRAFFIC_LIGHT, ANIMAL_ON_ROAD, VEHICLE_STOPPED, LANDSLIDE, FOG, OTHER
- [ ] Severidade: LOW, MEDIUM, HIGH, CRITICAL (default por tipo conforme backend)
- [ ] UI: tela “Reportar incidente” com mapa (pin na posição), seletor de tipo e severidade, campo descrição
- [ ] Rate limit no client: máx 5 reports/min por usuário (evitar spam)
- [ ] Resposta: incidentId (UUID) retornado pelo backend (não confundir com eventId)

### Votar em incidente
- [ ] POST `/api/v1/incidents/{id}/vote`: body voteType (CONFIRM, DENY, GONE)
- [ ] UI: em cada card de incidente, botões “Confirmar”, “Negar”, “Já passou”
- [ ] Um voto por usuário por incidente (backend valida)

### Listar incidentes
- [ ] GET `/api/v1/incidents?lat=&lon=&radius=` (raio em metros)
- [ ] Exibir no mapa como marcadores diferenciados (ícone por tipo ou severidade)
- [ ] Lista em painel: tipo, severidade, distância, tempo restante (expiresAt)
- [ ] Filtros opcionais: tipo, severidade, raio

### WebSocket incidentes
- [ ] Conexão ao endpoint de incidentes (ex.: `/ws/incidents`)
- [ ] Receber INCIDENT_ALERT (IncidentActivatedEvent): atualizar mapa e lista em tempo real
- [ ] Tratar IncidentExpiredEvent para remover ou marcar incidente como inativo na UI

### Integração com rota
- [ ] Mostrar na rota se há incidentes no trecho (cor ou ícone no segmento)
- [ ] Notificação push ou in-app: “Incidente no seu trajeto: acidente a 500 m” (se backend enviar)

**Critério de aceite:** Reportar incidente → retorna incidentId; votar CONFIRM/DENY/GONE; listar por lat/lon/radius; alertas via WebSocket atualizam mapa/lista.

---

## Sprint 7 — Offline, buffer e resiliência

**Objetivo:** Buffer local de posições quando offline, envio em batch ao reconectar, tratamento de 429/DLQ e inatividade.

### Buffer offline
- [ ] Persistência local: SQLite (sqflite) ou Hive com modelo PositionRecord (lat, lon, speedMps, heading, accuracyMeters, occurredAt, routeId, routeVersion, vehicleId)
- [ ] Ao coletar posição: se online, enviar no batch normal; se offline, inserir no buffer
- [ ] Limite de buffer: 10.000 posições (~3 h a 1/s); ao atingir 90%, remover mais antigas (FIFO)
- [ ] Ordenação por occurredAt ASC para envio

### Reconexão
- [ ] Detectar reconexão (connectivity_plus ou similar)
- [ ] Ao ficar online: enviar posições buffered em batches de 50, intervalo 200 ms entre batches
- [ ] Incluir vehicleId, routeId, routeVersion em cada batch; occurredAt em cada posição
- [ ] Remover do buffer apenas após 202 Accepted (ou tratar duplicatas no backend)
- [ ] Indicador na UI: “Enviando dados salvos offline” e quantidade restante

### Rate limit e retry
- [ ] Em 429: ler header Retry-After; aguardar e reenviar (ex.: mesma batch)
- [ ] Backoff exponencial em erros 5xx ou falha de rede (max tentativas configurável)
- [ ] Não reenviar indefinidamente: após N falhas, manter no buffer e notificar usuário (opcional)

### Inatividade (sinal perdido, parado, abandonado)
- [ ] Exibir estado “Sinal perdido” quando backend enviar DEGRADED_ESTIMATE / SignalLostEvent
- [ ] Exibir “Veículo parado” quando STOPPED; “Rota abandonada” quando FAILED (InactivityDetectorJob no backend)
- [ ] Opção “Tentar novamente” para reenviar última posição ou reestabelecer tracking

**Critério de aceite:** Sem internet: posições vão para o buffer; ao reconectar, batches de 50 enviados com intervalo; 429 tratado com Retry-After; estados de inatividade exibidos.

---

## Sprint 8 — Observabilidade, traceId e hardening

**Objetivo:** Rastreio ponta a ponta (traceId), logs seguros, preparação para produção e segurança.

### TraceId
- [ ] Gerar traceId (UUID v4) no app para cada “sessão” de envio (ex.: batch de locations) ou por requisição crítica
- [ ] Enviar em todas as requisições HTTP: header X-Trace-Id
- [ ] Guardar traceId atual em memória (ou logging) para correlacionar com erros
- [ ] Em telas de erro, exibir “Código: {traceId}” para suporte rastrear no backend (execution_event, DLQ)

### Logging
- [ ] Não logar tokens, senhas nem posições em produção
- [ ] Em debug: logs úteis (traceId, vehicleId, status da requisição, duração)
- [ ] Encoder JSON para logs estruturados (opcional), alinhado ao backend (traceId, vehicleId, decision, processingMs)

### Tratamento de erros global
- [ ] GlobalExceptionHandler ou Zone: capturar erros não tratados e enviar para serviço de crash (ex.: Firebase Crashlytics) com traceId e contexto seguro
- [ ] Tela de erro genérica: “Algo deu errado. Código: {traceId}” e opção de reenviar/copiar
- [ ] ErrorResponse do backend: exibir message e errorCode na UI quando disponível

### Segurança em produção
- [ ] ProGuard/R8 (Android) e stripping (iOS): ofuscar código e remover logs desnecessários
- [ ] Revisar permissões: só as necessárias (localização, rede)
- [ ] Não armazenar senha em texto claro; apenas tokens em secure storage
- [ ] Certificate pinning em prod (opcional), configurável

### Acessibilidade e performance
- [ ] Semântica correta (Semantics) para leitores de tela
- [ ] Listas longas: ListView.builder / lazy loading; evitar rebuilds desnecessários (const, keys)
- [ ] Imagens e assets: compressão e resolução adequada
- [ ] Testes de integração (opcional): fluxo login → criar rota → enviar posição → receber ETA

**Critério de aceite:** Qualquer erro rastreável por traceId no backend; logs sem dados sensíveis; app estável e preparado para release.

---

## Resumo de APIs e contratos (referência)

### Auth e usuários (Sprint 1)

**Roles:** `USER` (usuário normal) e `ADMIN` (dono da aplicação). Resposta de login e JWT incluem `role`. Só ADMIN pode listar/remover usuários e acessar áreas admin.

| Método | Endpoint | Uso | Quem |
|--------|----------|-----|------|
| POST | `/api/v1/users` | Cadastro (email, password, name; opcional vehicleId); role = USER | Público |
| GET | `/api/v1/users/me` | Usuário logado (Bearer); resposta inclui role | Qualquer logado |
| GET | `/api/v1/users` | Listar todos os usuários | **Admin-only** |
| GET | `/api/v1/users/{id}` | Usuário por id (próprio ou qualquer se admin) | Próprio ou Admin |
| PUT | `/api/v1/users/{id}` | Atualizar usuário (próprio ou outro se admin) | Próprio ou Admin |
| DELETE | `/api/v1/users/{id}` | Desativar/remover usuário | **Admin-only** |
| POST | `/api/v1/auth/login` | Login (body: email, password, rememberMe); resposta com user.role | Público |
| POST | `/api/v1/auth/logout` | Logout (Bearer); revoga só esta sessão | Qualquer logado |
| POST | `/api/v1/auth/revoke-all-other-sessions` | Revogar todas as outras sessões (Bearer); retorna novo refreshToken para este dispositivo; uso: perda/roubo do celular | Qualquer logado |
| POST | `/api/v1/auth/refresh` | Refresh token (body: refreshToken) | Qualquer logado |
| POST | `/api/v1/auth/forgot-password` | Esqueci senha (body: email) | Público |
| POST | `/api/v1/auth/reset-password` | Redefinir senha (body: token, newPassword) | Público |
| POST | `/api/v1/auth/change-password` | Trocar senha logado (Bearer; body: currentPassword, newPassword) | Qualquer logado |

**No app:** guardar `role` no user salvo localmente; mostrar menu/telas "Administração" / "Usuários" apenas se `role == ADMIN`; tratar 403 em chamadas admin com mensagem "Sem permissão".

### Rotas, locations e incidentes

| Método | Endpoint | Uso |
|--------|----------|-----|
| POST | `/api/v1/route-requests` | Criar rota (points, stops, constraints) |
| POST | `/api/v1/locations` | Batch de posições (vehicleId, routeId, routeVersion, positions[]) |
| GET | `/api/v1/incidents?lat=&lon=&radius=` | Listar incidentes próximos |
| POST | `/api/v1/incidents` | Reportar incidente |
| POST | `/api/v1/incidents/{id}/vote` | Votar (CONFIRM, DENY, GONE) |
| WebSocket | ETA (ex.: `/ws/eta`) | Receber EtaUpdatedEvent |
| WebSocket | Incidentes (ex.: `/ws/incidents`) | Receber INCIDENT_ALERT |

**Headers:** `Authorization: Bearer <JWT>`, `X-Trace-Id: <UUID>`, `Content-Type: application/json`.

**Eventos (recebidos):** EtaUpdatedEvent, RouteRecalculatedEvent, DestinationReachedEvent, EtaDegradedEvent, SignalLostEvent, SignalRecoveredEvent, IncidentActivatedEvent, IncidentExpiredEvent.

---

## Boas práticas gerais

- **Performance:** Batching de posições; frequência adaptativa de GPS; lazy loading em listas; evitar rebuilds desnecessários.
- **Segurança:** JWT em secure storage; HTTPS; traceId sem dados sensíveis; ofuscação em release.
- **Resiliência:** Buffer offline; retry com backoff; tratamento de 429/503; reconexão WebSocket.
- **UX:** Estados claros (IN_PROGRESS, RECALCULATING, ARRIVED, DEGRADED); feedback de envio offline; mensagens de erro amigáveis com código (traceId) para suporte.

Documento alinhado aos docs do backend: 01–11, 14 (Checklist Sprints) e contratos de eventos (doc 11).
