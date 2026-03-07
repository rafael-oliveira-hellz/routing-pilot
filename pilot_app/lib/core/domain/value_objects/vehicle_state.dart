import 'package:pilot_app/core/domain/enums/domain_enums.dart';

/// Estado do veículo na execução da rota. Doc 02 / 06.
class VehicleState {
  const VehicleState({
    required this.vehicleId,
    required this.status,
    this.routeId,
    this.routeVersion,
    this.lastLocationAt,
  });

  final String vehicleId;
  final VehicleStatus status;
  final String? routeId;
  final int? routeVersion;
  final DateTime? lastLocationAt;
}
