import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/location_dto.dart';

/// Buffer local de posições para envio offline. Até 10k posições; FIFO ao atingir 90%. APP-7001.
class OfflineLocationBuffer {
  static const _boxName = 'pilot_offline_locations';
  static const _keyBuffer = 'buffer';

  List<Map<String, dynamic>> _list = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_keyBuffer);
      if (raw is String) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _list = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _loaded = true;
    } catch (_) {
      _list = [];
      _loaded = true;
    }
  }

  Future<void> addBatch({
    required String vehicleId,
    required String routeId,
    required int routeVersion,
    required List<LocationPositionDto> positions,
  }) async {
    await _ensureLoaded();
    for (final p in positions) {
      _list.add({
        'lat': p.lat,
        'lon': p.lon,
        'speedMps': p.speedMps,
        'occurredAt': p.occurredAt.toUtc().toIso8601String(),
        'heading': p.heading,
        'accuracyMeters': p.accuracyMeters,
        'vehicleId': vehicleId,
        'routeId': routeId,
        'routeVersion': routeVersion,
      });
    }
    _trim();
    await _persist();
  }

  void _trim() {
    final max = AppConfig.offlineBufferMaxSize;
    final threshold = (max * AppConfig.offlineBufferTrimRatio).toInt();
    if (_list.length > threshold) {
      _list.sort((a, b) => (a['occurredAt'] as String).compareTo(b['occurredAt'] as String));
      _list = _list.sublist(_list.length - max);
    }
  }

  Future<void> _persist() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_keyBuffer, jsonEncode(_list));
    } catch (_) {}
  }

  /// Retorna o próximo batch (até batchSize posições do mesmo vehicleId/routeId/routeVersion), ordenado por occurredAt ASC. Não remove do buffer.
  Future<LocationsBatchRequest?> popNextBatch(int batchSize) async {
    await _ensureLoaded();
    if (_list.isEmpty) return null;
    _list.sort((a, b) => (a['occurredAt'] as String).compareTo(b['occurredAt'] as String));
    final first = _list.first;
    final vehicleId = first['vehicleId'] as String;
    final routeId = first['routeId'] as String;
    final routeVersion = first['routeVersion'] as int;
    final take = _list
        .where((m) =>
            m['vehicleId'] == vehicleId &&
            m['routeId'] == routeId &&
            m['routeVersion'] == routeVersion)
        .take(batchSize)
        .toList();
    if (take.isEmpty) return null;
    final positions = take.map((m) => LocationPositionDto(
      lat: (m['lat'] as num).toDouble(),
      lon: (m['lon'] as num).toDouble(),
      speedMps: (m['speedMps'] as num).toDouble(),
      occurredAt: DateTime.parse(m['occurredAt'] as String),
      heading: (m['heading'] as num?)?.toDouble(),
      accuracyMeters: (m['accuracyMeters'] as num?)?.toDouble(),
    )).toList();
    return LocationsBatchRequest(
      vehicleId: vehicleId,
      routeId: routeId,
      routeVersion: routeVersion,
      positions: positions,
    );
  }

  /// Remove do buffer as posições do batch (chamar após 202).
  Future<void> removeBatch(LocationsBatchRequest batch) async {
    await _ensureLoaded();
    final set = batch.positions.map((p) => p.occurredAt.toUtc().toIso8601String()).toSet();
    _list.removeWhere((m) => set.contains(m['occurredAt']));
    await _persist();
  }

  Future<int> get count async {
    await _ensureLoaded();
    return _list.length;
  }
}
