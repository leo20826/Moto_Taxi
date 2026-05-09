import 'package:flutter/material.dart';
import '../../data/models/location_point.dart';

class GpsStatusIndicator extends StatelessWidget {
  final double accuracy;
  final double speed;
  final LocationSource source;

  const GpsStatusIndicator({
    super.key,
    required this.accuracy,
    required this.speed,
    this.source = LocationSource.gps,
  });

  @override
  Widget build(BuildContext context) {
    late final Color statusColor;
    late final IconData statusIcon;
    late final String label;

    if (source == LocationSource.network) {
      statusColor = Colors.blue;
      statusIcon = Icons.signal_cellular_alt;
      label = 'RED MÓVIL';
    } else if (accuracy < 10) {
      statusColor = Colors.green;
      statusIcon = Icons.gps_fixed;
      label = 'GPS';
    } else if (accuracy < 30) {
      statusColor = Colors.yellow;
      statusIcon = Icons.gps_fixed;
      label = 'GPS';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.gps_not_fixed;
      label = 'DÉBIL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (source == LocationSource.gps && accuracy > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${accuracy.toStringAsFixed(0)}m',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
