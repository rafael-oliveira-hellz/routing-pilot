import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pilot_app/core/domain/dto/route_dto.dart';

const String _boxName = 'pilot_route_history';
const String _keyLastRequest = 'last_request';
const int _maxHistory = 5;
const String _keyHistoryList = 'history_list';

/// Cache local da última rota e histórico (até 5) para preencher "Nova rota". TODO-SPRINTS Sprint 2.
class RouteHistoryLocal {
  static Future<void> ensureBoxOpen() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  /// Salva a última solicitação enviada (após POST com sucesso).
  static Future<void> saveLastRequest({
    required String requestId,
    required RouteRequestDto request,
  }) async {
    await ensureBoxOpen();
    final map = {
      'requestId': requestId,
      'points': request.points.map((e) => {'lat': e.latitude, 'lon': e.longitude}).toList(),
      'stops': request.stops
          .map((e) => {
                'lat': e.latitude,
                'lon': e.longitude,
                'sequenceOrder': e.sequenceOrder,
              })
          .toList(),
      'constraints': request.constraints != null
          ? {
              'avoidTolls': request.constraints!.avoidTolls,
              'avoidTunnels': request.constraints!.avoidTunnels,
              'maxDurationSeconds': request.constraints!.maxDurationSeconds,
              'maxDistanceMeters': request.constraints!.maxDistanceMeters,
            }
          : null,
      'departureAt': request.departureAt?.toIso8601String(),
      'savedAt': DateTime.now().toUtc().toIso8601String(),
    };
    _box.put(_keyLastRequest, jsonEncode(map));

    // append to history list (summary only)
    final list = _getHistoryList();
    list.insert(0, {
      'requestId': requestId,
      'origin': request.points.isNotEmpty
          ? '${request.points.first.latitude.toStringAsFixed(4)}, ${request.points.first.longitude.toStringAsFixed(4)}'
          : '',
      'stopsCount': request.stops.length,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (list.length > _maxHistory) list.removeRange(_maxHistory, list.length);
    _box.put(_keyHistoryList, jsonEncode(list));
  }

  static List<Map<String, dynamic>> _getHistoryList() {
    try {
      final raw = _box.get(_keyHistoryList);
      if (raw is! String) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Retorna a última rota salva para preencher o formulário, ou null.
  static Future<({String requestId, RouteRequestDto request})?> getLastRequest() async {
    await ensureBoxOpen();
    final raw = _box.get(_keyLastRequest);
    if (raw is! String) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final points = (map['points'] as List<dynamic>?)
              ?.map((e) => RoutePointDto(
                    latitude: (e['lat'] as num).toDouble(),
                    longitude: (e['lon'] as num).toDouble(),
                  ))
              .toList() ??
          [];
      final stops = (map['stops'] as List<dynamic>?)
              ?.asMap()
              .entries
              .map((e) => RouteStopDto(
                    latitude: (e.value['lat'] as num).toDouble(),
                    longitude: (e.value['lon'] as num).toDouble(),
                    sequenceOrder: e.key + 1,
                  ))
              .toList() ??
          [];
      RouteConstraintDto? constraints;
      if (map['constraints'] != null) {
        final c = map['constraints'] as Map<String, dynamic>;
        constraints = RouteConstraintDto(
          avoidTolls: c['avoidTolls'] as bool? ?? false,
          avoidTunnels: c['avoidTunnels'] as bool? ?? false,
          maxDurationSeconds: c['maxDurationSeconds'] as int?,
          maxDistanceMeters: c['maxDistanceMeters'] as int?,
        );
      }
      DateTime? departureAt;
      if (map['departureAt'] != null) {
        departureAt = DateTime.parse(map['departureAt'] as String);
      }
      return (
        requestId: map['requestId'] as String,
        request: RouteRequestDto(
          points: points,
          stops: stops,
          constraints: constraints,
          departureAt: departureAt,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lista resumo do histórico (para exibir "Rotas recentes").
  static Future<List<Map<String, dynamic>>> getHistoryList() async {
    await ensureBoxOpen();
    return _getHistoryList();
  }
}
