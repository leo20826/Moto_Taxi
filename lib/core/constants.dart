class AppConstants {
  static const String appName = 'Moto Taxi';
  static const double minAccuracy = 20.0;
  static const double minDistance = 5.0;
  static const int priceUpdateIntervalSeconds = 5;
  static const int distanceFilterMeters = 3;

  /// Cada cuántos segundos pide una posición al GPS mientras hay carrera.
  /// (Si no se indica, Android usa 5 s, y eso hacía parpadear "SIN SEÑAL".)
  static const int gpsIntervalSeconds = 1;

  /// Segundos sin recibir posición, EN MOVIMIENTO, para marcar "SIN SEÑAL".
  static const int gpsLostAfterSeconds = 12;

  /// Por debajo de esta velocidad (m/s) se considera que la moto está parada;
  /// parado no llegan posiciones nuevas (distanceFilter) y eso es normal.
  static const double stoppedSpeedMps = 1.0;

  /// true = proveedor GPS puro (LocationManager). false = Fused (GPS + red),
  /// más rápido al arrancar pero menos "puro". Cambiar si en la calle tarda
  /// mucho en obtener el primer punto.
  static const bool forceGpsOnly = true;
}
