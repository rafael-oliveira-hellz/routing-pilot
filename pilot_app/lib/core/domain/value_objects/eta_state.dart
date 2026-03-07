/// Estado do ETA (tempo restante, confiança, degradado). Doc 02 / 07.
class EtaState {
  const EtaState({
    required this.remainingSeconds,
    required this.calculatedAt,
    required this.confidence,
    required this.smoothedSpeedMps,
    required this.lastLocationAt,
    required this.degraded,
  });

  final int remainingSeconds;
  final DateTime calculatedAt;
  final double confidence;
  final double smoothedSpeedMps;
  final DateTime lastLocationAt;
  final bool degraded;
}
