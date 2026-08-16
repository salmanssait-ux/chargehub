import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/station.dart';

class StationsMapPage extends StatefulWidget {
  const StationsMapPage({
    super.key,
    required this.stations,
    this.selectedStation,
    required this.onStationSelected,
  });

  final List<Station> stations;
  final Station? selectedStation;
  final ValueChanged<Station> onStationSelected;

  @override
  State<StationsMapPage> createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  static const _blue = Color(0xFF2563EB);

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

      final position = await Geolocator.getCurrentPosition();

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
        child: CircularProgressIndicator(
          color: _blue,
        ),
      );
    }

    final userLocation = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final markers = <Marker>[
      // User location
      Marker(
        point: userLocation,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _blue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 9,
              height: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),

      // Charging stations
      ...widget.stations.map(
        (station) {
          final isSelected = widget.selectedStation == station;

          return Marker(
            point: LatLng(
              station.latitude,
              station.longitude,
            ),
            width: isSelected ? 42 : 30,
            height: isSelected ? 50 : 38,
            child: GestureDetector(
              onTap: () {
                widget.onStationSelected(station);
              },
              child: _ChargerPin(
                selected: isSelected,
              ),
            ),
          );
        },
      ),
    ];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salman.chargehub',
            ),
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),

        // OpenStreetMap attribution
        Positioned(
          left: 6,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 7,
                color: Colors.black54,
              ),
            ),
          ),
        ),

        // Recenter button
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _loadCurrentLocation,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.my_location_rounded,
                  color: _blue,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _ChargerPin extends StatelessWidget {
  const _ChargerPin({
    this.selected = false,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: Icon(
        Icons.location_on_rounded,
        size: selected ? 40 : 30,
        color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
        shadows: selected
            ? const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}
