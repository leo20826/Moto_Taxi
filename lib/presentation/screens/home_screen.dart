import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/fare_config.dart';
import '../../data/models/trip_draft.dart';
import '../../data/repositories/fare_repository.dart';
import '../../data/repositories/gps_warmup_service.dart';
import '../../data/repositories/trip_draft_repository.dart';
import 'active_trip_screen.dart';
import 'fare_settings_screen.dart';
import 'trip_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repo = FareRepository();
  final _draftRepo = TripDraftRepository();
  FareConfig _config = const FareConfig();
  bool _tripOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Calentar el GPS desde que se abre la app.
    GpsWarmupService.instance.start();
    _loadConfig();
    // Si la app se cerró en medio de una carrera, ofrecer reanudarla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDraft());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GpsWarmupService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App en segundo plano fuera de una carrera: no gastar batería.
      GpsWarmupService.instance.stop();
    } else if (state == AppLifecycleState.resumed && !_tripOpen && mounted) {
      GpsWarmupService.instance.start();
    }
  }

  /// Abre la pantalla de carrera. Al volver, reanuda el calentamiento y
  /// ofrece retomar una carrera que haya quedado interrumpida.
  Future<void> _openTrip(Widget screen) async {
    _tripOpen = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _tripOpen = false;
    if (!mounted) return;
    GpsWarmupService.instance.start();
    _checkDraft();
  }

  Future<void> _loadConfig() async {
    _config = await _repo.getConfig();
    if (mounted) setState(() {});
  }

  Future<void> _checkDraft() async {
    final draft = await _draftRepo.load();
    if (draft == null || !mounted) return;

    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Carrera sin finalizar',
            style: TextStyle(color: Colors.white)),
        content: Text(
          _draftSummary(draft),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('DESCARTAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REANUDAR'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (resume == true) {
      await _openTrip(ActiveTripScreen(
        fareConfig: draft.config,
        resumeDraft: draft,
      ));
    } else if (resume == false) {
      await _draftRepo.clear();
    }
  }

  String _draftSummary(TripDraft d) {
    final mins = d.elapsedSeconds ~/ 60;
    final km = (d.distanceMeters / 1000).toStringAsFixed(2);
    final ago = DateTime.now().difference(d.savedAt).inMinutes;
    return 'Había una carrera en curso: $km km y $mins min. '
        'Se guardó hace $ago min.\n\n'
        'Si reanudas, se conserva el tiempo y la distancia acumulados.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.motorcycle,
                size: 100,
                color: Colors.yellow,
              ),
              const SizedBox(height: 24),
              const Text(
                'MOTO TAXI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calculadora de Tarifas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 40),
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildGpsStatus(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    _openTrip(ActiveTripScreen(fareConfig: _config)),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'INICIAR CARRERA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<FareConfig>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FareSettingsScreen()),
                  );
                  if (result != null) {
                    setState(() => _config = result);
                  }
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text(
                  'CONFIGURAR TARIFAS',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TripHistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.yellow),
                label: const Text(
                  'HISTORIAL DE CARRERAS',
                  style: TextStyle(color: Colors.yellow),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.yellow[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Indicador del calentamiento del GPS (se actualiza solo).
  Widget _buildGpsStatus() {
    return ValueListenableBuilder<GpsWarmupState>(
      valueListenable: GpsWarmupService.instance.state,
      builder: (context, s, _) {
        final Color color;
        final IconData icon;
        final String text;
        final String hint;
        final acc = s.accuracy != null ? ' · ±${s.accuracy!.toStringAsFixed(0)} m' : '';

        switch (s.status) {
          case WarmupStatus.ready:
            color = Colors.green;
            icon = Icons.gps_fixed;
            text = 'GPS LISTO$acc';
            hint = 'La carrera iniciará al instante';
            break;
          case WarmupStatus.searching:
            color = Colors.orange;
            icon = Icons.gps_not_fixed;
            text = 'BUSCANDO GPS$acc';
            hint = 'Espera unos segundos antes de iniciar';
            break;
          case WarmupStatus.serviceOff:
            color = Colors.red;
            icon = Icons.location_off;
            text = 'ACTIVA LA UBICACIÓN DEL CELULAR';
            hint = 'Toca aquí cuando la actives';
            break;
          case WarmupStatus.noPermission:
            color = Colors.red;
            icon = Icons.location_off;
            text = 'SIN PERMISO DE UBICACIÓN';
            hint = 'Toca aquí para abrir la configuración';
            break;
          case WarmupStatus.idle:
            color = Colors.grey;
            icon = Icons.gps_off;
            text = 'GPS EN ESPERA';
            hint = 'Toca aquí para buscar señal';
            break;
        }

        return GestureDetector(
          onTap: () {
            if (s.status == WarmupStatus.noPermission) {
              openAppSettings();
            } else if (s.status != WarmupStatus.ready &&
                s.status != WarmupStatus.searching) {
              GpsWarmupService.instance.start();
            }
          },
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hint,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(
              'Tarifa Base:', '\$${_config.baseFare.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Por Kilómetro:', '\$${_config.pricePerKm.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Por Minuto:', '\$${_config.pricePerMinute.toStringAsFixed(2)}'),
          const Divider(color: Colors.grey, height: 24),
          _buildInfoRow(
              'Mínimo:', '\$${_config.minimumFare.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
