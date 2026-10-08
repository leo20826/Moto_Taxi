import 'fare_config.dart';
import 'location_point.dart';

/// Punto de control de una carrera en curso. Se guarda cada pocos segundos
/// para poder reanudar si la app se cierra o el sistema la mata.
class TripDraft {
  final String id;
  final DateTime startTime;
  final int elapsedSeconds;
  final double distanceMeters;
  final LocationPoint lastPoint;
  final FareConfig config;
  final DateTime savedAt;

  const TripDraft({
    required this.id,
    required this.startTime,
    required this.elapsedSeconds,
    required this.distanceMeters,
    required this.lastPoint,
    required this.config,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'distanceMeters': distanceMeters,
        'savedAt': savedAt.toIso8601String(),
        'config': config.toJson(),
        'lastPoint': {
          'lat': lastPoint.latitude,
          'lon': lastPoint.longitude,
          'acc': lastPoint.accuracy,
          'alt': lastPoint.altitude,
          'speed': lastPoint.speed,
          'ts': lastPoint.timestamp.toIso8601String(),
          'heading': lastPoint.heading,
        },
      };

  factory TripDraft.fromJson(Map<String, dynamic> json) {
    final p = json['lastPoint'] as Map<String, dynamic>;
    return TripDraft(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      savedAt: DateTime.parse(json['savedAt'] as String),
      config: FareConfig.fromJson(json['config'] as Map<String, dynamic>),
      lastPoint: LocationPoint(
        latitude: (p['lat'] as num).toDouble(),
        longitude: (p['lon'] as num).toDouble(),
        accuracy: (p['acc'] as num).toDouble(),
        altitude: (p['alt'] as num).toDouble(),
        speed: (p['speed'] as num).toDouble(),
        timestamp: DateTime.parse(p['ts'] as String),
        heading: (p['heading'] as num?)?.toDouble(),
      ),
    );
  }
}
