import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/features/route_planning/domain/route_repository.dart';
import 'package:pilot_app/core/router/app_router.dart';
import 'package:pilot_app/features/route_planning/presentation/pages/route_map_page.dart';
import 'package:pilot_app/features/tracking/presentation/pages/en_rota_page.dart';

/// Estados da tela de resultado da rota. APP-3002.
enum RouteResultState {
  loading,
  optimized,
  recalculating,
  failed,
}

/// Tela de resultado após "Calcular rota". Exibe totais, estado e "Ver no mapa". APP-2002, APP-3002.
class RouteResultPage extends StatefulWidget {
  const RouteResultPage({super.key, required this.requestId, required this.status});

  final String requestId;
  final String status;

  @override
  State<RouteResultPage> createState() => _RouteResultPageState();
}

class _RouteResultPageState extends State<RouteResultPage> {
  RouteResultState _state = RouteResultState.loading;
  RouteResultDto? _result;
  String? _errorMessage;
  String? _recalculationReason;
  bool _recalcInProgress = false;
  DateTime? _lastRecalcAt;
  static const _recalcThrottleSeconds = 30;

  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
    if (widget.requestId.isEmpty) {
      setState(() {
        _state = RouteResultState.failed;
        _errorMessage = 'ID da solicitação não informado.';
      });
      return;
    }
    setState(() {
      _errorMessage = null;
      _state = RouteResultState.loading;
    });
    try {
      final result = await serviceLocator<RouteRepository>().getRouteResult(widget.requestId);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _state = RouteResultState.loading;
          _result = null;
          _errorMessage = null;
        });
        return;
      }
      final status = result.status.toUpperCase();
      setState(() {
        _result = result;
        if (status == 'OPTIMIZED' || status == 'COMPLETED') {
          _state = RouteResultState.optimized;
        } else if (status == 'RECALCULATING' || status == 'PENDING') {
          _state = RouteResultState.recalculating;
          _recalculationReason = result.recalculationReason;
        } else if (status == 'FAILED' || status == 'ERROR') {
          _state = RouteResultState.failed;
          _errorMessage = 'Rota não pôde ser calculada.';
        } else {
          _state = RouteResultState.loading;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = RouteResultState.failed;
        _errorMessage = 'Falha ao obter resultado da rota.';
      });
    }
  }

  bool get _recalcThrottled {
    if (_lastRecalcAt == null) return false;
    return DateTime.now().difference(_lastRecalcAt!).inSeconds < _recalcThrottleSeconds;
  }

  Future<void> _requestRecalculation() async {
    if (widget.requestId.isEmpty) return;
    if (_recalcThrottled) return;
    setState(() => _recalcInProgress = true);
    try {
      await serviceLocator<RouteRepository>().requestRecalculation(widget.requestId, 'MANUAL');
      if (!mounted) return;
      setState(() {
        _recalcInProgress = false;
        _lastRecalcAt = DateTime.now();
        _state = RouteResultState.recalculating;
        _recalculationReason = 'MANUAL';
      });
      await _fetchResult();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recalcInProgress = false;
        _errorMessage = 'Falha ao solicitar recálculo.';
      });
    }
  }

  void _openMap() {
    RouteMapArgs? args;
    if (_result != null && _result!.pathGeometry.isNotEmpty) {
      final polyline = _result!.pathGeometry
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      LatLng? origin;
      LatLng? destination;
      final stops = <LatLng>[];
      if (_result!.waypoints.isNotEmpty) {
        origin = LatLng(
          _result!.waypoints.first.latitude,
          _result!.waypoints.first.longitude,
        );
        destination = LatLng(
          _result!.waypoints.last.latitude,
          _result!.waypoints.last.longitude,
        );
        for (var i = 1; i < _result!.waypoints.length - 1; i++) {
          final w = _result!.waypoints[i];
          stops.add(LatLng(w.latitude, w.longitude));
        }
      }
      final segmentHeavyTraffic = _result!.segments.isNotEmpty
          ? _result!.segments.map((s) => s.isHeavyTraffic).toList()
          : null;
      args = RouteMapArgs(
        polyline: polyline,
        origin: origin,
        destination: destination,
        stops: stops,
        segmentHeavyTraffic: segmentHeavyTraffic,
      );
    }
    context.pushNamed(
      AppRouter.routeMap,
      queryParameters: {'requestId': widget.requestId},
      extra: args,
    );
  }

  void _openEnRota() {
    List<LatLng>? polyline;
    if (_result != null && _result!.pathGeometry.isNotEmpty) {
      polyline = _result!.pathGeometry
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }
    context.pushNamed(
      AppRouter.routeEnRota,
      queryParameters: {'requestId': widget.requestId},
      extra: EnRotaArgs(polyline: polyline),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitação de rota'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_state == RouteResultState.loading) ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
                Text(
                  _result == null && _errorMessage == null
                      ? 'Carregando resultado...'
                      : 'Resultado ainda não disponível.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (_result == null && widget.requestId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _fetchResult,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ] else if (_state == RouteResultState.recalculating) ...[
                Icon(
                  Icons.sync,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Recalculando rota',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_recalculationReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Motivo: $_recalculationReason',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else if (_state == RouteResultState.failed) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'Erro ao obter rota',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Rota otimizada',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'ID: ${widget.requestId}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  if (_result!.totalDistanceMeters != null)
                    Text(
                      'Distância: ${_result!.totalDistanceMeters!} m',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (_result!.totalDurationSeconds != null)
                    Text(
                      'Duração: ${_result!.totalDurationSeconds!} s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (_result!.waypointCount != null)
                    Text(
                      'Waypoints: ${_result!.waypointCount}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ],
              const SizedBox(height: 32),
              if (_state == RouteResultState.optimized) ...[
                FilledButton.icon(
                  onPressed: _openEnRota,
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Iniciar rota (ETA ao vivo)'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Ver no mapa'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: (_recalcInProgress || _recalcThrottled) ? null : _requestRecalculation,
                  icon: _recalcInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Recalcular rota'),
                ),
                const SizedBox(height: 12),
              ],
              if (_state == RouteResultState.recalculating) ...[
                if (_result != null && _result!.pathGeometry.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Ver no mapa'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _fetchResult,
                  child: const Text('Atualizar resultado'),
                ),
                const SizedBox(height: 12),
              ],
              if (_state == RouteResultState.failed)
                FilledButton(
                  onPressed: _fetchResult,
                  child: const Text('Tentar novamente'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/routes/new'),
                child: const Text('Nova rota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
