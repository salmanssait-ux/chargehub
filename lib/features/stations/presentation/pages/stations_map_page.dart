import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/station.dart';

class StationsMapPage extends StatefulWidget {
  const StationsMapPage({
    super.key,
    required this.stations,
  });

  final List<Station> stations;

  @override
  State<StationsMapPage> createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position =
      await Geolocator.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = position;
      });
    } catch (_) {
      // Map can still be opened without the user marker.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final userLocation = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final markers = <Marker>[
      Marker(
        point: userLocation,
        width: 45,
        height: 45,
        child: const Icon(
          Icons.my_location,
          size: 30,
          color: Colors.blue,
        ),
      ),
      ...widget.stations.map(
            (station) {
          return Marker(
            point: LatLng(
              station.latitude,
              station.longitude,
            ),
            width: 46,
            height: 46,
            child: GestureDetector(
              onTap: () {
                _showStationDetails(
                  context,
                  station,
                );
              },
              child: const Icon(
                Icons.ev_station,
                size: 34,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: userLocation,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.salman.chargehub',
        ),
        MarkerLayer(
          markers: markers,
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }

  void _showStationDetails(
      BuildContext context,
      Station station,
      ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(station.address),
                  const SizedBox(height: 8),
                  Text(
                    '${station.distanceKm.toStringAsFixed(1)} km away',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusText(
                      station.operationalStatus,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...station.connectors.map(
                        (connector) {
                      final power = connector.powerKw != null
                          ? ' • ${connector.powerKw!.toStringAsFixed(1)} kW'
                          : '';

                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${connector.type} × ${connector.quantity}$power',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusText(
      StationOperationalStatus status,
      ) {
    switch (status) {
      case StationOperationalStatus.operational:
        return '🟢 Operational';

      case StationOperationalStatus.unavailable:
        return '🔴 Unavailable';

      case StationOperationalStatus.unknown:
        return '⚪ Status unknown';
    }
  }
}