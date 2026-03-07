import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/route_planning/data/route_history_local.dart';
import 'package:pilot_app/features/route_planning/domain/route_repository.dart';
import 'package:pilot_app/l10n/app_localizations.dart';

/// Tela "Nova rota": origem, destino, paradas (até 1000), constraints, partida. APP-2002.
class NewRoutePage extends StatefulWidget {
  const NewRoutePage({super.key});

  @override
  State<NewRoutePage> createState() => _NewRoutePageState();
}

class _NewRoutePageState extends State<NewRoutePage> {
  final _originLat = TextEditingController(text: '');
  final _originLon = TextEditingController(text: '');
  final _destLat = TextEditingController(text: '');
  final _destLon = TextEditingController(text: '');
  int _stopId = 0;
  final List<({int id, TextEditingController lat, TextEditingController lon})> _stops = [];
  bool _avoidTolls = false;
  bool _avoidTunnels = false;
  String? _maxDurationSec;
  String? _maxDistanceM;
  DateTime? _departureAt;
  bool _loading = false;
  String? _errorMessage;
  bool _hasLastRequest = false;

  @override
  void initState() {
    super.initState();
    RouteHistoryLocal.getLastRequest().then((last) {
      if (mounted) setState(() => _hasLastRequest = last != null);
    });
  }

  static double? _parseDouble(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim().replaceAll(',', '.'));
  }

  Future<void> _fillFromLastRequest() async {
    final last = await RouteHistoryLocal.getLastRequest();
    if (last == null || !mounted) return;
    final r = last.request;
    if (r.points.length >= 2) {
      _originLat.text = r.points[0].latitude.toString();
      _originLon.text = r.points[0].longitude.toString();
      _destLat.text = r.points[1].latitude.toString();
      _destLon.text = r.points[1].longitude.toString();
    }
    while (_stops.isNotEmpty) {
      final s = _stops.removeLast();
      s.lat.dispose();
      s.lon.dispose();
    }
    _stopId = 0;
    for (final s in r.stops) {
      _stopId++;
      _stops.add((
        id: _stopId,
        lat: TextEditingController(text: s.latitude.toString()),
        lon: TextEditingController(text: s.longitude.toString()),
      ));
    }
    if (r.constraints != null) {
      _avoidTolls = r.constraints!.avoidTolls;
      _avoidTunnels = r.constraints!.avoidTunnels;
      _maxDurationSec = r.constraints!.maxDurationSeconds?.toString();
      _maxDistanceM = r.constraints!.maxDistanceMeters?.toString();
    }
    _departureAt = r.departureAt;
    if (mounted) setState(() {});
  }

  bool _validCoord(double? v, bool isLat) {
    if (v == null) return false;
    if (isLat) return v >= -90 && v <= 90;
    return v >= -180 && v <= 180;
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    final originLat = _parseDouble(_originLat.text);
    final originLon = _parseDouble(_originLon.text);
    final destLat = _parseDouble(_destLat.text);
    final destLon = _parseDouble(_destLon.text);
    if (originLat == null || originLon == null || !_validCoord(originLat, true) || !_validCoord(originLon, false)) {
      setState(() {
        _loading = false;
        _errorMessage = 'Informe coordenadas válidas para origem (lat -90 a 90, lon -180 a 180).';
      });
      return;
    }
    if (destLat == null || destLon == null || !_validCoord(destLat, true) || !_validCoord(destLon, false)) {
      setState(() {
        _loading = false;
        _errorMessage = 'Informe coordenadas válidas para destino.';
      });
      return;
    }
    final points = [
      RoutePointDto(latitude: originLat, longitude: originLon),
      RoutePointDto(latitude: destLat, longitude: destLon),
    ];
    final stops = <RouteStopDto>[];
    for (var i = 0; i < _stops.length; i++) {
      final lat = _parseDouble(_stops[i].lat.text);
      final lon = _parseDouble(_stops[i].lon.text);
      if (lat == null || lon == null || !_validCoord(lat, true) || !_validCoord(lon, false)) {
        setState(() {
          _loading = false;
          _errorMessage = 'Coordenadas inválidas na parada ${i + 1}.';
        });
        return;
      }
      stops.add(RouteStopDto(latitude: lat, longitude: lon, sequenceOrder: i + 1));
    }
    RouteConstraintDto? constraints;
    if (_avoidTolls || _avoidTunnels || _maxDurationSec != null || _maxDistanceM != null) {
      final maxSec = _maxDurationSec != null && _maxDurationSec!.trim().isNotEmpty
          ? int.tryParse(_maxDurationSec!.trim())
          : null;
      final maxM = _maxDistanceM != null && _maxDistanceM!.trim().isNotEmpty
          ? int.tryParse(_maxDistanceM!.trim())
          : null;
      constraints = RouteConstraintDto(
        avoidTolls: _avoidTolls,
        avoidTunnels: _avoidTunnels,
        maxDurationSeconds: maxSec,
        maxDistanceMeters: maxM,
      );
    }
    final request = RouteRequestDto(
      points: points,
      stops: stops,
      constraints: constraints,
      departureAt: _departureAt,
    );
    try {
      final response = await serviceLocator<RouteRepository>().submitRouteRequest(request);
      if (!mounted) return;
      context.go('/routes/result?id=${response.id}&status=${Uri.encodeComponent(response.status ?? '')}');
    } on ValidationException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = 'Falha ao calcular rota. Tente novamente.';
      });
    }
  }

  @override
  void dispose() {
    _originLat.dispose();
    _originLon.dispose();
    _destLat.dispose();
    _destLon.dispose();
    for (final s in _stops) {
      s.lat.dispose();
      s.lon.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: 'Nova rota. Informe origem, destino e paradas.',
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.newRoute),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_hasLastRequest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _fillFromLastRequest,
                      icon: const Icon(Icons.history),
                      label: Text(l10n.fillLastRoute),
                    ),
                  ),
                Text(l10n.origin, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _originLat,
                        decoration: const InputDecoration(labelText: 'Lat', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _originLon,
                        decoration: const InputDecoration(labelText: 'Lon', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.destination, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _destLat,
                        decoration: const InputDecoration(labelText: 'Lat', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _destLon,
                        decoration: const InputDecoration(labelText: 'Lon', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.stops, style: Theme.of(context).textTheme.titleSmall),
                    TextButton.icon(
                      onPressed: _stops.length >= 1000
                          ? null
                          : () => setState(() => _stops.add((
                                id: _stopId++,
                                lat: TextEditingController(text: ''),
                                lon: TextEditingController(text: ''),
                              ))),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.add),
                    ),
                  ],
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stops.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _stops.removeAt(oldIndex);
                      _stops.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final s = _stops[index];
                    return Card(
                      key: ValueKey(s.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: s.lat,
                                decoration: const InputDecoration(labelText: 'Lat', isDense: true),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: s.lon,
                                decoration: const InputDecoration(labelText: 'Lon', isDense: true),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() {
                            s.lat.dispose();
                            s.lon.dispose();
                            _stops.removeAt(index);
                          }),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Restrições (opcional)', style: Theme.of(context).textTheme.titleSmall),
                CheckboxListTile(
                  value: _avoidTolls,
                  onChanged: (v) => setState(() => _avoidTolls = v ?? false),
                  title: const Text('Evitar pedágio'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: _avoidTunnels,
                  onChanged: (v) => setState(() => _avoidTunnels = v ?? false),
                  title: const Text('Evitar túneis'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextField(
                  onChanged: (v) => setState(() => _maxDurationSec = v),
                  decoration: const InputDecoration(
                    labelText: 'Duração máx. (segundos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() => _maxDistanceM = v),
                  decoration: const InputDecoration(
                    labelText: 'Distância máx. (metros)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text('Partida (opcional)', style: Theme.of(context).textTheme.titleSmall),
                ListTile(
                  title: Text(_departureAt == null
                      ? 'Não definido'
                      : '${_departureAt!.day}/${_departureAt!.month}/${_departureAt!.year} ${_departureAt!.hour}:${_departureAt!.minute}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null || !mounted) return;
                    final time = await showTimePicker(
                      context: context, // ignore: use_build_context_synchronously
                      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                    );
                    if (time == null || !mounted) return;
                    setState(() => _departureAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.route),
                  label: Text(_loading ? l10n.calculating : l10n.calculateRoute),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
