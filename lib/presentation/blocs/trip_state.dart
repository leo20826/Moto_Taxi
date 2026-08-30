part of 'trip_cubit.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripInProgress extends TripState {
  final Trip trip;
  final GpsStatus gpsStatus;

  const TripInProgress({
    required this.trip,
    this.gpsStatus = GpsStatus.good,
  });

  @override
  List<Object?> get props => [trip, gpsStatus];

  TripInProgress copyWith({Trip? trip, GpsStatus? gpsStatus}) =>
      TripInProgress(
        trip: trip ?? this.trip,
        gpsStatus: gpsStatus ?? this.gpsStatus,
      );
}

class TripCompleted extends TripState {
  final Trip trip;

  const TripCompleted({required this.trip});

  @override
  List<Object?> get props => [trip];
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}
