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

  const TripInProgress({required this.trip});

  @override
  List<Object?> get props => [trip];

  TripInProgress copyWith({Trip? trip}) =>
      TripInProgress(trip: trip ?? this.trip);
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
