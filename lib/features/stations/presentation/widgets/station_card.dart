import 'package:flutter/material.dart';

import '../../domain/entities/station.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
  });

  static const _blue = Color(0xFF2563EB);

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          13,
          14,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${station.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              station.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _StatusIndicator(
                  status: station.operationalStatus,
                ),

                if (_hasConnectorInformation) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ConnectorInformation(
                      connectors: station.connectors,
                    ),
                  ),
                ],
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

class _ConnectorInformation extends StatelessWidget {
  const _ConnectorInformation({
    required this.connectors,
  });

  final List<Connector> connectors;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: connectors.map((connector) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _connectorText(connector),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _connectorText(Connector connector) {
    final quantity = connector.quantity > 1
        ? ' × ${connector.quantity}'
        : '';

    final power = connector.powerKw != null
        ? ' • ${connector.powerKw!.toStringAsFixed(1)} kW'
        : '';

    return '${connector.type}$quantity$power';
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
  });

  final StationOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StationOperationalStatus.operational:
        return const _StatusRow(
          color: Colors.green,
          label: 'Operational',
        );

      case StationOperationalStatus.unavailable:
        return const _StatusRow(
          color: Colors.red,
          label: 'Unavailable',
        );

      case StationOperationalStatus.unknown:
        return _StatusRow(
          color: Colors.grey,
          label: 'Status unknown',
          textColor: Colors.grey,
        );
    }
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.color,
    required this.label,
    this.textColor,
  });

  final Color color;
  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}