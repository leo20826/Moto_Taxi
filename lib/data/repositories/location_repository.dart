import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_point.dart';

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationRepository {
  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<LocationPoint>.broadcast();
  final _statusController = StreamController<GpsStatus>.broadcast();

  DateTime? _lastKnownTime;
  LocationPoint? _lastKnownPoint;
  bool _wasPaused = false;
  LocationSource _currentSource = LocationSource.gps;

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
    Position? position;
    LocationSource sourceUsed = LocationSource.gps;

    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      sourceUsed = LocationSource.network;
      _statusController.add(GpsStatus.fallbackToNetwork);
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    }

    _lastKnownPoint = _mapToLocationPoint(position, sourceUsed);
    _lastKnownTime = DateTime.now();
    _currentSource = sourceUsed;

    return _lastKnownPoint!;
  }

  void startTracking() {
    _positionStream?.cancel();
    _wasPaused = false;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        _statusController.add(GpsStatus.error);
        _locationController.addError(error);
      },
    );

    Timer.periodic(const Duration(seconds: 3), (_) => _checkSignalHealth());
  }

  void _onPositionUpdate(Position position) {
    final newSource =
        position.accuracy < 15 ? LocationSource.gps : LocationSource.network;

    if (_currentSource != newSource) {
      _currentSource = newSource;
      _statusController.add(newSource == LocationSource.gps
          ? GpsStatus.recovered
          : GpsStatus.usingNetwork);
    }

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

    final point = _mapToLocationPoint(position, newSource);
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
    _wasPaused = false;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _statusController.close();
  }

  LocationPoint _mapToLocationPoint(Position position, LocationSource source) =>
      LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp ?? DateTime.now(),
        heading: position.heading,
        source: source,
      );
}

enum GpsStatus {
  good,
  fairAccuracy,
  poorAccuracy,
  lost,
  recovered,
  usingNetwork,
  fallbackToNetwork,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}
