# 01 - Glossário e conceitos

Termos que aparecem nos docs e no código, explicados de forma direta para quem está subindo de júnior para júnior+.

---

## Arquitetura e domínio

### Event-driven (orientado a eventos)

Em vez de um serviço chamar outro diretamente (HTTP, método Java), os serviços **publicam eventos** em um **broker** (ex.: NATS). Outros serviços **assinam** esses eventos e reagem. Benefícios: desacoplamento, escalabilidade independente, resiliência (se um consumidor cai, os eventos ficam na fila).

**No projeto**: GPS envia posição → evento `LocationUpdatedEvent` → serviço de tracking consome, calcula ETA e publica `EtaUpdatedEvent` → cliente recebe via WebSocket.

### Bounded Context (contexto delimitado)

Em DDD, o domínio é dividido em **contextos** com fronteiras claras. Cada um tem seu próprio modelo (entidades, regras, linguagem). No projeto temos: **RoutePlanning**, **OptimizationEngine**, **ExecutionMonitoring**, **IncidentContext**.

### Aggregate (agregado)

Conjunto de entidades tratadas como **uma unidade** para consistência. Quem “manda” é o **aggregate root**. Exemplo: `RouteRequest` é o root; `RoutePoint`, `RouteStop`, `RouteConstraint` são entidades dentro do agregado. Regras de negócio e validações passam pelo root.

### Value Object (objeto de valor)

Objeto **imutável** definido apenas pelos seus valores (ex.: coordenada, janela de tempo). Não tem identidade própria; dois value objects com os mesmos valores são iguais. No projeto: `GeoPoint`, `EtaState`, `RegionTile`, `RouteProgress`.

### Port / Adapter (hexagonal)

**Port** = interface que define “o que o caso de uso precisa” (ex.: publicar evento, salvar estado). **Adapter** = implementação concreta (ex.: publicar no NATS, salvar no Redis). O núcleo da aplicação (domain + use cases) **não conhece** NATS nem Redis; só as interfaces. Isso facilita testes e troca de tecnologia.

---

## Infraestrutura e mensageria

### NATS JetStream

Broker de mensagens **open source** (em Go). **JetStream** é a parte que persiste mensagens e permite replay. Usamos para eventos de rota, ETA e incidentes. Subjects como `route.location.{vehicleId}` garantem ordem por veículo.

### Subject (NATS)

“Endereço” da mensagem. Consumidores assinam por subject (ou wildcard, ex.: `route.location.>`). No projeto, o subject inclui muitas vezes o `vehicleId` para **particionar** o tráfego por veículo.

### Consumer / Queue group

**Consumer**: quem lê mensagens de um stream. **Queue group**: vários consumidores com o mesmo nome; cada mensagem vai para **um só** deles (balanceamento de carga). Ex.: `tracking-worker` é um queue group com N instâncias.

### DLQ (Dead Letter Queue)

Fila para mensagens que **falharam** após retentativas. O payload original é preservado para análise e reprocessamento. No projeto temos stream e entidade `DeadLetterEvent`.

---

## Performance e operação

### Hot path / Cold path

- **Hot path**: caminho que a **maioria** dos eventos percorre — no nosso caso, atualizar ETA (sem recálculo). Precisa ser muito rápido (latência alvo p95 ≤ 100–200 ms).
- **Cold path**: caminho menos frequente e mais pesado — recálculo de rota (Christofides, 2-opt, GraphHopper). Pode levar segundos; por isso throttle e circuit breaker.

### Throttle (limitação de taxa)

Limitar **quantas vezes** uma ação pesada acontece (ex.: recálculo de rota). Ex.: no máximo 1 recálculo a cada 30 s por veículo, ou 2 por minuto. Evita picos de carga quando muitos veículos desviam ao mesmo tempo.

### Circuit breaker

Padrão de resiliência: se um serviço externo (ex.: motor de otimização) falha muitas vezes, o circuito “abre” e deixamos de chamá-lo por um tempo; as requisições seguem outro fluxo (ex.: ETA degradado) até o circuito “fechar” de novo.

### SLO / SLI

- **SLI** (Service Level Indicator): métrica que mede o serviço (ex.: latência p95 do ETA).
- **SLO** (Service Level Objective): meta para essa métrica (ex.: p95 ≤ 200 ms). Runbooks e alertas são definidos com base nos SLOs.

---

## Domínio do projeto

### ETA (Estimated Time of Arrival)

Tempo estimado para chegada ao destino. No projeto é **incremental**: a cada nova posição GPS, ajustamos o ETA com velocidade suavizada (EWMA) e fatores de trânsito/incidente, **sem** resolver a rota de novo. **Recebemos a velocidade do veículo** em cada atualização: o dispositivo envia `speedMps` (m/s) no payload de posição (API de ingestão e `LocationUpdatedEvent`); esse valor é a **velocidade observada** usada no EtaEngine para suavizar (EWMA) e calcular o tempo restante (distância restante / velocidade ajustada).

### Recálculo de rota

Recalcular a rota completa (ordem dos pontos, segmentos na rede viária). Ocorre quando: desvio, incidente crítico, mudança de destino, reotimização estratégica. É o **cold path**.

### Christofides / 2-opt / TSP

- **TSP** (Traveling Salesman Problem): visitar N pontos com custo total mínimo.
- **Christofides**: algoritmo de aproximação (garantia 3/2 do ótimo) usando MST + matching mínimo.
- **2-opt**: otimização local que “corta e religa” trechos da rota para reduzir distância. Usado depois do Christofides para refinar.

### Incidente crowdsourced

Evento reportado por usuários (blitz, acidente, trânsito, pista molhada, etc.). O sistema agrega votos (quorum), ativa o incidente e usa para ajustar ETA ou sugerir desvio. Não depende de API externa de trânsito.

### TraceId

Identificador único de uma **requisição/evento** ao longo de toda a cadeia (API → NATS → tracking → WebSocket). Permite auditoria: dado um erro, encontrar o payload original e todas as decisões tomadas.

---

## Resumo rápido

| Termo | Uma linha |
|-------|-----------|
| Event-driven | Serviços se comunicam por eventos no broker, não por chamadas diretas. |
| Bounded Context | Pedaço do domínio com modelo e linguagem próprios. |
| Aggregate root | Entidade que “comanda” um conjunto de entidades (consistência). |
| Value Object | Objeto imutável definido só pelos valores (ex.: GeoPoint). |
| Port/Adapter | Interface (port) + implementação concreta (adapter); núcleo não depende de infra. |
| Hot path | Caminho mais usado e mais rápido (ex.: atualizar ETA). |
| Cold path | Caminho pesado e menos frequente (ex.: recálculo de rota). |
| Throttle | Limitar frequência de uma ação pesada. |
| DLQ | Fila de mensagens que falharam (para análise/reprocessamento). |
| TraceId | ID que acompanha um evento do início ao fim para auditoria. |

Use este glossário sempre que encontrar um termo nos docs ou no código. Se algo ainda não estiver claro, anote e pergunte ao time ou consulte o [05 - FAQ](./05-FAQ-e-Armadilhas-Comuns.md).
