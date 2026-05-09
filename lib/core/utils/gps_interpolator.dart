import '../../data/models/location_point.dart';
import 'distance_calculator.dart';

class GpsInterpolator {
  static List<LocationPoint> interpolateGap({
    required LocationPoint lastKnown,
    required LocationPoint firstNew,
    required Duration gapDuration,
    required double lastSpeed,
  }) {
    if (gapDuration.inSeconds < 5) {
      return [firstNew.copyWith(isInterpolated: false)];
    }
    if (lastSpeed < 0.5) return [firstNew.copyWith(isInterpolated: false)];

    final estimatedDistance = lastSpeed * gapDuration.inSeconds;
    final realDistance = DistanceCalculator.haversine(lastKnown, firstNew);
    final ratio = realDistance / (estimatedDistance + 1);

    List<LocationPoint> interpolated = [];
    final segments = (gapDuration.inSeconds / 5).floor();

    if (segments > 1 && ratio > 0.5 && ratio < 2.0) {
      for (int i = 1; i < segments; i++) {
        final fraction = i / segments;
        interpolated.add(
          LocationPoint(
            latitude:
                lastKnown.latitude +
                (firstNew.latitude - lastKnown.latitude) * fraction,
            longitude:
                lastKnown.longitude +
                (firstNew.longitude - lastKnown.longitude) * fraction,
            accuracy: 50,
            altitude: (lastKnown.altitude + firstNew.altitude) / 2,
            speed: lastSpeed,
            timestamp: lastKnown.timestamp.add(Duration(seconds: i * 5)),
            heading: lastKnown.heading,
            source: LocationSource.gps,
            isInterpolated: true,
          ),
        );
      }
    }

    interpolated.add(firstNew.copyWith(isInterpolated: false));
    return interpolated;
  }
}
