# Camadas de persistência e ferramental (domain agnóstico, infra trocável)

## Objetivo

- **Domain**: entidades puras, sem JPA nem detalhe de banco; IDs em **UUID**.
- **Application** (e API): dependem apenas de **ports** (contratos em tipos de domínio ou em capacidades: publicar evento, dedup, rate limit, etc.).
- **Infrastructure**: implementa os ports (ex.: JPA/Postgres, NATS, Redis). Trocar tecnologia = criar só a **implementação concreta** do mesmo port (e mapper quando for persistência); domain e application não mudam.

## Estrutura

```
domain/
  entity/           <- entidades de domínio (records/classes, UUID, sem JPA)
    ExecutionEvent.java
    LivePosition.java

application/
  port/out/         <- contratos de persistência em tipos de domínio
    ExecutionEventStore.java
    LivePositionStore.java

infrastructure/
  persistence/
    entity/          <- entidades JPA (detalhe de implementação Postgres)
    repository/      <- Spring Data JPA (só usado pelos adapters)
    mapper/          <- Domain entity <-> JPA entity
    adapter/         <- implementam os ports; usam repository + mapper
```

## Padrão por entidade

1. **Domain**: criar `domain/entity/Xxx.java` (record com UUID id, sem anotações JPA).
2. **Port**: criar `application/port/out/XxxStore.java` com métodos que recebem/devolvem a entidade de domínio.
3. **Mapper**: criar `infrastructure/persistence/mapper/XxxMapper.java` com `toJpa(domain)` e `toDomain(jpa)`.
4. **Adapter**: criar `infrastructure/persistence/adapter/XxxStoreAdapter.java` que implementa o port, usa `XxxRepository` (JPA) e o mapper.

Assim, para mudar de Postgres para outro banco: basta criar o **mapper** e a **implementação concreta** que implementa o mesmo port (ex.: `MongoExecutionEventStoreAdapter`); domain e application permanecem iguais.

## IDs

Todas as entidades (domínio e JPA) usam **UUID** como identificador.

## Ferramental (NATS, Redis, etc.)

O mesmo padrão vale para mensageria, cache, dedup e rate limit: **application/API não dependem de NATS nem de Redis**, só dos ports.

| Port | Capacidade | Implementação atual | Para trocar |
|------|------------|----------------------|-------------|
| `EventPublisher` | Publicar eventos | `NatsEventPublisher` | Nova implementação do port (ex.: `KafkaEventPublisher`) |
| `DeadLetterPort` | Publicar em DLQ | `NatsDeadLetterPublisher` | Nova implementação (ex.: `KafkaDeadLetterPublisher`) |
| `VehicleStateStore` | Estado do veículo | `RedisVehicleStateStore` | Nova implementação (ex.: `MemcachedVehicleStateStore`) |
| `LocationDedupPort` | Dedup de posição | `RedisLocationDedup` | Nova implementação (ex.: `MemcachedLocationDedup`) |
| `RateLimitPort` | Rate limiting | `RedisRateLimitAdapter` (default); backend via `routing.rate-limit.backend` | Nova implementação (ex.: `MemcachedRateLimitAdapter`) + config |
| `IncidentQueryPort` | Consulta incidentes | (implementação pode usar cache Redis) | Nova implementação do port |

**Listeners (NATS → Kafka):** os listeners atuais (`NatsLocationListener`, etc.) subscrevem ao NATS e chamam os use cases. Para usar Kafka, crie **novos listeners** (ex.: `KafkaLocationListener`) que subscrevem ao Kafka e chamam os **mesmos** ports de entrada (`ProcessLocationUpdatePort`, etc.). Domain e application permanecem iguais.

Resumo: para trocar **NATS por Kafka** ou **Redis por Memcached**, basta criar o **mapper** (quando for persistência) e a **implementação concreta** do mesmo port; domain e application não mudam.

## Migrations

- `execution_event.execution_id` foi tornado opcional (V006) para permitir eventos de auditoria sem execução (ex.: signal lost).
