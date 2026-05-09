import 'location_point.dart';

class Trip {
  final String id;
  final List<LocationPoint> routePoints;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistance;
  final double totalPrice;
  final bool isActive;

  Trip({
    required this.id,
    required this.routePoints,
    required this.startTime,
    this.endTime,
    this.totalDistance = 0.0,
    this.totalPrice = 0.0,
    this.isActive = false,
  });

  Trip copyWith({
    String? id,
    List<LocationPoint>? routePoints,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistance,
    double? totalPrice,
    bool? isActive,
  }) {
    return Trip(
      id: id ?? this.id,
      routePoints: routePoints ?? this.routePoints,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistance: totalDistance ?? this.totalDistance,
      totalPrice: totalPrice ?? this.totalPrice,
      isActive: isActive ?? this.isActive,
    );
  }

  Duration get duration => endTime != null
      ? endTime!.difference(startTime)
      : DateTime.now().difference(startTime);

  double get currentSpeed {
    if (routePoints.isEmpty) return 0.0;
    return routePoints.last.speed * 3.6;
  }
}
