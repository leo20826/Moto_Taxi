import 'package:equatable/equatable.dart';

class FareConfig extends Equatable {
  final double baseFare;
  final double pricePerKm;
  final double pricePerMinute;
  final double minimumFare;
  final double roundTo;

  const FareConfig({
    this.baseFare = 15.0,
    this.pricePerKm = 10.0,
    this.pricePerMinute = 1.5,
    this.minimumFare = 20.0,
    this.roundTo = 1.0,
  });

  @override
  List<Object> get props => [
        baseFare,
        pricePerKm,
        pricePerMinute,
        minimumFare,
        roundTo,
      ];

  Map<String, dynamic> toJson() => {
        'baseFare': baseFare,
        'pricePerKm': pricePerKm,
        'pricePerMinute': pricePerMinute,
        'minimumFare': minimumFare,
        'roundTo': roundTo,
      };

  factory FareConfig.fromJson(Map<String, dynamic> json) => FareConfig(
        baseFare: json['baseFare']?.toDouble() ?? 15.0,
        pricePerKm: json['pricePerKm']?.toDouble() ?? 8.0,
        pricePerMinute: json['pricePerMinute']?.toDouble() ?? 1.5,
        minimumFare: json['minimumFare']?.toDouble() ?? 20.0,
        roundTo: json['roundTo'] ?? 50,
      );
}
