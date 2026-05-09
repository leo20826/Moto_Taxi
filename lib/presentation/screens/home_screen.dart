import 'package:flutter/material.dart';
import '../../data/models/fare_config.dart';
import '../../data/repositories/fare_repository.dart';
import 'active_trip_screen.dart';
import 'fare_settings_screen.dart';
import 'trip_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = FareRepository();
  FareConfig _config = const FareConfig();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _repo.getConfig();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
              const Spacer(),
              _buildInfoCard(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveTripScreen(fareConfig: _config),
                  ),
                ),
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
