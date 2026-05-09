import 'dart:math';
import '../../data/models/location_point.dart';

class DistanceCalculator {
  static const double _earthRadius = 6371000;

  static double haversine(LocationPoint p1, LocationPoint p2) {
    final lat1 = _toRadians(p1.latitude);
    final lat2 = _toRadians(p2.latitude);
    final deltaLat = _toRadians(p2.latitude - p1.latitude);
    final deltaLon = _toRadians(p2.longitude - p1.longitude);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadius * c;
  }

  static double calculateRouteDistance(
    List<LocationPoint> points, {
    double minAccuracy =
        30.0, // Más estricto: ignorar puntos con precisión > 30m
    double minDistance = 3.0, // Ignorar movimientos menores a 3m
    double maxSpeed =
        120.0, // Ignorar saltos que impliquen > 120 km/h (ruido GPS)
  }) {
    if (points.length < 2) return 0.0;

    double total = 0.0;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      // FILTRO 1: Precisión insuficiente
      if (curr.accuracy > minAccuracy) continue;

      // FILTRO 2: Velocidad imposible (ruido GPS)
      final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
      if (timeDiff > 0) {
        final segment = haversine(prev, curr);
        final speedKmh = (segment / timeDiff) * 3.6;
        if (speedKmh > maxSpeed) continue; // Saltar si implica > 120 km/h
      }

      // FILTRO 3: Movimiento mínimo
      final segment = haversine(prev, curr);
      if (segment < minDistance) continue;

      total += segment;
    }

    return total;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
