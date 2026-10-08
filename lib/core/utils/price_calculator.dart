import '../../data/models/fare_config.dart';
import '../../data/models/location_point.dart';
import 'distance_calculator.dart';

class PriceCalculator {
  /// [extraDistanceMeters] es la distancia ya recorrida antes de [route]
  /// (por ejemplo, al reanudar una carrera que quedó guardada).
  static double calculate({
    required List<LocationPoint> route,
    required FareConfig config,
    required DateTime startTime,
    double extraDistanceMeters = 0,
    DateTime? now,
  }) {
    final distanceKm =
        (extraDistanceMeters + DistanceCalculator.calculateRouteDistance(route)) /
            1000;
    final durationMinutes =
        (now ?? DateTime.now()).difference(startTime).inSeconds / 60.0;

    double price = config.baseFare;
    price += distanceKm * config.pricePerKm;
    price += durationMinutes * config.pricePerMinute;

    if (price < config.minimumFare) {
      price = config.minimumFare;
    }

    if (config.roundTo > 0.0) {
      // Primero a centavos: evita que 30.0000001 suba un peso de más por
      // errores de punto flotante.
      final cents = double.parse(price.toStringAsFixed(2));
      price = ((cents / config.roundTo) - 1e-9).ceil() * config.roundTo;
    }

    return price;
  }
}
