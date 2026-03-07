/// Janela de tempo (início/fim) para parada. Doc 02.
class TimeWindow {
  TimeWindow({required this.startAt, required this.endAt}) {
    if (startAt.isAfter(endAt)) {
      throw ArgumentError('startAt must be <= endAt');
    }
  }

  final DateTime startAt;
  final DateTime endAt;
}
