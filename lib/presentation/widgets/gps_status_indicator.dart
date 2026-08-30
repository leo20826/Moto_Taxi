import 'package:flutter/material.dart';
import '../../data/repositories/location_repository.dart';

class GpsStatusIndicator extends StatelessWidget {
  final double accuracy;
  final double speed;
  final GpsStatus status;

  const GpsStatusIndicator({
    super.key,
    required this.accuracy,
    required this.speed,
    this.status = GpsStatus.good,
  });

  @override
  Widget build(BuildContext context) {
    late final Color statusColor;
    late final IconData statusIcon;
    late final String label;

    switch (status) {
      case GpsStatus.lost:
        statusColor = Colors.red;
        statusIcon = Icons.gps_off;
        label = 'SIN SEÑAL';
        break;
      case GpsStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        label = 'ERROR GPS';
        break;
      case GpsStatus.poorAccuracy:
        statusColor = Colors.orange;
        statusIcon = Icons.gps_not_fixed;
        label = 'DÉBIL';
        break;
      case GpsStatus.fairAccuracy:
        statusColor = Colors.yellow;
        statusIcon = Icons.gps_fixed;
        label = 'GPS';
        break;
      case GpsStatus.good:
      case GpsStatus.recovered:
      case GpsStatus.serviceDisabled:
      case GpsStatus.permissionDenied:
      case GpsStatus.permissionDeniedForever:
        statusColor = Colors.green;
        statusIcon = Icons.gps_fixed;
        label = 'GPS';
        break;
    }

    final showAccuracy = status != GpsStatus.lost &&
        status != GpsStatus.error &&
        accuracy > 0;

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
          if (showAccuracy) ...[
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
