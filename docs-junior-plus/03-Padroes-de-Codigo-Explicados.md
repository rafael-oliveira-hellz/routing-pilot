# 03 - Padrões de código explicados

Padrões usados no projeto explicados de forma objetiva, com foco em **por que** e **como** aplicá-los como júnior+.

---

## 1. Ports e Adapters (Hexagonal)

### Ideia

O **domínio** e os **casos de uso** não dependem de detalhes de infraestrutura (NATS, Redis, PostgreSQL). Eles dependem apenas de **interfaces** (ports). Quem implementa essas interfaces são os **adapters** (NATS, Redis, JPA).

### Exemplo no projeto

**Port (entrada)** — o que o caso de uso “pede”:

```java
// application/port/in/ProcessLocationUpdatePort.java
public interface ProcessLocationUpdatePort {
    void process(LocationUpdatedEvent event);
}
```

**Port (saída)** — o que o caso de uso “precisa de fora”:

```java
// application/port/out/EventPublisher.java
public interface EventPublisher {
    void publishEtaUpdated(EtaUpdatedEvent event);
}
```

**Adapter** — implementação concreta:

```java
// infrastructure/nats/NatsEventPublisher.java
public class NatsEventPublisher implements EventPublisher {
    @Override
    public void publishEtaUpdated(EtaUpdatedEvent event) {
        // publica no subject route.eta.{vehicleId} via NATS
    }
}
```

**Use case** — depende só das interfaces:

```java
// application/usecase/ProcessLocationUpdateUseCase.java
public class ProcessLocationUpdateUseCase implements ProcessLocationUpdatePort {
    private final VehicleStateStore stateStore;  // port out
    private final EventPublisher eventPublisher; // port out

    @Override
    public void process(LocationUpdatedEvent event) {
        // lê estado, calcula ETA, publica evento — sem saber se é NATS ou Redis
    }
}
```

### Por que isso é júnior+

- Você **não injeta** NATS ou Redis no use case; injeta **interfaces**. Isso facilita testes (mock do `EventPublisher`) e troca de implementação.
- Nomenclatura: **Port in** = entrada (use case); **Port out** = saída (repositório, publicador, etc.).

---

## 2. Records para value objects e eventos

### Ideia

Em Java, **records** são imutáveis e definidos pelos campos. Ótimos para value objects e DTOs de eventos.

### Exemplo no projeto

```java
// domain/model/GeoPoint.java
public record GeoPoint(double latitude, double longitude) {
    public GeoPoint {
        if (latitude < -90 || latitude > 90) throw new IllegalArgumentException("lat");
        if (longitude < -180 || longitude > 180) throw new IllegalArgumentException("lon");
    }
}
```

```java
// domain/event/EtaUpdatedEvent.java (exemplo de estrutura)
public record EtaUpdatedEvent(
    UUID eventId,
    String eventType,
    String vehicleId,
    String routeId,
    int routeVersion,
    Instant occurredAt,
    EtaPayload payload
) {}
```

### Por que isso é júnior+

- **Imutabilidade**: ninguém altera o objeto depois de criado; evita bugs em fluxos assíncronos.
- **Compacto**: equals/hashCode/toString gerados; construtor compacto permite validação no próprio record.
- Use record para tudo que é “valor” ou evento de contrato; use classe/entidade quando precisar de identidade e ciclo de vida (ex.: entidade JPA).

---

## 3. Policies como componentes stateless

### Ideia

**Policies** são regras de decisão (ex.: “é desvio?”, “pode recalcular?”, “chegou ao destino?”). Ficam em componentes **stateless** injetados nos use cases, para manter a lógica de negócio testável e reutilizável.

### Exemplo no projeto

```java
// domain/policy/RouteDeviationPolicy.java (conceitual)
@Component
public class RouteDeviationPolicy {
    public boolean isDeviation(RouteProgress progress, GeoPoint currentPosition) {
        // distância ao corredor > threshold? heading muito diferente?
        return progress.distanceToCorridorMeters() > 50.0; // simplificado
    }
}

// domain/policy/RecalculationThrottlePolicy.java (conceitual)
@Component
public class RecalculationThrottlePolicy {
    public boolean allowRecalculation(String vehicleId, Instant lastRecalcAt) {
        // passou 30s desde o último? menos de 2 recálculos no último minuto?
        return Duration.between(lastRecalcAt, Instant.now()).toSeconds() >= 30;
    }
}
```

O use case **orquestra** as policies: primeiro verifica desvio, depois throttle; se ambas permitirem, dispara recálculo.

### Por que isso é júnior+

- Cada policy tem **uma responsabilidade**; fica fácil testar e alterar uma regra sem mexer nas outras.
- O use case fica **declarativo**: “se desvio e throttle ok → recalcular”.

---

## 4. Use case orquestra, não implementa detalhe

### Ideia

O **use case** coordena: chama port out para ler estado, chama domain/engine para calcular, chama policy para decidir, chama port out para persistir/publicar. Ele **não** contém fórmula de ETA nem SQL.

### Fluxo típico (ProcessLocationUpdate)

1. Recebe `LocationUpdatedEvent` (via port in).
2. `stateStore.get(vehicleId)` (port out).
3. `routeProgressService.getProgress(...)` (port out ou domain).
4. `deviationPolicy.isDeviation(...)` → se sim e `throttlePolicy.allowRecalc(...)` → publica `RecalculateRouteRequested`.
5. Senão: `etaEngine.update(...)` (engine) → `eventPublisher.publishEtaUpdated(...)` (port out).
6. `stateStore.save(...)` (port out).

### Por que isso é júnior+

- **Testes**: você mocka stateStore e eventPublisher e testa só a sequência e as decisões.
- **Leitura**: o use case vira um “roteiro” do fluxo; os detalhes estão nas policies e no engine.

---

## 5. Exceções de domínio e tratamento global

### Ideia

Em vez de `throw new RuntimeException("erro")`, usamos exceções **nomeadas** (`DomainException`, `RateLimitExceededException`, etc.). Um **handler global** (`@RestControllerAdvice`) converte cada tipo em status HTTP e corpo padronizado (ex.: `ErrorResponse` com `traceId`, `errorCode`, `message`).

### Por que isso é júnior+

- O cliente e os logs passam a ter **códigos e mensagens consistentes**.
- Você evita `catch (Exception e)` genérico; cada exceção tem um tratamento explícito.

---

## Resumo

| Padrão | O que fazer |
|--------|-------------|
| Ports & Adapters | Use cases dependem de **interfaces**; NATS/Redis/JPA implementam essas interfaces em `infrastructure/`. |
| Records | Use para value objects e eventos (imutáveis, validar no construtor compacto). |
| Policies | Regras de decisão em `@Component` stateless; use case só orquestra. |
| Use case | Orquestra ports e domain/engine; não implementa fórmula nem acesso a banco direto. |
| Exceções | Exceções de domínio/infra nomeadas + handler global com resposta padronizada. |

Quando for implementar um novo caso de uso, pergunte: “isso é entrada (port in), saída (port out), regra (policy), ou orquestração (use case)?” — isso ajuda a colocar cada coisa na camada certa.
