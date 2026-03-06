# 08 - Use Cases e Policies

## Use Cases

### UC-01: ProcessLocationUpdateUseCase (hot path)

**Entrada**: `LocationUpdatedEvent`

**Passos**:
1. Carregar `VehicleState` do Redis.
2. Atualizar posição e velocidade observada.
3. Projetar posição no corredor da rota (R-tree).
4. Aplicar chain de policies:
   - `DestinationArrivalPolicy`
   - `RecalculationThrottlePolicy`
   - `RouteDeviationPolicy`
   - `IncidentImpactPolicy`
   - `EtaUpdatePolicy`
5. Persistir estado atualizado (Redis + async PG).
6. Publicar eventos de saída.

**Saídas possíveis**:
- `EtaUpdatedEvent`
- `RecalculateRouteRequested`
- `DestinationReachedEvent`
- `EtaDegradedEvent`

### UC-02: RecalculateRouteUseCase (cold path)

**Entrada**: `RecalculateRouteRequested`

**Passos**:
1. Carregar request, constraints e incidentes ativos no bounding box.
2. Aplicar penalidades de incidentes nos pesos de segmentos.
3. Acionar OptimizationEngine com time budget.
4. Atualizar rota ativa e incrementar `routeVersion`.
5. Recalcular ETA base.
6. Publicar `RouteRecalculatedEvent` + `EtaUpdatedEvent`.

### UC-03: ProcessIncidentReportUseCase

**Entrada**: `IncidentReportedEvent`

**Passos**:
1. Validar coordenadas e tipo.
2. Calcular `RegionTile`.
3. Buscar incidente duplicado (tipo + tile + raio).
4. Se duplicado: incrementar voto.
5. Se novo: persistir incidente.
6. Se quorum atingido: publicar `IncidentActivatedEvent`.
7. Atualizar cache de incidentes ativos.

### UC-04: ProcessIncidentVoteUseCase

**Entrada**: `IncidentVotedEvent`

**Passos**:
1. Validar voto (CONFIRM, DENY, GONE).
2. CONFIRM: incrementar `vote_count`, verificar quorum.
3. DENY: decrementar, desativar se count <= 0.
4. GONE: marcar como expirado.

### UC-05: FinalizeRouteUseCase

**Entrada**: `DestinationReachedEvent`

**Efeitos**:
- Status → `ARRIVED`
- `remainingSeconds = 0`
- Publicar evento de finalização.

### UC-06: ExpireIncidentsUseCase (scheduled)

**Trigger**: Cron job a cada 30 s.

**Passos**:
1. `UPDATE incident SET active = false WHERE expires_at < now() AND active = true`
2. Para cada incidente expirado: publicar `IncidentExpiredEvent`.
3. Invalidar cache Redis dos tiles afetados.

---

## Policies

### P-01: DestinationArrivalPolicy

```java
public boolean hasArrived(RouteProgress progress) {
    return progress.distanceToDestinationMeters() < ARRIVAL_RADIUS_METERS;
}
```

- Raio configurável: padrão 20 m.
- Prioridade máxima na chain.

### P-02: RecalculationThrottlePolicy

```java
public boolean canRecalculate(VehicleState state, Instant now) {
    long sinceLast = Duration.between(state.lastRecalculationAt(), now).toSeconds();
    return sinceLast >= MIN_INTERVAL_SECONDS
        && state.recalcCountLastMinute() < MAX_RECALC_PER_MINUTE;
}
```

- `MIN_INTERVAL_SECONDS`: 30
- `MAX_RECALC_PER_MINUTE`: 2
- Essencial para 1000+ veículos (evitar avalanche de recálculos).

### P-03: RouteDeviationPolicy

```java
public boolean shouldRecalculate(RouteProgress progress, double heading,
                                 double segmentHeading) {
    boolean corridorViolation = progress.distanceToCorridorMeters() > THRESHOLD_METERS;
    boolean headingMismatch = Math.abs(heading - segmentHeading) > 60;
    return corridorViolation && headingMismatch;
}
```

- Threshold dinâmico: urbano 40 m, rodovia 80 m.

### P-04: IncidentImpactPolicy

```java
public PolicyDecision evaluate(RouteProgress progress,
                               List<ActiveIncident> incidents) {
    double factor = incidentEtaAdjuster.computeIncidentFactor(progress, incidents);
    if (factor >= 1.4 && hasAlternativeSegment(progress)) {
        return PolicyDecision.RECALCULATE;
    }
    return PolicyDecision.ADJUST_ETA_ONLY;
}
```

- Incidentes CRITICAL no segmento atual → forte candidato a recálculo.
- Incidentes LOW/MEDIUM → apenas ajuste de ETA.

### P-05: EtaUpdatePolicy

O `speedMps` é obtido do **payload do LocationUpdatedEvent** (velocidade reportada pelo veículo em cada posição); é obrigatório para o cálculo do ETA.

```java
public EtaState computeNewEta(EtaState current, RouteProgress progress,
                              double speedMps, double trafficFactor,
                              double incidentFactor, Instant now) {
    return etaEngine.update(current, progress, speedMps,
                            trafficFactor, incidentFactor, now);
}
```

---

## Matriz de decisão consolidada

| Condição | Ação | Frequência |
|----------|------|------------|
| Dentro do corredor + sem incidente | Atualiza ETA | ~85% |
| Dentro do corredor + incidente leve | Atualiza ETA com fator | ~8% |
| Fora do corredor + throttle OK | Recalcula rota | ~3% |
| Fora do corredor + throttle bloqueando | ETA degradado + agenda recálculo | ~1% |
| Incidente CRITICAL no trecho | Recalcula imediatamente | ~0.5% |
| Mudança manual de destino | Recalcula imediatamente | Raro |
| Próximo ao destino (< 500 m) | Aumenta frequência de ETA | ~2% |
| Sem sinal > timeout | Extrapola ETA + degradado | ~0.5% |
