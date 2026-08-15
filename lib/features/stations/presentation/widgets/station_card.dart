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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              station.address,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${station.distanceKm.toStringAsFixed(1)} km away',
              style: const TextStyle(
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),

            _StatusIndicator(
              status: station.operationalStatus,
            ),

            const SizedBox(height: 12),

            if (_hasConnectorInformation)
              _ConnectorInformation(
                connectors: station.connectors,
              ),

            const SizedBox(height: 10),

            _SourceLabel(
              source: station.source,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: connectors.map((connector) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _connectorText(connector),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
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

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({
    required this.source,
  });

  final StationSource source;

  @override
  Widget build(BuildContext context) {
    final String text;

    switch (source) {
      case StationSource.ocm:
        text = 'Source: Open Charge Map';

      case StationSource.osm:
        text = 'Source: OpenStreetMap';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade600,
      ),
    );
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
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: Colors.green,
            ),
            SizedBox(width: 6),
            Text(
              'Operational',
              style: TextStyle(
                fontSize: 12,
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
              size: 10,
              color: Colors.red,
            ),
            SizedBox(width: 6),
            Text(
              'Unavailable',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        );

      case StationOperationalStatus.unknown:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              'Status unknown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        );
    }
  }
}