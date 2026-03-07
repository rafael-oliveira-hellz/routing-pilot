/// Rate limit: máx 5 reports/min no client. APP-6001.
class ReportRateLimiter {
  final List<DateTime> _timestamps = [];
  static const int maxPerMinute = 5;
  static const int windowSeconds = 60;

  bool get canReport {
    _trim();
    return _timestamps.length < maxPerMinute;
  }

  int get remainingSeconds {
    if (_timestamps.length < maxPerMinute) return 0;
    _trim();
    if (_timestamps.isEmpty) return 0;
    final oldest = _timestamps.first;
    final elapsed = DateTime.now().difference(oldest).inSeconds;
    return (windowSeconds - elapsed).clamp(0, windowSeconds);
  }

  void recordReport() {
    _timestamps.add(DateTime.now());
    _trim();
  }

  void _trim() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: windowSeconds));
    _timestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}
