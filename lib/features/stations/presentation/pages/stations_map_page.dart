import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
  MapLibreMapController? _mapController;

  Position? _currentPosition;

  bool _mapReady = false;
  bool _locationLoading = true;

  final Map<String, Station> _symbols = {};

  static const _fallbackLocation = LatLng(
    19.0760,
    72.8777,
  );

  // ─────────────────────────────────────────────
  // Map style
  // ─────────────────────────────────────────────

  String get _mapStyleUrl {
    final apiKey = dotenv.env['STADIA_MAPS_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [],
      });
    }

    final isDark =
        Theme.of(context).colorScheme.brightness == Brightness.dark;

    final style = isDark ? 'alidade_smooth_dark' : 'alidade_smooth';

    final tileUrl = 'https://tiles.stadiamaps.com/tiles/'
        '$style/{z}/{x}/{y}.png'
        '?api_key=$apiKey';

    return jsonEncode({
      'version': 8,
      'sources': {
        'stadia': {
          'type': 'raster',
          'tiles': [tileUrl],
          'tileSize': 256,
          'minzoom': 0,
          'maxzoom': 20,
        },
      },
      'layers': [
        {
          'id': 'stadia-basemap',
          'type': 'raster',
          'source': 'stadia',
          'minzoom': 0,
          'maxzoom': 20,
        },
      ],
    });
  }

  String get _mapKey {
    final scheme = Theme.of(context).colorScheme;

    return [
      scheme.brightness.name,
      scheme.primary.toARGB32(),
      scheme.surface.toARGB32(),
    ].join('_');
  }

  LatLng get _mapCenter {
    final position = _currentPosition;

    if (position == null) {
      return _fallbackLocation;
    }

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

  // ─────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _finishLocationLoading();
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _finishLocationLoading();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _locationLoading = false;
      });

      if (_mapReady) {
        await _moveToCurrentLocation();
        await _refreshMarkers();
      }
    } catch (_) {
      _finishLocationLoading();
    }
  }

  void _finishLocationLoading() {
    if (!mounted) return;

    setState(() {
      _locationLoading = false;
    });
  }

  // ─────────────────────────────────────────────
  // Map lifecycle
  // ─────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;

    controller.onSymbolTapped.add(_onSymbolTapped);
  }

  Future<void> _onStyleLoaded() async {
    if (!mounted) return;

    _mapReady = true;

    await _refreshMarkers();
  }

  @override
  void didUpdateWidget(covariant StationsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedStation?.id !=
        widget.selectedStation?.id ||
        oldWidget.stations.length != widget.stations.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapReady) {
          _refreshMarkers();
        }
      });
    }
  }

  // ─────────────────────────────────────────────
  // Markers
  // ─────────────────────────────────────────────

  Future<void> _refreshMarkers() async {
    final controller = _mapController;

    if (controller == null || !_mapReady) {
      return;
    }

    final scheme = Theme.of(context).colorScheme;

    try {
      await controller.clearSymbols();
    } catch (_) {}

    _symbols.clear();

    await controller.addImage(
      'chargehub_charger',
      await _createChargerPin(
        primary: scheme.primary,
        surface: scheme.surface,
        selected: false,
      ),
    );

    await controller.addImage(
      'chargehub_charger_selected',
      await _createChargerPin(
        primary: scheme.primary,
        surface: scheme.surface,
        selected: true,
      ),
    );

    await controller.addImage(
      'chargehub_location',
      await _createLocationMarker(
        primary: scheme.primary,
        surface: scheme.surface,
      ),
    );

    // Current location
    final position = _currentPosition;

    if (position != null) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            position.latitude,
            position.longitude,
          ),
          iconImage: 'chargehub_location',
          iconSize: 0.65,
          zIndex: 1000,
        ),
      );
    }

    // Charging stations
    final options = <SymbolOptions>[];
    final data = <Map<String, dynamic>>[];

    for (final station in widget.stations) {
      final selected =
          widget.selectedStation?.id == station.id;

      options.add(
        SymbolOptions(
          geometry: LatLng(
            station.latitude,
            station.longitude,
          ),
          iconImage: selected
              ? 'chargehub_charger_selected'
              : 'chargehub_charger',
          iconSize: selected ? 0.82 : 0.68,
          zIndex: selected ? 900 : 100,
        ),
      );

      data.add({
        'stationId': station.id,
      });
    }

    if (options.isEmpty) {
      return;
    }

    final symbols = await controller.addSymbols(
      options,
      data,
    );

    for (var i = 0; i < symbols.length; i++) {
      _symbols[symbols[i].id] = widget.stations[i];
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    final station = _symbols[symbol.id];

    if (station == null) {
      return;
    }

    widget.onStationSelected(station);
    _moveToStation(station);
  }

  // ─────────────────────────────────────────────
  // Camera
  // ─────────────────────────────────────────────

  Future<void> _moveToStation(Station station) async {
    final controller = _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            station.latitude,
            station.longitude,
          ),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    final controller = _mapController;
    final position = _currentPosition;

    if (controller == null || position == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            position.latitude,
            position.longitude,
          ),
          zoom: 13,
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    if (_currentPosition == null) {
      await _loadCurrentLocation();
      return;
    }

    await _moveToCurrentLocation();
  }

  // ─────────────────────────────────────────────
  // Charger marker
  // ─────────────────────────────────────────────

  Future<Uint8List> _createChargerPin({
    required Color primary,
    required Color surface,
    required bool selected,
  }) async {
    const size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = const Offset(60, 43);

    final paint = Paint()
      ..isAntiAlias = true;

    if (selected) {
      paint.color = primary.withValues(alpha: 0.18);
      canvas.drawCircle(center, 44, paint);

      paint.color = primary.withValues(alpha: 0.08);
      canvas.drawCircle(center, 55, paint);
    }

    final pin = Path()
      ..moveTo(60, 91)
      ..cubicTo(48, 74, 23, 60, 23, 39)
      ..cubicTo(23, 17, 40, 3, 60, 3)
      ..cubicTo(80, 3, 97, 17, 97, 39)
      ..cubicTo(97, 60, 72, 74, 60, 91)
      ..close();

    paint.color = primary;
    canvas.drawPath(pin, paint);

    paint.color = surface;
    canvas.drawCircle(center, 26, paint);

    final bolt = Path()
      ..moveTo(63, 18)
      ..lineTo(42, 47)
      ..lineTo(56, 47)
      ..lineTo(49, 70)
      ..lineTo(78, 36)
      ..lineTo(64, 36)
      ..close();

    paint.color = primary;
    canvas.drawPath(bolt, paint);

    return _pictureToBytes(
      recorder.endRecording(),
      size,
    );
  }

  // ─────────────────────────────────────────────
  // Location marker
  // ─────────────────────────────────────────────

  Future<Uint8List> _createLocationMarker({
    required Color primary,
    required Color surface,
  }) async {
    const size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(60, 60);

    final paint = Paint()
      ..isAntiAlias = true;

    paint.color = primary.withValues(alpha: 0.13);
    canvas.drawCircle(center, 50, paint);

    paint.color = primary.withValues(alpha: 0.07);
    canvas.drawCircle(center, 61, paint);

    paint.color = surface;
    canvas.drawCircle(center, 24, paint);

    paint
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, 24, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = primary;

    canvas.drawCircle(center, 8, paint);

    return _pictureToBytes(
      recorder.endRecording(),
      size,
    );
  }

  Future<Uint8List> _pictureToBytes(
      ui.Picture picture,
      double size,
      ) async {
    final image = await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    final bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return bytes!.buffer.asUint8List();
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Stack(
      children: [
        MapLibreMap(
          key: ValueKey(_mapKey),
          styleString: _mapStyleUrl,
          initialCameraPosition: CameraPosition(
            target: _mapCenter,
            zoom: 12.8,
          ),
          myLocationEnabled: false,
          myLocationTrackingMode:
          MyLocationTrackingMode.none,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
        ),

        Positioned(
          left: 12,
          top: 12,
          child: _MapBadge(
            text:
            '${widget.stations.length} chargers',
          ),
        ),

        if (_locationLoading)
          Positioned(
            right: 12,
            top: 12,
            child: _MapBadge(
              icon: Icons.my_location_rounded,
              text: 'Locating...',
            ),
          ),

        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: scheme.surfaceContainer,
            elevation: 4,
            shadowColor:
            scheme.shadow.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _recenter,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.my_location_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.onSymbolTapped.remove(
      _onSymbolTapped,
    );
    _mapController?.dispose();
    super.dispose();
  }
}

// ================================================================
// Map badge
// ================================================================

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(
          alpha: 0.94,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(
            alpha: 0.45,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: 0.15,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: scheme.primary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}