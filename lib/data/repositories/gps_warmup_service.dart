import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';

enum WarmupStatus { idle, searching, ready, serviceOff, noPermission }

class GpsWarmupState {
  final WarmupStatus status;
  final double? accuracy;
  const GpsWarmupState(this.status, [this.accuracy]);
}

/// "Calienta" el GPS mientras el conductor está en la pantalla principal, para
/// que al pulsar INICIAR el chip ya tenga satélites y la carrera arranque al
/// instante. Se detiene en cuanto la carrera obtiene su primer punto (o al
/// salir de la app), para no gastar batería de más.
class GpsWarmupService {
  GpsWarmupService._();
  static final GpsWarmupService instance = GpsWarmupService._();

  /// Precisión (en metros) a partir de la cual se considera "GPS listo".
  static const double readyAccuracyMeters = 25;

  final ValueNotifier<GpsWarmupState> state =
      ValueNotifier(const GpsWarmupState(WarmupStatus.idle));

  StreamSubscription<Position>? _sub;
  bool _starting = false;
  int _generation = 0;

  Future<void> start() async {
    if (_sub != null || _starting) return;
    _starting = true;
    final gen = ++_generation;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (gen == _generation) {
          state.value = const GpsWarmupState(WarmupStatus.serviceOff);
        }
        return;
      }

      var permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        permission = await Permission.locationWhenInUse.request();
      }
      if (!permission.isGranted) {
        if (gen == _generation) {
          state.value = const GpsWarmupState(WarmupStatus.noPermission);
        }
        return;
      }

      // Si mientras tanto se pidió detener, no arrancar.
      if (gen != _generation) return;

      state.value = const GpsWarmupState(WarmupStatus.searching);
      _sub = Geolocator.getPositionStream(locationSettings: _settings())
          .listen(
        _onPosition,
        onError: (_) {
          state.value = const GpsWarmupState(WarmupStatus.serviceOff);
        },
      );
    } catch (_) {
      // El calentamiento es un extra: si falla, la carrera funciona igual.
      state.value = const GpsWarmupState(WarmupStatus.idle);
    } finally {
      _starting = false;
    }
  }

  void stop() {
    _generation++;
    _sub?.cancel();
    _sub = null;
    state.value = const GpsWarmupState(WarmupStatus.idle);
  }

  void _onPosition(Position position) {
    final accuracy = position.accuracy;
    state.value = GpsWarmupState(
      accuracy <= readyAccuracyMeters
          ? WarmupStatus.ready
          : WarmupStatus.searching,
      accuracy,
    );
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Sin servicio en primer plano ni notificación: solo es para la
      // pantalla principal.
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 2),
        forceLocationManager: AppConstants.forceGpsOnly,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }
}
