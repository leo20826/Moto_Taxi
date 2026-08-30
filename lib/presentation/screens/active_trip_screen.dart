import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/models/fare_config.dart';
import '../../data/repositories/location_repository.dart';
import '../blocs/trip_cubit.dart';
import '../widgets/fare_display.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/trip_controls.dart';

class ActiveTripScreen extends StatefulWidget {
  final FareConfig fareConfig;
  const ActiveTripScreen({super.key, required this.fareConfig});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isLoading = false;
  late final TripCubit _tripCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _tripCubit = TripCubit(LocationRepository())
      ..initialize(widget.fareConfig);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _tripCubit.close();
    super.dispose();
  }

  /// Detecta cuando el usuario vuelve de la configuración del sistema
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final currentState = _tripCubit.state;

      // Si estábamos esperando permiso, reintentar automáticamente
      if (currentState is TripError &&
          (currentState.message == 'PERMANENTE' ||
              currentState.message == 'DENEGADO')) {
        // Pequeño delay para que el sistema actualice el estado de permisos
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _tripCubit.retryPermission();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return BlocProvider.value(
      value: _tripCubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: BlocConsumer<TripCubit, TripState>(
                listener: (context, state) {
                  if (state is TripCompleted) {
                    WakelockPlus.disable();
                    _showTripSummary(context, state);
                  }
                },
                builder: (context, state) {
                  if (state is TripInitial) {
                    return _buildStartView(context);
                  }
                  if (state is TripInProgress) {
                    return _buildActiveTripView(context, state);
                  }
                  if (state is TripError) {
                    return _buildErrorState(context, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            if (_isLocked) _buildLockOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.motorcycle, size: 80, color: Colors.yellow),
          const SizedBox(height: 24),
          const Text(
            'LISTO PARA INICIAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarifa: \$${widget.fareConfig.baseFare.toStringAsFixed(2)} base + \$${widget.fareConfig.pricePerKm.toStringAsFixed(2)}/km',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 48),
          if (_isLoading)
            Column(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: Colors.yellow,
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ESPERANDO UBICACIÓN GPS...',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto puede tomar unos segundos',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _isLoading = true);
                await context.read<TripCubit>().startTrip();
                // Cuando termine, el BlocConsumer recibirá TripInProgress y cambiará la vista sola
              },
              icon: const Icon(Icons.play_arrow, size: 32),
              label: const Text(
                'INICIAR CARRERA',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTripView(BuildContext context, TripInProgress state) {
    final trip = state.trip;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GpsStatusIndicator(
                accuracy: trip.routePoints.last.accuracy,
                speed: trip.currentSpeed,
                status: state.gpsStatus,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(trip.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _isLocked = true),
                    icon: const Icon(Icons.lock_outline, color: Colors.yellow),
                    tooltip: 'Bloquear pantalla',
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          FareDisplay(price: trip.totalPrice),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetricCard(
                '${(trip.totalDistance / 1000).toStringAsFixed(2)} km',
                'Distancia',
                Icons.route,
              ),
              const SizedBox(width: 24),
              _buildMetricCard(
                '${trip.currentSpeed.toStringAsFixed(0)} km/h',
                'Velocidad',
                Icons.speed,
              ),
            ],
          ),
          const Spacer(),
          TripControls(
            onEndTrip: () => _confirmEndTrip(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, TripError state) {
    // Pantalla de permiso permanente denegado
    if (state.message == 'PERMANENTE') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              const Text(
                'PERMISO DE UBICACIÓN REQUERIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'La app necesita acceso a tu ubicación para calcular la distancia de la carrera. Por favor, actívalo en la configuración.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('ABRIR CONFIGURACIÓN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<TripCubit>().retryPermission(),
                child: const Text(
                  'YA LO CONCEDÍ, REINTENTAR',
                  style: TextStyle(color: Colors.yellow, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Permiso denegado temporalmente
    if (state.message == 'DENEGADO') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'PERMISO DENEGADO',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Debes permitir el acceso a la ubicación para usar la app.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<TripCubit>().startTrip(),
              icon: const Icon(Icons.refresh),
              label: const Text('INTENTAR DE NUEVO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text(
                'ABRIR CONFIGURACIÓN DEL SISTEMA',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Otros errores
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VOLVER'),
          ),
        ],
      ),
    );
  }

  Widget _buildLockOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.yellow, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'PANTALLA BLOQUEADA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<TripCubit, TripState>(
                  builder: (context, state) {
                    double price = 0;
                    if (state is TripInProgress) price = state.trip.totalPrice;
                    return Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Mono',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                BlocBuilder<TripCubit, TripState>(
                  builder: (context, state) {
                    double dist = 0;
                    if (state is TripInProgress) {
                      dist = state.trip.totalDistance;
                    }
                    return Text(
                      '${(dist / 1000).toStringAsFixed(2)} km',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    );
                  },
                ),
                const SizedBox(height: 64),
                GestureDetector(
                  onLongPress: () => setState(() => _isLocked = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'MANTÉN PRESIONADO PARA DESBLOQUEAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.yellow, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _confirmEndTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Finalizar Carrera?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esto calculará el precio final y terminará el seguimiento.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TripCubit>().endTrip();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  void _showTripSummary(BuildContext context, TripCompleted state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.grey[900],
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'CARRERA FINALIZADA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryRow('Distancia total:',
                '${(state.trip.totalDistance / 1000).toStringAsFixed(2)} km'),
            _buildSummaryRow('Duración:', _formatDuration(state.trip.duration)),
            const Divider(color: Colors.grey, height: 32),
            _buildSummaryRow(
              'TOTAL A COBRAR:',
              '\$${state.trip.totalPrice.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'NUEVA CARRERA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.yellow : Colors.grey[400],
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 24 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
