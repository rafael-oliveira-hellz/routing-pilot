import 'package:pilot_app/core/domain/dto/eta_event_dto.dart';
import 'package:pilot_app/core/domain/enums/domain_enums.dart';

/// Evento unificado de tracking (ETA, recálculo, chegada). APP-5001.
sealed class RouteTrackingEvent {
  const RouteTrackingEvent();
  VehicleStatus get suggestedStatus;
}

class RouteTrackingEtaUpdated extends RouteTrackingEvent {
  const RouteTrackingEtaUpdated(this.eta);
  final EtaUpdatedEventDto eta;
  @override
  VehicleStatus get suggestedStatus =>
      eta.degraded ? VehicleStatus.degradedEstimate : VehicleStatus.inProgress;
}

class RouteTrackingRecalculated extends RouteTrackingEvent {
  const RouteTrackingRecalculated(this.data);
  final RouteRecalculatedEventDto data;
  @override
  VehicleStatus get suggestedStatus => VehicleStatus.recalculating;
}

class RouteTrackingDestinationReached extends RouteTrackingEvent {
  const RouteTrackingDestinationReached(this.data);
  final DestinationReachedEventDto data;
  @override
  VehicleStatus get suggestedStatus => VehicleStatus.arrived;
}
