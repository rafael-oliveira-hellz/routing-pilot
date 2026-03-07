// Enums de domínio alinhados ao backend (doc 02, 09, 11).

enum IncidentType {
  blitz,
  accident,
  heavyTraffic,
  wetRoad,
  flood,
  roadWork,
  brokenTrafficLight,
  animalOnRoad,
  vehicleStopped,
  landslide,
  fog,
  other,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum VehicleStatus {
  inProgress,
  degradedEstimate,
  recalculating,
  arrived,
  stopped,
  failed,
}

enum RouteType {
  fastest,
  noToll,
  ecoFuel,
  shortest,
}

enum Traffic {
  enabled,
  disabled,
}

enum OptimizationStrategy {
  fastest,
  noToll,
  ecoFuel,
  shortest,
}

enum OptimizationStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum VoteType {
  confirm,
  deny,
  gone,
}

enum RecalcReason {
  routeDeviation,
  incidentCritical,
  manualDestinationChange,
  strategicReoptimization,
  trafficSevere,
}

enum ProcessingErrorCode {
  validationFailed,
  duplicateEvent,
  staleEvent,
  unknown,
}
