import 'package:pilot_app/core/domain/dto/route_dto.dart';

/// Contrato para envio de solicitações de rota. APP-2001.
abstract class RouteRepository {
  Future<RouteRequestResponse> submitRouteRequest(RouteRequestDto request);
}
