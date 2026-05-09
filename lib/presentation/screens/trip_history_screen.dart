import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip_record.dart';
import '../../data/repositories/trip_database.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<TripRecord> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await TripDatabase.instance.getAll();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  double get _totalToday {
    final now = DateTime.now();
    return _trips
        .where((t) =>
            t.startTime.year == now.year &&
            t.startTime.month == now.month &&
            t.startTime.day == now.day)
        .fold(0.0, (sum, t) => sum + t.price);
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Borrar todo?', style: TextStyle(color: Colors.white)),
        content: const Text('Se eliminará todo el historial permanentemente.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TripDatabase.instance.deleteAll();
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Historial de Carreras'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _confirmDeleteAll,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar todo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _trips.isEmpty
              ? Center(
                  child: Text(
                    'No hay carreras registradas',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _trips.length,
                        itemBuilder: (context, index) =>
                            _buildTripCard(_trips[index]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL HOY',
            style: TextStyle(
                color: Colors.grey[500], fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalToday.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripRecord trip) {
    final fmt = DateFormat('dd/MM HH:mm');
    final dur = Duration(seconds: trip.durationSeconds);
    final durStr =
        '${dur.inHours.toString().padLeft(2, '0')}:${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}';

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.yellow[700],
          child: const Icon(Icons.motorcycle, color: Colors.black),
        ),
        title: Text(
          '\$${trip.price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${fmt.format(trip.startTime)} • ${(trip.distance / 1000).toStringAsFixed(2)} km • $durStr',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
          onPressed: () async {
            await TripDatabase.instance.delete(trip.id);
            _loadTrips();
          },
        ),
      ),
    );
  }
}
