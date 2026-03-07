import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';
import 'package:pilot_app/features/map/widgets/pulsating_marker.dart';
import 'package:pilot_app/core/di/injection.dart';

/// Argumentos para a tela do mapa: polyline, marcadores e opcionalmente trânsito por segmento.
class RouteMapArgs {
  const RouteMapArgs({
    this.polyline = const [],
    this.origin,
    this.destination,
    this.stops = const [],
    this.segmentHeavyTraffic,
  });

  final List<LatLng> polyline;
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> stops;
  /// Por segmento (ordem do backend): true = trânsito intenso (trecho vermelho).
  final List<bool>? segmentHeavyTraffic;
}

/// Mapa da rota com OpenStreetMap (gratuito, sem API key). APP-3001.
class RouteMapPage extends StatefulWidget {
  const RouteMapPage({
    super.key,
    this.requestId,
    this.args,
  });

  final String? requestId;
  final RouteMapArgs? args;

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final _mapController = MapController();
  static const _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  List<IncidentListItemDto> _incidents = [];
  static const _incidentRadiusMeters = 5000.0;

  LatLng get _initialCenter {
    final args = widget.args;
    if (args != null) {
      if (args.origin != null) return args.origin!;
      if (args.polyline.isNotEmpty) return args.polyline.first;
      if (args.destination != null) return args.destination!;
      if (args.stops.isNotEmpty) return args.stops.first;
    }
    return LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon);
  }

  List<Marker> get _markers {
    final args = widget.args;
    if (args == null) return [];
    final list = <Marker>[];
    if (args.origin != null) {
      list.add(Marker(
        point: args.origin!,
        width: 40,
        height: 40,
        child: const Icon(Icons.trip_origin, color: Colors.green, size: 40),
      ));
    }
    if (args.destination != null) {
      list.add(Marker(
        point: args.destination!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }
    for (var i = 0; i < args.stops.length; i++) {
      list.add(Marker(
        point: args.stops[i],
        width: 32,
        height: 32,
        child: Icon(Icons.place, color: Colors.blue.shade700, size: 32),
      ));
    }
    for (final inc in _incidents) {
      final point = LatLng(inc.lat, inc.lon);
      final isBlitz = inc.incidentType.toUpperCase() == 'BLITZ';
      list.add(Marker(
        point: point,
        width: isBlitz ? 44 : 32,
        height: isBlitz ? 44 : 32,
        child: isBlitz
            ? PulsatingMarker(
                size: 44,
                child: Icon(Icons.radar, color: Colors.orange.shade800, size: 44),
              )
            : Icon(
                Icons.warning_amber,
                color: Colors.orange.shade700,
                size: 32,
              ),
      ));
    }
    return list;
  }

  List<Polyline> get _polylines {
    final args = widget.args;
    if (args == null || args.polyline.length < 2) return [];
    final segHeavy = args.segmentHeavyTraffic;
    if (segHeavy == null || segHeavy.isEmpty) {
      return [
        Polyline(
          points: args.polyline,
          color: Colors.blue,
          strokeWidth: 5,
        ),
      ];
    }
    final n = args.polyline.length;
    final segCount = segHeavy.length;
    final polylines = <Polyline>[];
    for (var i = 0; i < segCount; i++) {
      final start = (i * n / segCount).floor();
      final end = i == segCount - 1 ? n : ((i + 1) * n / segCount).floor();
      if (end > start) {
        final pts = args.polyline.sublist(start, end);
        if (pts.length >= 2) {
          polylines.add(Polyline(
            points: pts,
            color: segHeavy[i] ? Colors.red : Colors.blue,
            strokeWidth: 5,
          ));
        }
      }
    }
    return polylines.isEmpty
        ? [
            Polyline(
              points: args.polyline,
              color: Colors.blue,
              strokeWidth: 5,
            ),
          ]
        : polylines;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
      _loadIncidents();
    });
  }

  Future<void> _loadIncidents() async {
    final args = widget.args;
    if (args == null || args.polyline.isEmpty) return;
    double lat = args.polyline.first.latitude;
    double lon = args.polyline.first.longitude;
    for (final p in args.polyline) {
      lat += p.latitude;
      lon += p.longitude;
    }
    lat /= args.polyline.length;
    lon /= args.polyline.length;
    try {
      final list = await serviceLocator<IncidentRepository>().listByLocation(
        lat: lat,
        lon: lon,
        radiusMeters: _incidentRadiusMeters,
      );
      if (mounted) setState(() => _incidents = list);
    } catch (_) {}
  }

  void _fitBounds() {
    final args = widget.args;
    if (args == null) return;
    final points = <LatLng>[
      ...args.polyline,
      if (args.origin != null) args.origin!,
      if (args.destination != null) args.destination!,
      ...args.stops,
    ];
    if (points.length < 2) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
    final span = (maxLat - minLat).abs().clamp(0.01, 90.0) + (maxLng - minLng).abs().clamp(0.01, 180.0);
    final zoom = span > 10 ? 8.0 : span > 2 ? 10.0 : span > 0.5 ? 12.0 : 14.0;
    _mapController.move(center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.requestId != null
              ? 'Mapa – ${widget.requestId}'
              : 'Mapa da rota',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centralizar na sua localização em breve.')),
              );
            },
            tooltip: 'Minha localização',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: _osmUrl,
            userAgentPackageName: 'com.pilot.app',
          ),
          PolylineLayer(polylines: _polylines),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
