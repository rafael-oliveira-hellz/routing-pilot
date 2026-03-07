/// Métricas de um segmento da rota (distância, duração). Doc 02.
class SegmentMetrics {
  const SegmentMetrics({
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final double distanceMeters;
  final int durationSeconds;
}
