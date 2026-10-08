import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/utils/distance_calculator.dart';
import '../../core/utils/price_calculator.dart';
import '../../data/models/location_point.dart';
import '../../data/models/trip.dart';
import '../../data/models/fare_config.dart';
import '../../data/models/trip_draft.dart';
import '../../data/repositories/gps_warmup_service.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/trip_database.dart';
import '../../data/repositories/trip_draft_repository.dart';
import '../../data/models/trip_record.dart';

part 'trip_state.dart';

class TripCubit extends Cubit<TripState> {
  final LocationRepository _locationRepository;
  final TripDraftRepository _draftRepository;
  StreamSubscription? _locationSub;
  StreamSubscription? _statusSub;
  Timer? _priceUpdateTimer;
  FareConfig _fareConfig = const FareConfig();

  /// Borrador por reanudar (si la carrera se interrumpió).
  TripDraft? _pendingDraft;

  /// Distancia ya recorrida antes de los puntos de la sesión actual
  /// (solo > 0 al reanudar una carrera).
  double _baseDistance = 0;
  int _ticks = 0;

  /// Si la carrera se reanuda hasta este tiempo después del último guardado,
  /// se suma en línea recta el tramo entre el último punto guardado y el
  /// punto actual.
  static const Duration _maxGapToBridge = Duration(minutes: 30);

  TripCubit(this._locationRepository, [TripDraftRepository? draftRepository])
      : _draftRepository = draftRepository ?? TripDraftRepository(),
        super(const TripInitial());

  void initialize(FareConfig config) {
    _fareConfig = config;
  }

  /// Reanuda una carrera guardada: usa la tarifa con la que empezó, conserva
  /// el tiempo y la distancia acumulados y vuelve a rastrear el GPS.
  Future<void> resumeFrom(TripDraft draft) {
    _pendingDraft = draft;
    _fareConfig = draft.config;
    return startTrip();
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

    LocationPoint currentLocation;
    try {
      currentLocation = await _locationRepository.getCurrentLocation();
    } catch (e) {
      emit(const TripError(
          'No se pudo obtener señal GPS. Sal a un lugar más despejado e intenta de nuevo.'));
      return;
    }

    // Ya hay primer punto: el rastreo de la carrera toma el relevo del
    // calentamiento (el chip GPS sigue "caliente").
    GpsWarmupService.instance.stop();

    final now = DateTime.now();
    final draft = _pendingDraft;
    _pendingDraft = null;

    String tripId = now.millisecondsSinceEpoch.toString();
    DateTime startTime = now;
    _baseDistance = 0;

    if (draft != null) {
      tripId = draft.id;
      // El tiempo en que la app estuvo cerrada no se cobra por minuto.
      startTime = now.subtract(Duration(seconds: draft.elapsedSeconds));
      _baseDistance = draft.distanceMeters;

      // Tramo recorrido mientras la app no estaba rastreando.
      final sinceSave = now.difference(draft.savedAt);
      if (sinceSave <= _maxGapToBridge && currentLocation.accuracy <= 30) {
        final gap = DistanceCalculator.haversine(
            draft.lastPoint, currentLocation);
        final speedKmh = sinceSave.inSeconds > 0
            ? (gap / sinceSave.inSeconds) * 3.6
            : 0.0;
        if (speedKmh <= 120) _baseDistance += gap;
      }
    }

    final initialPrice = PriceCalculator.calculate(
      route: [currentLocation],
      config: _fareConfig,
      startTime: startTime,
      extraDistanceMeters: _baseDistance,
    );

    final trip = Trip(
      id: tripId,
      routePoints: [currentLocation],
      startTime: startTime,
      totalDistance: _baseDistance,
      totalPrice: initialPrice,
      isActive: true,
    );

    emit(TripInProgress(trip: trip));
    _saveDraft();

    _locationSub?.cancel();
    _statusSub?.cancel();
    _priceUpdateTimer?.cancel();

    _locationRepository.startTracking();
    _locationSub = _locationRepository.locationStream.listen(
      _onNewLocation,
      onError: (error) => emit(TripError('Error GPS: $error')),
    );
    _statusSub = _locationRepository.statusStream.listen(_onGpsStatusUpdate);

    _ticks = 0;
    _priceUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onTick(),
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
        List<LocationPoint>.from(currentState.trip.routePoints)..add(point);

    // Si hubo un hueco de señal (túnel, etc.), el siguiente punto real se une
    // en línea recta al último punto bueno (ver DistanceCalculator).
    final newDistance =
        _baseDistance + DistanceCalculator.calculateRouteDistance(updatedPoints);

    final newPrice = PriceCalculator.calculate(
      route: updatedPoints,
      config: _fareConfig,
      startTime: currentState.trip.startTime,
      extraDistanceMeters: _baseDistance,
    );

    emit(currentState.copyWith(
      trip: currentState.trip.copyWith(
        routePoints: updatedPoints,
        totalDistance: newDistance,
        totalPrice: newPrice,
      ),
    ));
  }

  void _onGpsStatusUpdate(GpsStatus status) {
    if (state is! TripInProgress) return;
    final currentState = state as TripInProgress;
    emit(currentState.copyWith(gpsStatus: status));
  }

  void _onTick() {
    _updatePrice();
    _ticks++;
    // Punto de control cada ~10 segundos.
    if (_ticks % 10 == 0) _saveDraft();
  }

  void _updatePrice() {
    if (state is! TripInProgress) return;

    final currentState = state as TripInProgress;
    final newPrice = PriceCalculator.calculate(
      route: currentState.trip.routePoints,
      config: _fareConfig,
      startTime: currentState.trip.startTime,
      extraDistanceMeters: _baseDistance,
    );

    emit(currentState.copyWith(
      trip: currentState.trip.copyWith(totalPrice: newPrice),
    ));
  }

  void _saveDraft() {
    if (state is! TripInProgress) return;
    final trip = (state as TripInProgress).trip;
    if (trip.routePoints.isEmpty) return;

    final now = DateTime.now();
    unawaited(_draftRepository.save(TripDraft(
      id: trip.id,
      startTime: trip.startTime,
      elapsedSeconds: now.difference(trip.startTime).inSeconds,
      distanceMeters: trip.totalDistance,
      lastPoint: trip.routePoints.last,
      config: _fareConfig,
      savedAt: now,
    )));
  }

  Future<void> endTrip() async {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _priceUpdateTimer?.cancel();
    _locationRepository.stopTracking();

    if (state is TripInProgress) {
      final currentState = state as TripInProgress;
      final endTime = DateTime.now();
      final finalPrice = PriceCalculator.calculate(
        route: currentState.trip.routePoints,
        config: _fareConfig,
        startTime: currentState.trip.startTime,
        extraDistanceMeters: _baseDistance,
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

      // La carrera ya quedó en el historial: el borrador ya no hace falta.
      await _draftRepository.clear();

      emit(TripCompleted(trip: completedTrip));
    }
  }

  @override
  Future<void> close() {
    // Ojo: aquí NO se borra el borrador. Si la pantalla se destruye con una
    // carrera en curso, queda guardada para poder reanudarla.
    _locationSub?.cancel();
    _statusSub?.cancel();
    _priceUpdateTimer?.cancel();
    _locationRepository.dispose();
    return super.close();
  }
}
