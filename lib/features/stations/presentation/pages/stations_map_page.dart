import 'dart:math' as math;
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

class _StationsMapPageState extends State<StationsMapPage>
    with WidgetsBindingObserver {
  MapLibreMapController? _mapController;

  Position? _currentPosition;

  bool _mapReady = false;
  bool _locationLoading = true;
  bool _imagesRegistered = false;
  bool _showLocationPrompt = true;
  bool _locationServiceDisabled = false;

  final Map<String, Station> _symbols = {};

  static const _fallbackLocation = LatLng(19.0760, 72.8777);

  // ─────────────────────────────────────────────
  // Map style
  // ─────────────────────────────────────────────

  String get _mapStyleUrl {
    final apiKey = dotenv.env['STADIA_MAPS_API_KEY']?.trim();
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    if (apiKey == null || apiKey.isEmpty) {
      return 'https://tiles.openfreemap.org/styles/liberty';
    }

    final style = isDark ? 'alidade_smooth_dark' : 'alidade_smooth';

    final tileUrl =
        'https://tiles.stadiamaps.com/styles/'
        '$style.json'
        '?api_key=$apiKey';

    return tileUrl;
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

    return LatLng(position.latitude, position.longitude);
  }

  // ─────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapLibreMap.useHybridComposition = true;
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _finishLocationLoading(showPrompt: true, serviceDisabled: true);
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _finishLocationLoading(showPrompt: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _locationLoading = false;
        _showLocationPrompt = false;
        _locationServiceDisabled = false;
      });

      if (_mapReady) {
        await _moveToCurrentLocation();
        await _refreshMarkers();
      }
    } catch (_) {
      _finishLocationLoading(showPrompt: true);
    }
  }

  void _finishLocationLoading({
    bool showPrompt = false,
    bool serviceDisabled = false,
  }) {
    if (!mounted) return;

    setState(() {
      _locationLoading = false;
      _showLocationPrompt = showPrompt;
      _locationServiceDisabled = serviceDisabled;
    });
  }

  Future<void> _enableLocation() async {
    if (_locationServiceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    }

    await _loadCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showLocationPrompt) {
      _loadCurrentLocation();
    }
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
    _imagesRegistered = false;

    await _tintRoadLayers();
    await _refreshMarkers();

    // The initial camera position is only used while the map is created.
    // Location may have resolved before the style finished loading, so move
    // the camera explicitly once the map can accept camera updates.
    await _moveToCurrentLocation();

    final selectedStation = widget.selectedStation;
    if (selectedStation != null) {
      await _moveToStation(selectedStation);
    }
  }

  Future<void> _tintRoadLayers() async {
    final controller = _mapController;
    if (controller == null) return;

    final scheme = Theme.of(context).colorScheme;
    final minorRoadColor = Color.lerp(
      scheme.surface,
      scheme.primary,
      scheme.brightness == Brightness.dark ? 0.28 : 0.24,
    )!;
    final majorRoadColor = Color.lerp(
      scheme.surface,
      scheme.primary,
      scheme.brightness == Brightness.dark ? 0.46 : 0.40,
    )!;
    final layerIds = await controller.getLayerIds();

    for (final layerId in layerIds) {
      final id = layerId.toString().toLowerCase();
      if (!id.contains('road') &&
          !id.contains('street') &&
          !id.contains('highway') &&
          !id.contains('motorway') &&
          !id.contains('transport')) {
        continue;
      }

      final isMajorRoad =
          id.contains('motorway') ||
          id.contains('trunk') ||
          id.contains('highway') ||
          id.contains('primary');

      await controller.setLayerProperties(
        layerId.toString(),
        LineLayerProperties(
          lineColor: _colorHex(isMajorRoad ? majorRoadColor : minorRoadColor),
          lineWidth: 0.7,
          lineOpacity: isMajorRoad ? 0.95 : 0.84,
        ),
      );
    }
  }

  String _colorHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  @override
  void didUpdateWidget(covariant StationsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectionChanged =
        oldWidget.selectedStation?.id != widget.selectedStation?.id;
    final stationsChanged = oldWidget.stations.length != widget.stations.length;

    if (selectionChanged || stationsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapReady) {
          _updateMapForWidgetChange(moveToSelectedStation: selectionChanged);
        }
      });
    }
  }

  Future<void> _updateMapForWidgetChange({
    required bool moveToSelectedStation,
  }) async {
    await _refreshMarkers();

    final selectedStation = widget.selectedStation;
    if (moveToSelectedStation && selectedStation != null) {
      await _moveToStation(selectedStation);
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

    if (!_imagesRegistered) {
      _imagesRegistered = true;

      await controller.addImage(
        'chargehub_charger_operational',
        await _createChargerPin(
          color: scheme.primary,
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_unavailable',
        await _createChargerPin(
          color: scheme.error,
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_unknown',
        await _createChargerPin(
          color: scheme.secondary,
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_selected',
        await _createChargerPin(
          color: scheme.primary,
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
    }

    // Current location
    final position = _currentPosition;

    if (position != null) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(position.latitude, position.longitude),
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
      final selected = widget.selectedStation?.id == station.id;

      options.add(
        SymbolOptions(
          geometry: LatLng(station.latitude, station.longitude),
          iconImage: selected
              ? 'chargehub_charger_selected'
              : _markerImageFor(station),
          iconSize: selected ? 0.92 : 0.72,
          zIndex: selected ? 900 : 100,
        ),
      );

      data.add({'stationId': station.id});
    }

    if (options.isEmpty) {
      return;
    }

    final symbols = await controller.addSymbols(options, data);

    for (var i = 0; i < symbols.length; i++) {
      _symbols[symbols[i].id] = widget.stations[i];
    }
  }

  String _markerImageFor(Station station) {
    switch (station.operationalStatus) {
      case StationOperationalStatus.operational:
        return 'chargehub_charger_operational';
      case StationOperationalStatus.unavailable:
        return 'chargehub_charger_unavailable';
      case StationOperationalStatus.unknown:
        return 'chargehub_charger_unknown';
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
          target: LatLng(station.latitude, station.longitude),
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
          target: LatLng(position.latitude, position.longitude),
          zoom: 13,
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    await _loadCurrentLocation();

    if (_currentPosition != null) {
      await _moveToCurrentLocation();
    }
  }

  // ─────────────────────────────────────────────
  // Charger marker
  // ─────────────────────────────────────────────

  Future<Uint8List> _createChargerPin({
    required Color color,
    required Color surface,
    required bool selected,
  }) async {
    const size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = const Offset(60, 43);

    final paint = Paint()..isAntiAlias = true;

    if (selected) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: 0.24);
      canvas.drawCircle(center, 46, paint);

      paint
        ..strokeWidth = 3
        ..color = color.withValues(alpha: 0.10);
      canvas.drawCircle(center, 55, paint);
    }

    final pin = Path()
      ..moveTo(60, 91)
      ..cubicTo(48, 74, 23, 60, 23, 39)
      ..cubicTo(23, 17, 40, 3, 60, 3)
      ..cubicTo(80, 3, 97, 17, 97, 39)
      ..cubicTo(97, 60, 72, 74, 60, 91)
      ..close();

    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.32), 7, true);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = surface;
    canvas.drawPath(pin, paint);

    paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        const Offset(30, 10),
        const Offset(88, 78),
        [
          Color.lerp(color, Colors.white, 0.18)!,
          Color.lerp(color, Colors.black, 0.12)!,
        ],
      );
    canvas.drawPath(pin, paint);
    paint.shader = null;

    paint
      ..style = PaintingStyle.fill
      ..color = surface;
    canvas.drawCircle(center, 26, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.20);
    canvas.drawCircle(center, 26, paint);

    final bolt = Path()
      ..moveTo(63, 20)
      ..lineTo(45, 46)
      ..lineTo(57, 46)
      ..lineTo(52, 66)
      ..lineTo(75, 37)
      ..lineTo(63, 37)
      ..close();

    paint
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(bolt, paint);

    return _pictureToBytes(recorder.endRecording(), size);
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

    final paint = Paint()..isAntiAlias = true;

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

    return _pictureToBytes(recorder.endRecording(), size);
  }

  Future<Uint8List> _pictureToBytes(ui.Picture picture, double size) async {
    final image = await picture.toImage(size.toInt(), size.toInt());

    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return bytes!.buffer.asUint8List();
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        MapLibreMap(
          key: ValueKey(_mapKey),
          styleString: _mapStyleUrl,
          initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 12.8),
          myLocationEnabled: false,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          attributionButtonPosition: AttributionButtonPosition.topRight,
          attributionButtonMargins: const math.Point<num>(-1000, -1000),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.secondary.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          left: 12,
          top: 12,
          child: _MapBadge(
            icon: Icons.ev_station_rounded,
            text: '${widget.stations.length} chargers',
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

        if (_showLocationPrompt ||
            (_currentPosition == null && !_locationLoading))
          Positioned(
            left: 12,
            right: 12,
            top: 56,
            child: Material(
              color: scheme.surfaceContainer,
              elevation: 4,
              shadowColor: scheme.shadow.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _enableLocation,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        color: scheme.primary,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Turn on location to center the map on you.',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _enableLocation,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Turn on'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: scheme.surfaceContainer,
            elevation: 4,
            shadowColor: scheme.shadow.withValues(alpha: 0.25),
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
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    _mapController?.dispose();
    super.dispose();
  }
}

// ================================================================
// Map badge
// ================================================================

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: scheme.primary),
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
