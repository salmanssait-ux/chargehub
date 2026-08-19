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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${station.distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              station.address.isEmpty
                  ? 'Address unavailable'
                  : station.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                _StatusIndicator(
                  status: station.operationalStatus,
                ),

                const SizedBox(width: 10),

                if (_hasConnectorInformation)
                  Flexible(
                    child: _ConnectorPreview(
                      connectors: station.connectors,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasConnectorInformation {
    return station.connectors.any(
          (connector) => connector.type != 'Unknown',
    );
  }
}

// ═══════════════════════════════════════════════════════
// CONNECTOR
// ═══════════════════════════════════════════════════════

class _ConnectorPreview extends StatelessWidget {
  const _ConnectorPreview({
    required this.connectors,
  });

  final List<Connector> connectors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final connector = connectors.firstWhere(
          (connector) => connector.type != 'Unknown',
      orElse: () => connectors.first,
    );

    final quantity = connector.quantity > 1
        ? ' × ${connector.quantity}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '${connector.type}$quantity',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// STATUS
// ═══════════════════════════════════════════════════════

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
  });

  final StationOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case StationOperationalStatus.operational:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: Colors.green,
            ),
            SizedBox(width: 5),
            Text(
              'Operational',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case StationOperationalStatus.unavailable:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: Colors.red,
            ),
            SizedBox(width: 5),
            Text(
              'Unavailable',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case StationOperationalStatus.unknown:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.circle,
              size: 8,
              color: Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              'Status unknown',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
    }
  }
}