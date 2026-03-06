# 07 - ETA Engine Otimizado

## Objetivo

Motor de ETA incremental, robusto e de baixo custo computacional.
Separa claramente **atualização de ETA** de **recálculo de rota**.

**Origem da velocidade:** O projeto **recebe a velocidade do veículo** em cada atualização. O dispositivo envia `speedMps` (metros por segundo) no batch de posições (POST /api/v1/locations) e no payload do `LocationUpdatedEvent` (doc 11). Esse valor é a **velocidade observada** (`observedSpeedMps`) usada pelo EtaEngine: entrando na EWMA e no cálculo `remainingSeconds = distanceRemainingMeters / smoothedSpeedMps` (ajustado por trafficFactor e incidentFactor). Sem `speedMps` do veículo, o ETA não teria como refletir a velocidade real em tempo real.

## Problemas do modelo original (CalculateETA)

- Fórmula física simplificada (aceleração, arrasto, rolamento) com pouca aderência ao trânsito real.
- Recalcula ETA do zero a cada chamada.
- Não considera qualidade do sinal GPS nem confiança do resultado.
- Mistura lógica de validação com cálculo.
- Não reage a incidentes externos.

## Arquitetura de camadas de ETA

```text
Camada 1: ETA Base de Rota
  └─ Calculado após otimização (Christofides + 2-opt)
  └─ Gera estimativa inicial por segmento

Camada 2: ETA Incremental (hot path)
  └─ Atualizado a cada LocationUpdatedEvent
  └─ Usa velocidade reportada pelo veículo (payload.speedMps) → EWMA → velocidade suavizada
  └─ remainingSeconds = distância restante / (velocidade suavizada × fatores tráfego/incidente)
  └─ NÃO resolve rota

Camada 3: ETA Corrigido por Contexto
  └─ Aplica impacto de incidentes ativos na região
  └─ Ajusta confiança do ETA
  └─ Pode degradar ou forçar recálculo
```

## Modelo de dados

```java
public record EtaState(
    long remainingSeconds,
    Instant calculatedAt,
    double confidence,           // 0.0 a 1.0
    double smoothedSpeedMps,     // EWMA
    Instant lastLocationAt,
    boolean degraded
) {}

public record RouteProgress(
    String routeId,
    int routeVersion,
    int currentSegmentIndex,
    double distanceRemainingMeters,
    double distanceToCorridorMeters,
    double distanceToDestinationMeters
) {}
```

## Algoritmo ETA incremental

A velocidade **observada** (`observedSpeedMps`) vem do **payload do evento de localização**: `LocationUpdatedEvent.payload.speedMps` (enviado pelo dispositivo em cada posição). O cliente deve enviar `speedMps` em toda posição para que o ETA reflita a velocidade real do veículo.

```java
public final class EtaEngine {

    private static final double MIN_SPEED_MPS = 1.0;
    private static final double MAX_SPEED_MPS = 45.0; // ~162 km/h
    private static final double EWMA_ALPHA = 0.25;

    // observedSpeedMps = evento.payload.speedMps (velocidade reportada pelo veículo)
    public EtaState update(EtaState current,
                           RouteProgress progress,
                           double observedSpeedMps,
                           double trafficFactor,
                           double incidentFactor,
                           Instant now) {

        double clipped = clamp(observedSpeedMps, MIN_SPEED_MPS, MAX_SPEED_MPS);
        double smoothed = ewma(current.smoothedSpeedMps(), clipped, EWMA_ALPHA);

        double nominalSec = progress.distanceRemainingMeters() / Math.max(smoothed, MIN_SPEED_MPS);

        // trafficFactor: 1.0 = normal; 1.3 = +30%
        // incidentFactor: 1.0 = sem incidente; 1.5 = blitz/acidente no trecho
        double adjustedSec = nominalSec * trafficFactor * incidentFactor;

        long remaining = Math.max(0L, Math.round(adjustedSec));
        double confidence = computeConfidence(
                progress.distanceToCorridorMeters(), now, current.lastLocationAt());
        boolean degraded = Duration.between(current.lastLocationAt(), now).toSeconds() > 20;

        return new EtaState(remaining, now, confidence, smoothed, now, degraded);
    }

    private static double ewma(double prev, double current, double alpha) {
        if (prev <= 0) return current;
        return alpha * current + (1 - alpha) * prev;
    }

    private static double clamp(double v, double min, double max) {
        return Math.max(min, Math.min(max, v));
    }

    private static double computeConfidence(double corridorDist, Instant now, Instant lastAt) {
        long ageSec = Math.max(0, Duration.between(lastAt, now).toSeconds());
        double c1 = Math.max(0.0, 1.0 - (corridorDist / 200.0));
        double c2 = Math.max(0.0, 1.0 - (ageSec / 60.0));
        return clamp(0.7 * c1 + 0.3 * c2, 0.0, 1.0);
    }
}
```

## Impacto de incidentes no ETA

```java
public final class IncidentEtaAdjuster {

    public double computeIncidentFactor(RouteProgress progress,
                                        List<ActiveIncident> nearbyIncidents) {
        if (nearbyIncidents.isEmpty()) return 1.0;

        double maxImpact = nearbyIncidents.stream()
                .filter(inc -> inc.affectsSegment(progress.currentSegmentIndex()))
                .mapToDouble(inc -> switch (inc.severity()) {
                    case LOW -> 1.05;
                    case MEDIUM -> 1.15;
                    case HIGH -> 1.35;
                    case CRITICAL -> 1.60;
                })
                .max()
                .orElse(1.0);

        return maxImpact;
    }
}
```

## Detecção de desvio

- Polilinha simplificada (Douglas-Peucker).
- R-tree espacial para segmento mais próximo em O(log n).
- Threshold dinâmico: urbano 30-50 m, rodovia 50-100 m.
- Heading check (ângulo entre direção do veículo e segmento).

## Casos cobertos (1-12)

| # | Caso | Ação |
|---|------|------|
| 1 | Mudança explícita de rota | Recálculo imediato |
| 2 | Atualização periódica de posição | Valida aderência + atualiza ETA |
| 3 | Desvio detectado | Recálculo completo + novo ETA |
| 4 | Dentro do corredor | Sem recálculo, só ETA |
| 5 | Ajuste progressivo | ETA reduz continuamente |
| 6 | Velocidade real diferente | Ajusta ETA via EWMA |
| 7 | Incidente/tráfego externo | `incidentFactor` ou recálculo |
| 8 | Próximo ao destino | Maior precisão e frequência |
| 9 | Destino alcançado | `remaining=0`, status ARRIVED |
| 10 | Perda de sinal | Extrapola + `degraded=true` |
| 11 | Mudança manual de destino | Reset + recálculo |
| 12 | Reotimização estratégica | Nova rota + ETA global |

## Custo por atualização (sem recálculo)

| Etapa | Tempo |
|-------|-------|
| Redis lookup | 1-3 ms |
| Projeção no corredor | 1-5 ms |
| ETA incremental | < 1 ms |
| Incident lookup (R-tree) | 1-3 ms |
| Publicação evento | 1-3 ms |
| **Total p95** | **8-20 ms** |
