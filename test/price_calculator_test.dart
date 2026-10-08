import 'package:flutter_test/flutter_test.dart';
import 'package:moto_taxi_app/core/utils/price_calculator.dart';
import 'package:moto_taxi_app/data/models/fare_config.dart';
import 'package:moto_taxi_app/data/models/location_point.dart';

final _start = DateTime(2026, 1, 1, 10, 0, 0);

LocationPoint _p(double lat, int seconds) => LocationPoint(
      latitude: lat,
      longitude: 0,
      accuracy: 5,
      altitude: 0,
      speed: 5,
      timestamp: _start.add(Duration(seconds: seconds)),
    );

/// Config sin extras para aislar cada regla.
FareConfig _cfg({
  double base = 0,
  double km = 0,
  double minute = 0,
  double minimum = 0,
  double round = 0,
}) =>
    FareConfig(
      baseFare: base,
      pricePerKm: km,
      pricePerMinute: minute,
      minimumFare: minimum,
      roundTo: round,
    );

double _price(
  FareConfig config, {
  List<LocationPoint> route = const [],
  Duration elapsed = Duration.zero,
  double extraMeters = 0,
}) =>
    PriceCalculator.calculate(
      route: route,
      config: config,
      startTime: _start,
      now: _start.add(elapsed),
      extraDistanceMeters: extraMeters,
    );

void main() {
  group('PriceCalculator', () {
    test('tarifa base sola', () {
      expect(_price(_cfg(base: 15)), 15);
    });

    test('suma base + kilómetros (~1000.75 m a \$10/km)', () {
      final route = [_p(0, 0), _p(0.009, 100)];
      expect(_price(_cfg(base: 15, km: 10), route: route), closeTo(25.0075, 0.01));
    });

    test('suma el tiempo por minuto', () {
      expect(
        _price(_cfg(base: 15, minute: 1.5), elapsed: const Duration(minutes: 10)),
        30,
      );
    });

    test('aplica la tarifa mínima', () {
      expect(_price(_cfg(base: 5, minimum: 20)), 20);
    });

    test('suma la distancia previa al reanudar una carrera', () {
      expect(_price(_cfg(base: 15, km: 10), extraMeters: 2000), 35);
    });

    group('redondeo', () {
      test('30.00 con redondeo a 1 se queda en 30 (no sube a 31)', () {
        expect(_price(_cfg(base: 30, round: 1)), 30);
        expect(_price(_cfg(base: 30.0000001, round: 1)), 30);
      });

      test('sube al siguiente entero si hay fracción', () {
        expect(_price(_cfg(base: 30.4, round: 1)), 31);
      });

      test('redondeo a decenas', () {
        expect(_price(_cfg(base: 21, round: 10)), 30);
        expect(_price(_cfg(base: 30, round: 10)), 30);
      });

      test('redondeo 0 = sin redondeo', () {
        expect(_price(_cfg(base: 30.4, round: 0)), closeTo(30.4, 1e-9));
      });
    });
  });
}
