import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/utils/distance_calculator.dart';
import '../../core/utils/price_calculator.dart';
import '../../core/utils/gps_interpolator.dart';
import '../../data/models/location_point.dart';
import '../../data/models/trip.dart';
import '../../data/models/fare_config.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/trip_database.dart';
import '../../data/models/trip_record.dart';

part 'trip_state.dart';

class TripCubit extends Cubit<TripState> {
  final LocationRepository _locationRepository;
  StreamSubscription? _locationSub;
  Timer? _priceUpdateTimer;
  FareConfig _fareConfig = const FareConfig();

  LocationPoint? _lastPoint;
  DateTime? _lastPointTime;
  double _lastSpeed = 0;

  TripCubit(this._locationRepository) : super(const TripInitial());

  void initialize(FareConfig config) {
    _fareConfig = config;
  }

  /// Inicia la carrera verificando permisos de forma robusta
  Future<void> startTrip() async {
    final permissionResult =
        await _locationRepository.checkAndRequestPermission();

    switch (permissionResult) {
      case PermissionResult.granted:
        break;
      case PermissionResult.denied:
        emit(const TripError('DENEGADO'));
        return;
      case PermissionResult.permanentlyDenied:
        emit(const TripError('PERMANENTE'));
        return;
      case PermissionResult.serviceDisabled:
        emit(const TripError(
            'GPS desactivado. Activa la ubicación en el sistema.'));
        return;
    }

    final currentLocation = await _locationRepository.getCurrentLocation();
    _lastPoint = currentLocation;
    _lastPointTime = DateTime.now();
    _lastSpeed = currentLocation.speed;

    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routePoints: [currentLocation],
      startTime: DateTime.now(),
      isActive: true,
    );

    emit(TripInProgress(trip: trip));

    _locationRepository.startTracking();
    _locationSub = _locationRepository.locationStream.listen(
      _onNewLocation,
      onError: (error) => emit(TripError('Error GPS: $error')),
    );

    _priceUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updatePrice(),
    );
  }

  /// Reintenta verificar permisos al volver de la configuración del sistema
  Future<void> retryPermission() async {
    final permissionResult = await _locationRepository.recheckPermission();

    switch (permissionResult) {
      case PermissionResult.granted:
        // Si ya tenemos permiso, iniciar la carrera automáticamente
        await startTrip();
        break;
      case PermissionResult.denied:
        emit(const TripError('DENEGADO'));
        break;
      case PermissionResult.permanentlyDenied:
        emit(const TripError('PERMANENTE'));
        break;
      case PermissionResult.serviceDisabled:
        emit(const TripError(
            'GPS desactivado. Activa la ubicación en el sistema.'));
        break;
    }
  }

  void _onNewLocation(LocationPoint point) {
    if (state is! TripInProgress) return;

    final currentState = state as TripInProgress;
    final updatedPoints =
        List<LocationPoint>.from(currentState.trip.routePoints);

    // Detectar gap e interpolar si es necesario
    if (_lastPoint != null && _lastPointTime != null) {
      final gap = point.timestamp.difference(_lastPointTime!);

      if (gap.inSeconds > 10) {
        final interpolated = GpsInterpolator.interpolateGap(
          lastKnown: _lastPoint!,
          firstNew: point,
          gapDuration: gap,
          lastSpeed: _lastSpeed,
        );

        for (int i = 0; i < interpolated.length - 1; i++) {
          updatedPoints.add(interpolated[i]);
        }
      }
    }

    updatedPoints.add(point);

    final newDistance =
        DistanceCalculator.calculateRouteDistance(updatedPoints);
    _lastPoint = point;
    _lastPointTime = point.timestamp;
    _lastSpeed = point.speed;

    final newPrice = PriceCalculator.calculate(
      route: updatedPoints,
      config: _fareConfig,
      startTime: currentState.trip.startTime,
    );

    emit(currentState.copyWith(
      trip: currentState.trip.copyWith(
        routePoints: updatedPoints,
        totalDistance: newDistance,
        totalPrice: newPrice,
      ),
    ));
  }

  void _updatePrice() {
    if (state is! TripInProgress) return;

    final currentState = state as TripInProgress;
    final newPrice = PriceCalculator.calculate(
      route: currentState.trip.routePoints,
      config: _fareConfig,
      startTime: currentState.trip.startTime,
    );

    emit(currentState.copyWith(
      trip: currentState.trip.copyWith(totalPrice: newPrice),
    ));
  }

  Future<void> endTrip() async {
    _locationSub?.cancel();
    _priceUpdateTimer?.cancel();
    _locationRepository.stopTracking();

    if (state is TripInProgress) {
      final currentState = state as TripInProgress;
      final endTime = DateTime.now();
      final finalPrice = PriceCalculator.calculate(
        route: currentState.trip.routePoints,
        config: _fareConfig,
        startTime: currentState.trip.startTime,
      );

      final completedTrip = currentState.trip.copyWith(
        isActive: false,
        endTime: endTime,
        totalPrice: finalPrice,
      );

      await TripDatabase.instance.insert(TripRecord(
        id: completedTrip.id,
        startTime: completedTrip.startTime,
        endTime: completedTrip.endTime!,
        distance: completedTrip.totalDistance,
        durationSeconds: completedTrip.duration.inSeconds,
        price: completedTrip.totalPrice,
      ));

      emit(TripCompleted(trip: completedTrip));
    }
  }

  @override
  Future<void> close() {
    _locationSub?.cancel();
    _priceUpdateTimer?.cancel();
    _locationRepository.dispose();
    return super.close();
  }
}
