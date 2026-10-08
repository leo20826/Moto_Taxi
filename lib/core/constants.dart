class AppConstants {
  static const String appName = 'Moto Taxi';
  static const double minAccuracy = 20.0;
  static const double minDistance = 5.0;
  static const int priceUpdateIntervalSeconds = 5;
  static const int distanceFilterMeters = 3;

  /// true = proveedor GPS puro (LocationManager). false = Fused (GPS + red),
  /// más rápido al arrancar pero menos "puro". Cambiar si en la calle tarda
  /// mucho en obtener el primer punto.
  static const bool forceGpsOnly = true;
}
