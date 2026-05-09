import '../../data/models/fare_config.dart';
import '../../data/models/location_point.dart';
import 'distance_calculator.dart';

class PriceCalculator {
  static double calculate({
    required List<LocationPoint> route,
    required FareConfig config,
    required DateTime startTime,
  }) {
    final distanceKm = DistanceCalculator.calculateRouteDistance(route) / 1000;
    final durationMinutes =
        DateTime.now().difference(startTime).inSeconds / 60.0;

    double price = config.baseFare;
    price += distanceKm * config.pricePerKm;
    price += durationMinutes * config.pricePerMinute;

    if (price < config.minimumFare) {
      price = config.minimumFare;
    }

    if (config.roundTo > 0.0) {
      price = (price / config.roundTo).ceil() * config.roundTo.toDouble();
    }

    return price;
  }
}
