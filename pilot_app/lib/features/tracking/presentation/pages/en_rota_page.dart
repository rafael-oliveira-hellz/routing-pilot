import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/eta_event_dto.dart';
import 'package:pilot_app/core/domain/enums/domain_enums.dart';
import 'package:pilot_app/core/security/jwt_parser.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/tracking/data/eta_ws_client.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';
import 'package:pilot_app/features/map/widgets/pulsating_marker.dart';
import 'package:pilot_app/features/tracking/data/location_service.dart';
import 'package:pilot_app/features/tracking/domain/route_tracking_event.dart';

/// Argumentos para a tela Em rota (polyline opcional).
class EnRotaArgs {
  const EnRotaArgs({this.polyline});
  final List<LatLng>? polyline;
}

/// Tela "Em rota": mapa, posição atual, card ETA em tempo real. WebSocket ETA + ingestão GPS. APP-4002.
class EnRotaPage extends StatefulWidget {
  const EnRotaPage({
    super.key,
    required this.routeRequestId,
    this.initialPolyline,
  });

  final String routeRequestId;
  final List<LatLng>? initialPolyline;

  @override
  State<EnRotaPage> createState() => _EnRotaPageState();
}

class _EnRotaPageState extends State<EnRotaPage> {
  EtaUpdatedEventDto? _eta;
  LatLng? _currentPosition;
  VehicleStatus _vehicleStatus = VehicleStatus.inProgress;
  StreamSubscription<EtaUpdatedEventDto>? _etaSub;
  StreamSubscription<RouteTrackingEvent>? _routeEventSub;
  bool _trackingStarted = false;
  String? _error;
  DateTime? _lastEtaAt;
  static const _signalLostSeconds = 20;
  Timer? _signalLostTimer;
  int _offlinePendingCount = 0;
  bool _isDraining = false;
  StreamSubscription<int>? _offlineCountSub;
  List<IncidentListItemDto> _incidents = [];
  static const _incidentRadiusMeters = 3000.0;

  @override
  void initState() {
    super.initState();
    _loadRouteAndStartTracking();
    _listenEta();
    _updateCurrentPosition();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    final center = _currentPosition ??
        (widget.initialPolyline?.isNotEmpty == true
            ? widget.initialPolyline!.first
            : LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon));
    try {
      final list = await serviceLocator<IncidentRepository>().listByLocation(
        lat: center.latitude,
        lon: center.longitude,
        radiusMeters: _incidentRadiusMeters,
      );
      if (mounted) setState(() => _incidents = list);
    } catch (_) {}
  }

  Future<void> _loadRouteAndStartTracking() async {
    if (widget.routeRequestId.isEmpty) return;
    final token = await serviceLocator<SecureTokenStorage>().getAccessToken();
    if (token == null) return;
    final vehicleId = JwtParser.getVehicleId(token);
    if (vehicleId == null || vehicleId.isEmpty) {
      setState(() => _error = 'Veículo não associado ao usuário.');
      return;
    }
    try {
      final locationService = serviceLocator<LocationService>();
      await locationService.start(
        vehicleId: vehicleId,
        routeId: widget.routeRequestId,
        routeVersion: 1,
      );
      final etaClient = serviceLocator<EtaWsClient>();
      await etaClient.connect(
        vehicleId: vehicleId,
        routeId: widget.routeRequestId,
      );
      final loc = serviceLocator<LocationService>();
      _offlineCountSub = loc.offlineCountStream.listen((c) {
        if (mounted) {
          setState(() {
            _offlinePendingCount = c;
            _isDraining = loc.isDraining;
          });
        }
      });
      if (mounted) {
        setState(() {
          _trackingStarted = true;
          _offlinePendingCount = loc.offlinePendingCount;
          _isDraining = loc.isDraining;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _listenEta() {
    final etaClient = serviceLocator<EtaWsClient>();
    _etaSub = etaClient.etaStream.listen((event) {
      if (mounted) {
        setState(() {
          _eta = event;
          _lastEtaAt = DateTime.now();
          _vehicleStatus = event.degraded
              ? VehicleStatus.degradedEstimate
              : VehicleStatus.inProgress;
        });
        _resetSignalLostTimer();
      }
    });
    _routeEventSub = etaClient.routeTrackingStream.listen((event) {
      if (!mounted) return;
      setState(() => _vehicleStatus = event.suggestedStatus);
      if (event is RouteTrackingDestinationReached) {
        serviceLocator<LocationService>().stop();
        serviceLocator<EtaWsClient>().disconnect();
        _trackingStarted = false;
      }
      _resetSignalLostTimer();
    });
    _signalLostTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_lastEtaAt == null) return;
      if (DateTime.now().difference(_lastEtaAt!).inSeconds >= _signalLostSeconds &&
          _vehicleStatus != VehicleStatus.arrived) {
        if (mounted) {
          setState(() => _vehicleStatus = VehicleStatus.degradedEstimate);
        }
      }
    });
  }

  void _resetSignalLostTimer() {
    _lastEtaAt = DateTime.now();
  }

  Future<void> _updateCurrentPosition() async {
    while (mounted) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) {
          setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  void dispose() {
    _signalLostTimer?.cancel();
    if (_trackingStarted) {
      serviceLocator<LocationService>().stop();
      serviceLocator<EtaWsClient>().disconnect();
    }
    _etaSub?.cancel();
    _routeEventSub?.cancel();
    _offlineCountSub?.cancel();
    super.dispose();
  }

  String get _statusMessage {
    switch (_vehicleStatus) {
      case VehicleStatus.inProgress:
        return 'Em rota';
      case VehicleStatus.degradedEstimate:
        return 'Sinal fraco – ETA aproximado';
      case VehicleStatus.recalculating:
        return 'Recalculando rota';
      case VehicleStatus.arrived:
        return 'Você chegou';
      case VehicleStatus.stopped:
        return 'Veículo parado';
      case VehicleStatus.failed:
        return 'Rota interrompida';
    }
  }

  String _confidenceLabel(double c) {
    if (c >= 0.7) return 'Alta';
    if (c >= 0.4) return 'Média';
    return 'Baixa';
  }

  @override
  Widget build(BuildContext context) {
    final polyline = widget.initialPolyline ?? <LatLng>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_statusMessage),
        actions: [
          if (_vehicleStatus == VehicleStatus.degradedEstimate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('ETA aproximado', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Card ETA
          Material(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEtaCard(),
                  _buildDistanceCard(),
                  _buildConfidenceCard(),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          if (_offlinePendingCount > 0 || _isDraining)
            Material(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  _isDraining
                      ? 'Enviando dados salvos offline ($_offlinePendingCount restantes)'
                      : '$_offlinePendingCount posições salvas offline (serão enviadas ao reconectar)',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ),
          if (_vehicleStatus == VehicleStatus.arrived)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chegada confirmada',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Finalizar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: _buildMap(polyline)),
        ],
      ),
    );
  }

  Widget _buildEtaCard() {
    final sec = _eta?.remainingSeconds ?? 0;
    final min = (sec / 60).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Chegada em', style: TextStyle(fontSize: 12)),
        Text(
          min <= 0 ? '—' : '$min min',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDistanceCard() {
    final m = _eta?.distanceRemainingMeters ?? 0.0;
    final km = (m / 1000).toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Distância', style: TextStyle(fontSize: 12)),
        Text(
          '$km km',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildConfidenceCard() {
    final c = _eta?.confidence ?? 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Confiança', style: TextStyle(fontSize: 12)),
        Text(
          _confidenceLabel(c),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMap(List<LatLng> polyline) {
    final initialCenter = _currentPosition ??
        (polyline.isNotEmpty
            ? polyline.first
            : LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon));
    final markers = <Marker>[
      if (_currentPosition != null)
        Marker(
          point: _currentPosition!,
          width: 36,
          height: 36,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
        ),
      ..._incidents.map((e) {
        final isBlitz = e.incidentType.toUpperCase() == 'BLITZ';
        return Marker(
          point: LatLng(e.lat, e.lon),
          width: isBlitz ? 44 : 32,
          height: isBlitz ? 44 : 32,
          child: isBlitz
              ? PulsatingMarker(
                  size: 44,
                  child: Icon(Icons.radar,
                      color: Colors.orange.shade800, size: 44),
                )
              : Icon(Icons.warning_amber,
                  color: Colors.orange.shade700, size: 32),
        );
      }),
    ];
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pilot.app',
        ),
        if (polyline.length >= 2)
          PolylineLayer(polylines: [
            Polyline(points: polyline, color: Colors.blue, strokeWidth: 4),
          ]),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
