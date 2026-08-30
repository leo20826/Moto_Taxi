import 'package:equatable/equatable.dart';

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;
  final double? heading;
  final bool isInterpolated;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.heading,
    this.isInterpolated = false,
  });

  @override
  List<Object?> get props => [latitude, longitude, timestamp];

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
    double? heading,
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
      isInterpolated: isInterpolated ?? this.isInterpolated,
    );
  }
}
