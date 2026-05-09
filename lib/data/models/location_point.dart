import 'package:equatable/equatable.dart';

enum LocationSource { gps, network }

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;
  final double? heading;
  final LocationSource source;
  final bool isInterpolated;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.heading,
    this.source = LocationSource.gps,
    this.isInterpolated = false,
  });

  @override
  List<Object?> get props => [latitude, longitude, timestamp, source];

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
    double? heading,
    LocationSource? source,
    bool? isInterpolated,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      heading: heading ?? this.heading,
      source: source ?? this.source,
      isInterpolated: isInterpolated ?? this.isInterpolated,
    );
  }
}
