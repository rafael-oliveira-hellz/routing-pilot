import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';
import 'package:pilot_app/features/incidents/data/incident_ws_client.dart';
import 'package:pilot_app/features/map/widgets/pulsating_marker.dart';

/// Lista e mapa de incidentes próximos + WebSocket em tempo real. APP-6002.
class IncidentsListPage extends StatefulWidget {
  const IncidentsListPage({super.key});

  @override
  State<IncidentsListPage> createState() => _IncidentsListPageState();
}

const List<double> _radiusOptions = [500, 1000, 2000, 5000];
const List<String> _typeOptions = [
  'Todos',
  'BLITZ', 'ACCIDENT', 'HEAVY_TRAFFIC', 'WET_ROAD', 'FLOOD', 'ROAD_WORK',
  'BROKEN_TRAFFIC_LIGHT', 'ANIMAL_ON_ROAD', 'VEHICLE_STOPPED', 'LANDSLIDE', 'FOG', 'OTHER',
];
const List<String> _severityOptions = ['Todas', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

class _IncidentsListPageState extends State<IncidentsListPage> {
  List<IncidentListItemDto> _items = [];
  final Set<String> _expiredIds = {};
  LatLng? _center;
  double _radiusMeters = 2000;
  bool _loading = false;
  String? _error;
  String? _filterType; // null = Todos
  String? _filterSeverity; // null = Todas
  StreamSubscription<IncidentActivatedEventDto>? _activatedSub;
  StreamSubscription<IncidentExpiredEventDto>? _expiredSub;

  @override
  void initState() {
    super.initState();
    _loadLocationAndFetch();
    _subscribeWs();
  }

  Future<void> _loadLocationAndFetch() async {
    setState(() => _loading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _center = LatLng(pos.latitude, pos.longitude);
      await _fetch();
      final ws = serviceLocator<IncidentWsClient>();
      await ws.connect(
        lat: _center!.latitude,
        lon: _center!.longitude,
        radiusMeters: _radiusMeters,
      );
    } catch (e) {
      _center = LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon);
      await _fetch();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetch() async {
    if (_center == null) return;
    setState(() => _error = null);
    try {
      final list = await serviceLocator<IncidentRepository>().listByLocation(
        lat: _center!.latitude,
        lon: _center!.longitude,
        radiusMeters: _radiusMeters,
      );
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _refetchWithRadius(double radius) async {
    await _fetch();
    if (mounted && _center != null) {
      final ws = serviceLocator<IncidentWsClient>();
      ws.disconnect();
      await ws.connect(
        lat: _center!.latitude,
        lon: _center!.longitude,
        radiusMeters: radius,
      );
    }
  }

  void _subscribeWs() {
    final ws = serviceLocator<IncidentWsClient>();
    _activatedSub = ws.activatedStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _expiredIds.remove(event.incidentId);
        final existing = _items.indexWhere((e) => e.id == event.incidentId);
        final dto = IncidentListItemDto(
          id: event.incidentId,
          lat: event.lat,
          lon: event.lon,
          incidentType: event.incidentType,
          severity: event.severity,
          expiresAt: event.expiresAt,
          radiusMeters: event.radiusMeters,
        );
        if (existing >= 0) {
          _items = List.from(_items)..[existing] = dto;
        } else {
          _items = [..._items, dto];
        }
      });
    });
    _expiredSub = ws.expiredStream.listen((event) {
      if (mounted) setState(() => _expiredIds.add(event.incidentId));
    });
  }

  @override
  void dispose() {
    serviceLocator<IncidentWsClient>().disconnect();
    _activatedSub?.cancel();
    _expiredSub?.cancel();
    super.dispose();
  }

  List<IncidentListItemDto> get _visibleItems {
    var list = _items.where((e) => !_expiredIds.contains(e.id)).toList();
    if (_filterType != null && _filterType!.isNotEmpty && _filterType != 'Todos') {
      list = list.where((e) => e.incidentType.toUpperCase() == _filterType).toList();
    }
    if (_filterSeverity != null && _filterSeverity!.isNotEmpty && _filterSeverity != 'Todas') {
      list = list.where((e) => e.severity?.toUpperCase() == _filterSeverity).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final center = _center ?? LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon);
    final visible = _visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidentes próximos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType ?? 'Todos',
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: _typeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _filterType = (v == 'Todos') ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterSeverity ?? 'Todas',
                    decoration: const InputDecoration(
                      labelText: 'Severidade',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: _severityOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _filterSeverity = (v == 'Todas') ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonFormField<double>(
                  value: _radiusMeters,
                  decoration: const InputDecoration(
                    labelText: 'Raio',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  items: _radiusOptions.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r == 1000 ? '1 km' : '${(r / 1000).toStringAsFixed(r >= 1000 ? 0 : 1)} km'),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null && v != _radiusMeters) {
                      setState(() => _radiusMeters = v);
                      if (_center != null) _refetchWithRadius(v);
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pilot.app',
                ),
                MarkerLayer(
                  markers: visible
                      .map((e) {
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
                              : Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange.shade700,
                                  size: 32,
                                ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final e = visible[i];
                      return _IncidentCard(incident: e);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatefulWidget {
  const _IncidentCard({required this.incident});

  final IncidentListItemDto incident;

  @override
  State<_IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<_IncidentCard> {
  bool _voting = false;
  String? _voteError;

  Future<void> _vote(String voteType) async {
    setState(() {
      _voting = true;
      _voteError = null;
    });
    try {
      await serviceLocator<IncidentRepository>().vote(
        widget.incident.id,
        VoteRequest(voteType: voteType),
      );
      if (mounted) {
        setState(() => _voting = false);
      }
    } catch (e) {
      if (mounted) setState(() {
        _voting = false;
        _voteError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.incident;
    final dist = e.distanceMeters != null
        ? '${(e.distanceMeters! / 1000).toStringAsFixed(1)} km'
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(e.incidentType, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (e.severity != null) Text(e.severity!, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
            if (e.description != null && e.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(e.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            Text('Distância: $dist', style: Theme.of(context).textTheme.bodySmall),
            if (e.expiresAt != null)
              Text('Expira: ${e.expiresAt}', style: Theme.of(context).textTheme.bodySmall),
            if (_voteError != null)
              Text(_voteError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: _voting ? null : () => _vote('CONFIRM'),
                  child: const Text('Confirmar'),
                ),
                TextButton(
                  onPressed: _voting ? null : () => _vote('DENY'),
                  child: const Text('Negar'),
                ),
                TextButton(
                  onPressed: _voting ? null : () => _vote('GONE'),
                  child: const Text('Já passou'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
