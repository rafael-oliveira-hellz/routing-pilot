import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/route_planning/domain/route_repository.dart';
import 'package:pilot_app/features/route_planning/domain/route_request_validator.dart';
import 'package:pilot_app/features/route_planning/data/route_remote.dart';

/// Valida no client e chama POST /api/v1/route-requests. APP-2001.
class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl({required RouteRemote remote}) : _remote = remote;

  final RouteRemote _remote;

  @override
  Future<RouteRequestResponse> submitRouteRequest(RouteRequestDto request) async {
    final error = RouteRequestValidator.validate(request);
    if (error != null) throw ValidationException(error);
    return _remote.submitRouteRequest(request);
  }

  @override
  Future<RouteResultDto?> getRouteResult(String routeRequestId) async {
    return _remote.getRouteResult(routeRequestId);
  }

  @override
  Future<void> requestRecalculation(String routeRequestId, String reason) async {
    await _remote.requestRecalculation(routeRequestId, reason);
  }
}
