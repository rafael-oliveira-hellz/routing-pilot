# 03 - Contexto RoutePlanning

## Responsabilidade

Receber, validar e persistir intenção de rota antes da otimização.

## Aggregate Root: `RouteRequest`

## Entidades

| Tabela | Campos principais | Notas |
|--------|-------------------|-------|
| `route_request` | id, departure_at, optimization_strategy, created_at | Aggregate root |
| `route_point` | id, route_request_id, identifier, location (GEOGRAPHY), loading/unloading_duration_ms | Origem ou destino |
| `route_stop` | id, route_request_id, identifier, location (GEOGRAPHY), sequence_order | Até 1000 paradas |
| `route_constraint` | id, route_request_id, max_vehicle_count, max_duration_s, max_distance_m, avoid_tolls, avoid_tunnels | Restrições para VRP |

## Fluxo de criação

1. API recebe request (REST ou gRPC).
2. Validação síncrona (coordenadas, limites, duplicidade).
3. Persistência batch de stops.
4. Publicação de `RouteOptimizationRequested`.

## Performance para 1000+ stops

- Persistência em batch (`saveAll` com flush size 500).
- Índice GIST em `location` para queries espaciais.
- Índice composto `(route_request_id, sequence_order)`.
- Pré-calcular bounding box para uso no OptimizationEngine.

## Validações

```java
public final class RouteRequestValidator {
    public static void validate(RouteRequest request) {
        var points = request.getPoints();
        if (points.size() != 2)
            throw new DomainException("Exactly 1 origin and 1 destination required");

        var stops = request.getStops();
        if (stops.size() > 1000)
            throw new DomainException("Maximum 1000 stops exceeded");

        for (var stop : stops) {
            GeoPoint.validate(stop.getLatitude(), stop.getLongitude());
        }

        if (request.getDepartureAt() != null
                && request.getDepartureAt().isBefore(request.getCreatedAt()))
            throw new DomainException("departure_at must be >= created_at");
    }
}
```

## Casos de recálculo originados aqui

- Mudança manual de destino → `ManualDestinationChangedEvent`
- Inclusão/remoção de parada → `RouteOptimizationRequested`
- Mudança de constraint → `RouteOptimizationRequested`
- Reotimização estratégica (reordenar entregas) → `StrategicReoptimizationRequested`
