/// Progresso na rota (segmento atual, distâncias). Doc 02 / 06.
class RouteProgress {
  const RouteProgress({
    required this.routeId,
    required this.routeVersion,
    required this.currentSegmentIndex,
    required this.distanceRemainingMeters,
    required this.distanceToCorridorMeters,
    required this.distanceToDestinationMeters,
  });

  final String routeId;
  final int routeVersion;
  final int currentSegmentIndex;
  final double distanceRemainingMeters;
  final double distanceToCorridorMeters;
  final double distanceToDestinationMeters;
}
