import 'package:flutter_test/flutter_test.dart';
import 'package:moto_taxi_app/core/utils/distance_calculator.dart';
import 'package:moto_taxi_app/data/models/location_point.dart';

final _t0 = DateTime(2026, 1, 1, 10, 0, 0);

LocationPoint _p(
  double lat, {
  double lon = 0,
  int seconds = 0,
  double accuracy = 5,
}) =>
    LocationPoint(
      latitude: lat,
      longitude: lon,
      accuracy: accuracy,
      altitude: 0,
      speed: 5,
      timestamp: _t0.add(Duration(seconds: seconds)),
    );

void main() {
  group('DistanceCalculator.haversine', () {
    test('1 grado de latitud son ~111.2 km', () {
      final d = DistanceCalculator.haversine(_p(0), _p(1));
      expect(d, closeTo(111195, 50));
    });

    test('mismo punto = 0 m', () {
      expect(DistanceCalculator.haversine(_p(10), _p(10)), 0);
    });
  });

  group('DistanceCalculator.calculateRouteDistance', () {
    test('menos de 2 puntos = 0', () {
      expect(DistanceCalculator.calculateRouteDistance([]), 0);
      expect(DistanceCalculator.calculateRouteDistance([_p(0)]), 0);
    });

    test('dos puntos buenos suman su distancia (~1000.75 m)', () {
      final d = DistanceCalculator.calculateRouteDistance([
        _p(0),
        _p(0.009, seconds: 100),
      ]);
      expect(d, closeTo(1000.75, 1));
    });

    test('ignora puntos con mala precisión (> 30 m)', () {
      final d = DistanceCalculator.calculateRouteDistance([
        _p(0),
        _p(0.004, seconds: 50, accuracy: 80), // ruido: se descarta
        _p(0.009, seconds: 100),
      ]);
      expect(d, closeTo(1000.75, 1));
    });

    test('ignora saltos imposibles (> 120 km/h)', () {
      final d = DistanceCalculator.calculateRouteDistance([
        _p(0),
        _p(0.5, seconds: 10), // ~55 km en 10 s
      ]);
      expect(d, 0);
    });

    test('ignora movimientos menores a 3 m', () {
      final d = DistanceCalculator.calculateRouteDistance([
        _p(0),
        _p(0.00001, seconds: 5), // ~1.1 m
      ]);
      expect(d, 0);
    });

    test('tras un hueco de señal une en línea recta con el último punto bueno',
        () {
      final d = DistanceCalculator.calculateRouteDistance([
        _p(0),
        _p(0.009, seconds: 100),
        // 60 s sin señal (túnel) y reaparece ~1 km más adelante
        _p(0.018, seconds: 160),
      ]);
      expect(d, closeTo(2001.5, 2));
    });
  });
}
