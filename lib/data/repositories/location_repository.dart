import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_point.dart';

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Repositorio de ubicación configurado para usar EXCLUSIVAMENTE el chip GPS
/// del dispositivo, con la mejor precisión posible.
///
/// Nota: por defecto, Android usa el FusedLocationProviderClient, que mezcla
/// GPS + red móvil + Wi-Fi para entregar una ubicación más rápida (aunque
/// menos "pura"). Aquí forzamos el LocationManager clásico
/// (forceLocationManager: true) para que Android use el proveedor GPS real
/// y no caiga en triangulación por red. Esto puede tardar un poco más en
/// obtener el primer punto, especialmente en interiores.
class LocationRepository {
  StreamSubscription<Position>? _positionStream;
  Timer? _signalHealthTimer;
  final _locationController = StreamController<LocationPoint>.broadcast();
  final _statusController = StreamController<GpsStatus>.broadcast();

  DateTime? _lastKnownTime;
  LocationPoint? _lastKnownPoint;
  bool _wasPaused = false;

  Stream<LocationPoint> get locationStream => _locationController.stream;
  Stream<GpsStatus> get statusStream => _statusController.stream;

  /// Verifica y solicita permisos de forma robusta para TODAS las versiones de Android
  Future<PermissionResult> checkAndRequestPermission() async {
    // 1. Verificar que el GPS del sistema esté activado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return PermissionResult.serviceDisabled;
    }

    // 2. Solicitar permiso de ubicación en primer plano (FINE + COARSE)
    //    Esto funciona en Android 5.0 hasta 16
    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }

    if (status.isDenied) {
      return PermissionResult.denied;
    }

    // 3. Si tenemos permiso de primer plano, verificar background
    //    En Android 10+ (API 29+) el background es aparte
    PermissionStatus backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isDenied && !backgroundStatus.isPermanentlyDenied) {
      // Solicitamos background solo si es necesario para tu caso
      // Para moto taxi, foreground service con notificación es suficiente
      // Si quieres tracking con pantalla apagada, descomenta la siguiente línea:
      // await Permission.locationAlways.request();
    }

    return PermissionResult.granted;
  }

  /// Fuerza recarga del estado de permisos (útil al volver de configuración)
  Future<PermissionResult> recheckPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return PermissionResult.serviceDisabled;
    }

    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return PermissionResult.granted;
    } else if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    } else {
      return PermissionResult.denied;
    }
  }

  Future<LocationPoint> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _buildLocationSettings(),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'No se pudo obtener señal GPS. Sal a un lugar más despejado.',
      ),
    );

    _lastKnownPoint = _mapToLocationPoint(position);
    _lastKnownTime = DateTime.now();

    return _lastKnownPoint!;
  }

  void startTracking() {
    _positionStream?.cancel();
    _signalHealthTimer?.cancel();
    _wasPaused = false;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        _statusController.add(GpsStatus.error);
        _locationController.addError(error);
      },
    );

    _signalHealthTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _checkSignalHealth());
  }

  /// Configuración de ubicación forzando GPS puro (sin red móvil/Wi-Fi).
  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        forceLocationManager: true, // Usa el proveedor GPS real, no el Fused
      );
    }
    // iOS/otras plataformas no tienen un equivalente a "solo GPS": el
    // sistema operativo administra la fuente internamente, pero
    // bestForNavigation ya pide la máxima precisión disponible.
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );
  }

  void _onPositionUpdate(Position position) {
    if (_lastKnownTime != null) {
      final gap = DateTime.now().difference(_lastKnownTime!);
      if (gap.inSeconds > 6 && _wasPaused) {
        _statusController.add(GpsStatus.recovered);
      }
    }

    if (position.accuracy > 100) {
      _statusController.add(GpsStatus.poorAccuracy);
    } else if (position.accuracy > 25) {
      _statusController.add(GpsStatus.fairAccuracy);
    } else {
      _statusController.add(GpsStatus.good);
    }

    final point = _mapToLocationPoint(position);
    _lastKnownPoint = point;
    _lastKnownTime = DateTime.now();
    _wasPaused = false;

    _locationController.add(point);
  }

  void _checkSignalHealth() {
    if (_lastKnownTime == null) return;

    final gap = DateTime.now().difference(_lastKnownTime!);
    if (gap.inSeconds > 5 && !_wasPaused) {
      _wasPaused = true;
      _statusController.add(GpsStatus.lost);
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _signalHealthTimer?.cancel();
    _signalHealthTimer = null;
    _wasPaused = false;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _statusController.close();
  }

  LocationPoint _mapToLocationPoint(Position position) => LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp ?? DateTime.now(),
        heading: position.heading,
      );
}

enum GpsStatus {
  good,
  fairAccuracy,
  poorAccuracy,
  lost,
  recovered,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}
