import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/features/route_planning/domain/route_request_validator.dart';

void main() {
  group('RouteRequestValidator', () {
    test('retorna null para request válido com 2 points e 0 stops', () {
      final request = RouteRequestDto(
        points: [
          RoutePointDto(latitude: -23.5, longitude: -46.6),
          RoutePointDto(latitude: -23.6, longitude: -46.7),
        ],
        stops: [],
      );
      expect(RouteRequestValidator.validate(request), isNull);
    });

    test('retorna erro quando points.length != 2', () {
      final request = RouteRequestDto(
        points: [
          RoutePointDto(latitude: 0, longitude: 0),
        ],
        stops: [],
      );
      expect(
        RouteRequestValidator.validate(request),
        contains('exatamente 1 origem e 1 destino'),
      );
    });

    test('retorna erro para latitude inválida', () {
      final request = RouteRequestDto(
        points: [
          RoutePointDto(latitude: -100, longitude: 0),
          RoutePointDto(latitude: 0, longitude: 0),
        ],
        stops: [],
      );
      expect(RouteRequestValidator.validate(request), contains('Coordenadas inválidas'));
    });

    test('retorna erro quando stops > maxStops', () {
      final request = RouteRequestDto(
        points: [
          RoutePointDto(latitude: 0, longitude: 0),
          RoutePointDto(latitude: 1, longitude: 1),
        ],
        stops: List.generate(
          RouteRequestValidator.maxStops + 1,
          (i) => RouteStopDto(latitude: 0.0, longitude: 0.0, sequenceOrder: i + 1),
        ),
      );
      expect(
        RouteRequestValidator.validate(request),
        contains('Máximo de ${RouteRequestValidator.maxStops} paradas'),
      );
    });

    test('retorna erro quando departureAt é no passado', () {
      final now = DateTime.now().toUtc();
      final request = RouteRequestDto(
        points: [
          RoutePointDto(latitude: 0, longitude: 0),
          RoutePointDto(latitude: 1, longitude: 1),
        ],
        stops: [],
        departureAt: now.subtract(const Duration(hours: 1)),
      );
      expect(
        RouteRequestValidator.validate(request, now: now),
        contains('partida deve ser maior ou igual'),
      );
    });
  });
}
