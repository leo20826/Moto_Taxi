import 'package:flutter/material.dart';

class TripControls extends StatelessWidget {
  final VoidCallback onEndTrip;

  const TripControls({super.key, required this.onEndTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEndTrip,
              icon: const Icon(Icons.stop, size: 28),
              label: const Text(
                'FINALIZAR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
