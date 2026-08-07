import 'package:flutter/material.dart';

import '../../domain/entities/station.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
  });

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(station.address),
            const SizedBox(height: 8),
            Text(
              '${station.distanceKm.toStringAsFixed(1)} km away',
            ),
            const SizedBox(height: 8),
            Text(
              station.isOperational
                  ? '🟢 Operational'
                  : '🔴 Not Operational',
            ),
          ],
        ),
      ),
    );
  }
}
