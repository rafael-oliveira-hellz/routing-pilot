# 05 - FAQ e armadilhas comuns

Perguntas frequentes e erros que devs júnior costumam cometer neste projeto — e como evitar.

---

## FAQ

### Onde começo a implementar?

Pelo **Sprint 1** do [Checklist](../docs/14-Checklist-Sprints.md): projeto, domínio (value objects, enums), infra (PostgreSQL, Redis, NATS), Docker. Depois Sprint 2 (RoutePlanning), e assim por diante. Não pule Sprints; a base de domínio e eventos é usada em tudo.

### Posso chamar o repositório JPA direto no use case?

Não. O use case deve depender de **ports** (interfaces). Quem implementa a interface é o adapter (repositório JPA). Assim você testa o use case com mocks e mantém a regra de “núcleo não conhece infra”.

### O evento tem que ser igual ao JSON Schema do doc 11?

Sim. Os consumidores e o replay/auditoria esperam os campos descritos no [11 - Contratos](../docs/11-Contratos-Eventos-Estado.md). Alterar contrato exige versão ou novo subject/stream para não quebrar consumidores antigos.

### Por que tanto “por vehicleId” nos subjects NATS?

Para **ordem**: todas as mensagens de um mesmo veículo vão no mesmo subject, então o JetStream entrega em ordem. E para **particionamento**: você pode escalar consumidores e cada partição (vehicleId) ser tratada por uma instância.

### ETA: por que não recalcular a rota a cada posição?

Porque recálculo é **pesado** (segundos) e a maioria das posições só precisa de um **ajuste incremental** do tempo (hot path, &lt; 100 ms). Recálculo só quando policy diz: desvio, incidente crítico, mudança de destino, etc.

### O que fazer quando um teste que usa NATS/Redis falha na CI?

Use **testcontainers** ou perfis de teste com instâncias em memória/embedded. Não dependa de NATS/Redis rodando na máquina do CI. O Checklist e o doc 15 mencionam testes de integração; configure um perfil `test` com conexões para containers.

---

## Armadilhas comuns

### 1. Validar no controller em vez de no domínio

**Erro:** Colocar validação “máximo 1000 stops” só no controller ou no DTO.  
**Certo:** Validação de regra de negócio no **domain** (ex.: `RouteRequestValidator`) ou no aggregate. Controller só chama o use case; se alguém chamar o use case por outro canal (NATS, outro API), a regra continua valendo.

### 2. Ignorar `routeVersion` nos eventos

**Erro:** Processar evento de rota sem checar `routeVersion`; assim você pode aplicar atualização de uma rota antiga por cima da nova.  
**Certo:** Comparar com o estado atual do veículo; se `event.routeVersion` &lt; estado atual, **descartar** o evento (obsoleto).

### 3. `occurredAt` no futuro ou fora de ordem

**Erro:** Aceitar qualquer `occurredAt` e processar.  
**Certo:** Rejeitar ou ignorar evento com `occurredAt` no futuro. Para ordem: se `occurredAt` &lt; último processado para aquele veículo, descartar (consistência monotônica).

### 4. Recálculo sem throttle

**Erro:** Disparar recálculo a cada desvio detectado.  
**Certo:** Usar **RecalculationThrottlePolicy**: intervalo mínimo (ex.: 30 s) e limite por minuto (ex.: 2). Caso contrário, um GPS instável gera pico de recálculos e sobrecarga no cold path.

### 5. Esquecer dedup na ingestão de localização

**Erro:** Inserir toda posição que chega. Em reconexão, o cliente reenvia batch e você duplica posições.  
**Certo:** Dedup por `(vehicleId, occurredAt)` com janela (ex.: 2 min) em Redis; posição já vista → contar como “duplicate” e não reprocessar.

### 6. Catch genérico e perder contexto

**Erro:** `catch (Exception e) { log.error("erro"); }` — perde tipo, traceId e não envia para DLQ.  
**Certo:** Exceções específicas (DomainException, RateLimitExceededException, etc.) e handler global que loga com traceId e publica na DLQ quando for falha de processamento de evento.

### 7. Confundir “origem/destino” com “stops”

**Erro:** Tratar origem e destino como “mais dois stops”.  
**Certo:** No modelo (doc 02 e 03), há **2 points** (origem + destino) e até **1000 stops** (paradas intermediárias). Validação e índices são diferentes; a otimização considera origem → stops em ordem → destino.

### 8. Não propagar traceId

**Erro:** Gerar novo UUID em cada serviço. Na auditoria você não consegue seguir o mesmo request do mobile até o WebSocket.  
**Certo:** Receber `traceId` no header (ou no evento), colocar no MDC e repassar em logs e em eventos downstream. Assim um único ID liga toda a cadeia.

---

## Resumo

- Comece pelo Checklist Sprint 1 e não pule a base.
- Use **ports** no use case; não injete JPA/NATS direto no núcleo.
- Respeite **contratos** de eventos (doc 11) e **routeVersion** / **occurredAt**.
- Use **throttle** em recálculo e **dedup** na ingestão de posição.
- Valide no **domínio**; use **exceções nomeadas** e **traceId** em toda a cadeia.

Se tiver mais dúvidas, consulte o [02 - Mapa](./02-Mapa-Do-Projeto-e-Docs.md) para achar o doc certo e o [01 - Glossário](./01-Glossario-e-Conceitos.md) para os termos.
