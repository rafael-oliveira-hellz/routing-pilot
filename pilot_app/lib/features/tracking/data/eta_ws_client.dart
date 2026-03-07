import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/eta_event_dto.dart';
import 'package:pilot_app/features/tracking/domain/route_tracking_event.dart';

/// Cliente WebSocket para ETA (/ws/eta). Autenticação por query token. Reconexão com backoff. APP-4002, APP-5001.
class EtaWsClient {
  EtaWsClient({required Future<String?> Function() getAccessToken})
      : getAccessToken = getAccessToken;

  final Future<String?> Function() getAccessToken;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  int _reconnectAttempt = 0;
  static const _maxReconnectAttempts = 10;
  String? _vehicleId;
  String? _routeId;

  final _etaController = StreamController<EtaUpdatedEventDto>.broadcast();
  Stream<EtaUpdatedEventDto> get etaStream => _etaController.stream;

  final _routeEventController = StreamController<RouteTrackingEvent>.broadcast();
  Stream<RouteTrackingEvent> get routeTrackingStream => _routeEventController.stream;

  bool get isConnected => _channel != null;

  /// Conecta ao /ws/eta com token. Query: token=xxx ou authorization=Bearer.
  Future<void> connect({String? vehicleId, String? routeId}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;
    _vehicleId = vehicleId;
    _routeId = routeId;
    final base = AppConfig.wsBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final path = '/ws/eta';
    final query = <String>[
      'token=$token',
      if (vehicleId != null) 'vehicleId=$vehicleId',
      if (routeId != null) 'routeId=$routeId',
    ].join('&');
    final uri = Uri.parse('$base$path?$query');
    try {
      _channel = WebSocketChannel.connect(uri);
      _reconnectAttempt = 0;
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect(vehicleId: vehicleId, routeId: routeId);
    }
  }

  void _onMessage(dynamic data) {
    try {
      final map = jsonDecode(data is String ? data : utf8.decode(data as List<int>))
          as Map<String, dynamic>;
      final eventType = map['eventType'] as String?;
      switch (eventType) {
        case 'EtaUpdatedEvent':
          final eta = EtaUpdatedEventDto.fromJson(map);
          _etaController.add(eta);
          _routeEventController.add(RouteTrackingEtaUpdated(eta));
          break;
        case 'RouteRecalculatedEvent':
          _routeEventController.add(RouteTrackingRecalculated(
            RouteRecalculatedEventDto.fromJson(map),
          ));
          break;
        case 'DestinationReachedEvent':
          _routeEventController.add(RouteTrackingDestinationReached(
            DestinationReachedEventDto.fromJson(map),
          ));
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  void _onError(dynamic _) {
    _channel = null;
  }

  void _onDone() {
    _channel = null;
    _sub?.cancel();
    _sub = null;
    if (_reconnectAttempt < _maxReconnectAttempts) {
      _scheduleReconnect(vehicleId: _vehicleId, routeId: _routeId);
    }
  }

  void _scheduleReconnect({String? vehicleId, String? routeId}) {
    if (_reconnectAttempt >= _maxReconnectAttempts) return;
    _reconnectAttempt++;
    final delay = AppConfig.wsReconnectDelay *
        (1 << (_reconnectAttempt.clamp(0, 5)));
    Future.delayed(delay, () {
      connect(vehicleId: vehicleId, routeId: routeId);
    });
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempt = _maxReconnectAttempts;
  }

  void dispose() {
    disconnect();
    _etaController.close();
    _routeEventController.close();
  }
}
