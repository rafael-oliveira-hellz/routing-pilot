import 'package:pilot_app/core/domain/dto/route_dto.dart';

/// Validação client-side para RouteRequest. APP-2001.
/// Exatamente 2 points (origem, destino); máx. 1000 stops; departure_at >= now; coordenadas válidas.
class RouteRequestValidator {
  static const int maxStops = 1000;

  static String? validate(RouteRequestDto request, {DateTime? now}) {
    final n = now ?? DateTime.now().toUtc();

    if (request.points.length != 2) {
      return 'Informe exatamente 1 origem e 1 destino (2 points).';
    }
    for (var i = 0; i < request.points.length; i++) {
      final p = request.points[i];
      if (p.latitude < -90 || p.latitude > 90 || p.longitude < -180 || p.longitude > 180) {
        return 'Coordenadas inválidas no point ${i + 1}.';
      }
    }
    if (request.stops.length > maxStops) {
      return 'Máximo de $maxStops paradas excedido.';
    }
    for (var i = 0; i < request.stops.length; i++) {
      final s = request.stops[i];
      if (s.latitude < -90 || s.latitude > 90 || s.longitude < -180 || s.longitude > 180) {
        return 'Coordenadas inválidas na parada ${i + 1}.';
      }
    }
    if (request.departureAt != null && request.departureAt!.isBefore(n)) {
      return 'Data/hora de partida deve ser maior ou igual a agora.';
    }
    return null;
  }
}
