class TripRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distance; // metros
  final int durationSeconds;
  final double price;

  TripRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.durationSeconds,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distance': distance,
        'durationSeconds': durationSeconds,
        'price': price,
      };

  factory TripRecord.fromMap(Map<String, dynamic> map) => TripRecord(
        id: map['id'],
        startTime: DateTime.parse(map['startTime']),
        endTime: DateTime.parse(map['endTime']),
        distance: map['distance'],
        durationSeconds: map['durationSeconds'],
        price: map['price'],
      );
}
