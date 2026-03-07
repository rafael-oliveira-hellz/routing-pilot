import 'package:pilot_app/core/domain/dto/route_dto.dart';

/// Contrato para envio de solicitações de rota e resultado/recálculo. APP-2001, APP-3002.
abstract class RouteRepository {
  Future<RouteRequestResponse> submitRouteRequest(RouteRequestDto request);

  Future<RouteResultDto?> getRouteResult(String routeRequestId);

  Future<void> requestRecalculation(String routeRequestId, String reason);
}
