# 02 - Modelo de Domínio e Bounded Contexts

## Mapa de contextos

```text
┌─────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│  RoutePlanning  │───►│OptimizationEngine│───►│ExecutionMonitoring │
│                 │    │                  │    │                    │
│ RouteRequest    │    │ RouteOptimization│    │ RouteExecution     │
│ RoutePoint      │    │ RouteResult      │    │ LivePosition       │
│ RouteStop       │    │ RouteSegment     │    │ ExecutionEvent     │
│ RouteConstraint │    │ RouteWaypoint    │    │ EtaState (VO)      │
└─────────────────┘    │ OptimizationRun  │    └────────┬───────────┘
                       └──────────────────┘             │
┌─────────────────┐                                     │
│IncidentContext  │◄────────────────────────────────────┘
│                 │
│ Incident        │
│ IncidentVote    │
│ IncidentImpact  │
│ RegionTile (VO) │
└─────────────────┘
```

## Aggregates e entidades

### RoutePlanning

| Aggregate Root | Entidade | Value Object |
|----------------|----------|--------------|
| `RouteRequest` | `RoutePoint` | `GeoPoint` |
|                | `RouteStop` | `TimeWindow` |
|                | `RouteConstraint` | `OptimizationStrategy` |

### OptimizationEngine

| Aggregate Root | Entidade | Value Object |
|----------------|----------|--------------|
| `RouteOptimization` | `RouteResult` | `Polyline` |
|                     | `RouteSegment` | `SegmentMetrics` |
|                     | `RouteWaypoint` | |
|                     | `OptimizationRun` | `AlgorithmConfig` |

### ExecutionMonitoring

| Aggregate Root | Entidade | Value Object |
|----------------|----------|--------------|
| `RouteExecution` | `LivePosition` | `EtaState` |
|                  | `ExecutionEvent` | `RouteProgress` |
|                  |                  | `VehicleStatus` |

### IncidentContext

| Aggregate Root | Entidade | Value Object |
|----------------|----------|--------------|
| `Incident` | `IncidentVote` | `RegionTile` |
|            | `IncidentImpact` | `IncidentType` |
|            |                  | `IncidentSeverity` |

## Value Objects principais

```java
public record GeoPoint(double latitude, double longitude) {
    public GeoPoint {
        if (latitude < -90 || latitude > 90) throw new IllegalArgumentException("lat");
        if (longitude < -180 || longitude > 180) throw new IllegalArgumentException("lon");
    }
}

public record EtaState(
    long remainingSeconds,
    Instant calculatedAt,
    double confidence,
    double smoothedSpeedMps,
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

public record RegionTile(int zoomLevel, long tileX, long tileY) {
    public static RegionTile fromGeoPoint(GeoPoint p, int zoom) {
        long n = 1L << zoom;
        long x = (long) ((p.longitude() + 180.0) / 360.0 * n);
        double latRad = Math.toRadians(p.latitude());
        long y = (long) ((1.0 - Math.log(Math.tan(latRad) + 1.0 / Math.cos(latRad)) / Math.PI) / 2.0 * n);
        return new RegionTile(zoom, x, y);
    }
}

public enum IncidentType {
    BLITZ, ACCIDENT, HEAVY_TRAFFIC, WET_ROAD, FLOOD,
    ROAD_WORK, BROKEN_TRAFFIC_LIGHT, ANIMAL_ON_ROAD,
    VEHICLE_STOPPED, LANDSLIDE, FOG, OTHER
}

public enum IncidentSeverity {
    LOW, MEDIUM, HIGH, CRITICAL
}

public enum VehicleStatus {
    IN_PROGRESS, DEGRADED_ESTIMATE, RECALCULATING, ARRIVED, FAILED
}
```

## Invariantes de domínio

| Contexto | Regra | Severidade |
|----------|-------|------------|
| RoutePlanning | Exatamente 1 origem + 1 destino por request | Alta |
| RoutePlanning | Máximo 1000 stops por request | Alta |
| RoutePlanning | `departure_at >= created_at` | Média |
| OptimizationEngine | Apenas 1 optimization ACTIVE por request | Alta |
| OptimizationEngine | `sequence_order` contíguo e sem gaps | Média |
| ExecutionMonitoring | `recorded_at` monotônico por veículo | Baixa |
| IncidentContext | Incidente expira automaticamente (TTL configurável) | Média |
| IncidentContext | Mínimo de N votos para ativar impacto (quorum) | Média |
