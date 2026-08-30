import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FareDisplay extends StatelessWidget {
  final double price;

  const FareDisplay({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.yellow[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'PRECIO',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(price),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }
}
