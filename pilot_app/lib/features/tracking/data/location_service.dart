import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/location_dto.dart';
import 'package:pilot_app/features/tracking/data/location_remote.dart';
import 'package:pilot_app/features/tracking/data/offline_location_buffer.dart';

/// Coleta posições com geolocator, batching (10 pos ou 5s), buffer offline e drain ao reconectar. APP-4001, APP-7001.
class LocationService {
  LocationService({
    required LocationRemote remote,
    required OfflineLocationBuffer offlineBuffer,
  })  : _remote = remote,
        _offlineBuffer = offlineBuffer;

  final LocationRemote _remote;
  final OfflineLocationBuffer _offlineBuffer;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final List<LocationPositionDto> _buffer = [];
  DateTime? _lastSendTime;
  String? _vehicleId;
  String? _routeId;
  int _routeVersion = 1;
  bool _running = false;
  Position? _lastPosition;
  DateTime? _lastMovementAt;
  bool _draining = false;
  int _offlinePendingCount = 0;

  bool get isRunning => _running;
  bool get isDraining => _draining;
  int get offlinePendingCount => _offlinePendingCount;

  final _offlineCountController = StreamController<int>.broadcast();
  Stream<int> get offlineCountStream => _offlineCountController.stream;

  /// Inicia coleta e envio. vehicleId/routeId/routeVersion obrigatórios.
  Future<void> start({
    required String vehicleId,
    required String routeId,
    int routeVersion = 1,
  }) async {
    if (_running) return;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        throw StateError('Permissão de localização negada');
      }
    }
    _vehicleId = vehicleId;
    _routeId = routeId;
    _routeVersion = routeVersion;
    _running = true;
    _lastMovementAt = DateTime.now();
    _scheduleNext();
    _updateOfflineCount();
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((_) => _onConnectivityChanged());
  }

  void _onConnectivityChanged() {
    _drainOfflineBuffer();
  }

  Future<void> _drainOfflineBuffer() async {
    if (_draining) return;
    final connected = await _isOnline();
    if (!connected) return;
    _draining = true;
    while (true) {
      final batch = await _offlineBuffer.popNextBatch(50);
      if (batch == null) break;
      try {
        await _remote.sendBatch(batch);
        await _offlineBuffer.removeBatch(batch);
      } catch (_) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      _updateOfflineCount();
    }
    _draining = false;
    _updateOfflineCount();
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _updateOfflineCount() async {
    final c = await _offlineBuffer.count;
    if (c != _offlinePendingCount) {
      _offlinePendingCount = c;
      _offlineCountController.add(c);
    }
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _flush();
    _vehicleId = null;
    _routeId = null;
  }

  void _scheduleNext() {
    if (!_running) return;
    final interval = _nextInterval();
    _timer = Timer(interval, () async {
      if (!_running) return;
      final position = await _getPosition();
      if (position != null && _running) {
        _addPosition(position);
        _lastPosition = position;
        _lastMovementAt = DateTime.now();
      } else {
        // Sem movimento > 2 min: heartbeat com última posição
        final elapsed = _lastMovementAt != null
            ? DateTime.now().difference(_lastMovementAt!)
            : Duration.zero;
        if (elapsed >= const Duration(minutes: 2, seconds: 30) &&
            _lastPosition != null) {
          _addPosition(_lastPosition!);
          _lastMovementAt = DateTime.now();
        }
      }
      _scheduleNext();
    });
  }

  Duration _nextInterval() {
    final speed = _lastPosition?.speed ?? 0.0;
    if (speed < 1.0) return AppConfig.locationIntervalStopped;
    return AppConfig.locationIntervalNormal;
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _addPosition(Position p) {
    final dto = LocationPositionDto(
      lat: p.latitude,
      lon: p.longitude,
      speedMps: (p.speed >= 0) ? p.speed : 0.0,
      occurredAt: p.timestamp,
      heading: p.heading >= 0 ? p.heading : null,
      accuracyMeters: p.accuracy >= 0 ? p.accuracy : null,
    );
    _buffer.add(dto);
    if (_buffer.length >= AppConfig.locationBatchMaxSize) {
      _flush();
    } else {
      final last = _lastSendTime;
      if (last == null ||
          DateTime.now().difference(last) >= AppConfig.locationBatchMaxWait) {
        _flush();
      }
    }
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty || _vehicleId == null || _routeId == null) return;
    final batch = List<LocationPositionDto>.from(_buffer);
    _buffer.clear();
    _lastSendTime = DateTime.now();
    final online = await _isOnline();
    if (!online) {
      await _offlineBuffer.addBatch(
        vehicleId: _vehicleId!,
        routeId: _routeId!,
        routeVersion: _routeVersion,
        positions: batch,
      );
      _updateOfflineCount();
      return;
    }
    try {
      await _remote.sendBatch(LocationsBatchRequest(
        vehicleId: _vehicleId!,
        routeId: _routeId!,
        routeVersion: _routeVersion,
        positions: batch,
      ));
    } catch (_) {
      await _offlineBuffer.addBatch(
        vehicleId: _vehicleId!,
        routeId: _routeId!,
        routeVersion: _routeVersion,
        positions: batch,
      );
      _updateOfflineCount();
    }
  }
}
