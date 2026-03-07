import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';
import 'package:pilot_app/features/incidents/data/report_rate_limiter.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';

/// Tipos e severidades aceitos pelo backend. APP-6001.
const List<String> kIncidentTypes = [
  'BLITZ', 'ACCIDENT', 'HEAVY_TRAFFIC', 'WET_ROAD', 'FLOOD', 'ROAD_WORK',
  'BROKEN_TRAFFIC_LIGHT', 'ANIMAL_ON_ROAD', 'VEHICLE_STOPPED', 'LANDSLIDE', 'FOG', 'OTHER',
];
const List<String> kSeverities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

/// Tela "Reportar incidente": mapa com pin, tipo, severidade, descrição. Rate limit 5/min. APP-6001.
class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  LatLng? _position;
  String _incidentType = kIncidentTypes.first;
  String? _severity = kSeverities.first;
  final _descriptionController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successId;
  final _rateLimiter = ReportRateLimiter();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) setState(() => _position = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      if (mounted) setState(() => _position = LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon));
    }
  }

  Future<void> _submit() async {
    if (_position == null) {
      setState(() => _error = 'Selecione a posição no mapa.');
      return;
    }
    if (!_rateLimiter.canReport) {
      setState(() => _error = 'Limite de 5 reportes por minuto. Aguarde ${_rateLimiter.remainingSeconds}s.');
      return;
    }
    final user = await serviceLocator<AuthRepository>().getCurrentUser();
    if (user == null) {
      setState(() => _error = 'Usuário não identificado.');
      return;
    }
    setState(() {
      _error = null;
      _successId = null;
      _loading = true;
    });
    try {
      final response = await serviceLocator<IncidentRepository>().report(
        ReportIncidentRequest(
          lat: _position!.latitude,
          lon: _position!.longitude,
          incidentType: _incidentType,
          severity: _severity,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reportedBy: user.id,
        ),
      );
      _rateLimiter.recordReport();
      if (mounted) {
        setState(() {
          _loading = false;
          _successId = response.incidentId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _position ?? LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: target,
                  initialZoom: 14,
                  onTap: (_, point) => setState(() => _position = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pilot.app',
                  ),
                  if (_position != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _position!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar minha localização'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _incidentType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: kIncidentTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _incidentType = v ?? kIncidentTypes.first),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(labelText: 'Severidade'),
              items: kSeverities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _severity = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            if (_successId != null) ...[
              const SizedBox(height: 8),
              Text('Reportado. ID: $_successId', style: TextStyle(color: Colors.green.shade700)),
            ],
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Enviar reporte de incidente',
              child: FilledButton(
                onPressed: _loading || !_rateLimiter.canReport ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_rateLimiter.canReport ? 'Enviar' : 'Aguarde ${_rateLimiter.remainingSeconds}s'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
