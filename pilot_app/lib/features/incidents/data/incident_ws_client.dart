import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';

/// WebSocket /ws/incidents. IncidentActivatedEvent, IncidentExpiredEvent. APP-6002.
class IncidentWsClient {
  IncidentWsClient({required Future<String?> Function() getAccessToken})
      : getAccessToken = getAccessToken;

  final Future<String?> Function() getAccessToken;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  final _activatedController =
      StreamController<IncidentActivatedEventDto>.broadcast();
  Stream<IncidentActivatedEventDto> get activatedStream => _activatedController.stream;

  final _expiredController = StreamController<IncidentExpiredEventDto>.broadcast();
  Stream<IncidentExpiredEventDto> get expiredStream => _expiredController.stream;

  Future<void> connect({double? lat, double? lon, double? radiusMeters}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;
    final base = AppConfig.wsBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final query = <String>['token=$token'];
    if (lat != null) query.add('lat=$lat');
    if (lon != null) query.add('lon=$lon');
    if (radiusMeters != null) query.add('radius=$radiusMeters');
    final uri = Uri.parse('$base/ws/incidents?${query.join('&')}');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) {},
        onDone: () {
          _channel = null;
          _sub?.cancel();
          _sub = null;
        },
        cancelOnError: false,
      );
    } catch (_) {}
  }

  void _onMessage(dynamic data) {
    try {
      final map = jsonDecode(data is String ? data : utf8.decode(data as List<int>))
          as Map<String, dynamic>;
      final eventType = map['eventType'] as String?;
      switch (eventType) {
        case 'IncidentActivatedEvent':
          _activatedController.add(IncidentActivatedEventDto.fromJson(map));
          break;
        case 'IncidentExpiredEvent':
          _expiredController.add(IncidentExpiredEventDto.fromJson(map));
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _activatedController.close();
    _expiredController.close();
  }
}
