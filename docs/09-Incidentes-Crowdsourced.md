# 09 - Incidentes Crowdsourced

## Objetivo

Permitir que usuários reportem eventos reais (blitz, acidente, trânsito intenso, pista molhada, etc.) para um **trecho específico**. O sistema agrega, valida e usa essas informações para ajustar ETA e desviar rotas **sem depender de APIs externas**.

## Tipos de incidente suportados

| Tipo | Impacto padrão | TTL padrão | Quorum mínimo |
|------|---------------|------------|----------------|
| `BLITZ` | MEDIUM | 2 h | 2 |
| `ACCIDENT` | HIGH | 4 h | 1 |
| `HEAVY_TRAFFIC` | MEDIUM | 1 h | 3 |
| `WET_ROAD` | LOW | 3 h | 2 |
| `FLOOD` | CRITICAL | 6 h | 1 |
| `ROAD_WORK` | MEDIUM | 8 h | 1 |
| `BROKEN_TRAFFIC_LIGHT` | LOW | 2 h | 2 |
| `ANIMAL_ON_ROAD` | LOW | 30 min | 1 |
| `VEHICLE_STOPPED` | LOW | 1 h | 2 |
| `LANDSLIDE` | CRITICAL | 12 h | 1 |
| `FOG` | MEDIUM | 2 h | 2 |
| `OTHER` | LOW | 1 h | 3 |

## Modelo de dados

### Tabelas

```sql
CREATE TABLE incident (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_type   VARCHAR(40) NOT NULL,
    severity        VARCHAR(20) NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_meters   INTEGER NOT NULL DEFAULT 200,
    region_tile_x   BIGINT NOT NULL,
    region_tile_y   BIGINT NOT NULL,
    region_zoom     INTEGER NOT NULL DEFAULT 14,
    description     VARCHAR(500),
    reported_by     UUID NOT NULL,
    vote_count      INTEGER NOT NULL DEFAULT 1,
    quorum_reached  BOOLEAN NOT NULL DEFAULT FALSE,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at      TIMESTAMP NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_incident_tile ON incident (region_tile_x, region_tile_y, region_zoom) WHERE active = TRUE;
CREATE INDEX idx_incident_location ON incident USING GIST (location) WHERE active = TRUE;
CREATE INDEX idx_incident_expires ON incident (expires_at) WHERE active = TRUE;

CREATE TABLE incident_vote (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES incident(id) ON DELETE CASCADE,
    voter_id    UUID NOT NULL,
    vote_type   VARCHAR(10) NOT NULL, -- CONFIRM, DENY, GONE
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (incident_id, voter_id)
);
```

### Java entities

```java
@Entity
@Table(name = "incident")
public class IncidentEntity {
    @Id
    private UUID id;

    @Enumerated(EnumType.STRING)
    private IncidentType incidentType;

    @Enumerated(EnumType.STRING)
    private IncidentSeverity severity;

    private double latitude;
    private double longitude;
    private int radiusMeters;
    private long regionTileX;
    private long regionTileY;
    private int regionZoom;
    private String description;
    private UUID reportedBy;
    private int voteCount;
    private boolean quorumReached;
    private boolean active;
    private Instant expiresAt;
    private Instant createdAt;
    private Instant updatedAt;
}
```

## Fluxo de vida de um incidente

```text
1. Usuário reporta incidente no app (lat, lon, tipo)
   └─► IncidentReportedEvent

2. IncidentService recebe e persiste
   └─► Calcula RegionTile
   └─► Verifica duplicata por (tile + tipo + raio)
   └─► Se duplicata: incrementa voto
   └─► Se novo: cria incidente (quorum_reached = false se quorum > 1)

3. Verificação de quorum
   └─► Se vote_count >= quorum → quorum_reached = true
   └─► Publica IncidentActivatedEvent

4. Impacto ativo
   └─► Incidentes com quorum são incluídos no R-tree de incidentes
   └─► EtaEngine consulta incidentes ativos por segmento
   └─► OptimizationEngine penaliza segmentos com incidentes na MST

5. Negação / expiração
   └─► Votos DENY reduzem contagem
   └─► Votos GONE marcam como expirado
   └─► Cron/scheduler expira incidentes com expires_at < now()
   └─► Publica IncidentExpiredEvent
```

## Estratégia de agrupamento espacial (RegionTile)

- Usar slippy map tiles zoom 14 (~1 km² por tile).
- Indexar incidentes por `(tile_x, tile_y, zoom)`.
- Para consulta de impacto: buscar tiles vizinhos (3×3 grid).
- R-tree em memória (atualizado por evento) para lookup em O(log n).

## Impacto no ETA e na rota

### No ETA (hot path, sem recálculo)

```java
public double computeIncidentFactor(RouteProgress progress,
                                    List<ActiveIncident> nearby) {
    return nearby.stream()
            .filter(i -> i.quorumReached() && i.affectsSegment(progress.currentSegmentIndex()))
            .mapToDouble(i -> switch (i.severity()) {
                case LOW -> 1.05;
                case MEDIUM -> 1.15;
                case HIGH -> 1.35;
                case CRITICAL -> 1.60;
            })
            .max()
            .orElse(1.0);
}
```

### Na rota (cold path, recálculo)

- Segmentos com incidentes CRITICAL recebem penalidade de peso na MST.
- Se impacto alto no trecho atual → `RecalculateRouteRequested`.
- Threshold: `if (incidentFactor > 1.4 && hasAlternativeSegment) recalculate()`.

## Eventos NATS

| Subject | Payload | Direção |
|---------|---------|---------|
| `incident.reported.{tile}` | IncidentReportedEvent | User → Service |
| `incident.voted.{incidentId}` | IncidentVotedEvent | User → Service |
| `incident.activated.{tile}` | IncidentActivatedEvent | Service → Tracking/Routing |
| `incident.expired.{tile}` | IncidentExpiredEvent | Service → Tracking/Routing |

## Performance para 1000+ veículos

- Cache de incidentes ativos em Redis: `incidents:tile:{x}:{y}` com TTL.
- Refresh periódico (5 s) ou por evento de ativação/expiração.
- Lookup por tile é O(1) no Redis + O(log n) no R-tree local.
- Expiração: scheduled job a cada 30 s (batch delete).

## Endpoint de report simplificado

```java
public record ReportIncidentRequest(
    double latitude,
    double longitude,
    IncidentType incidentType,
    IncidentSeverity severity,   // opcional, default por tipo
    String description           // opcional
) {}
```

## Anti-spam e qualidade

- Rate limit: máx 5 reports/min por usuário.
- Cooldown: mesmo tipo + mesmo tile → incrementa voto em vez de duplicar.
- Score de confiança por usuário (futuro): quem mais confirma acertos ganha peso.
