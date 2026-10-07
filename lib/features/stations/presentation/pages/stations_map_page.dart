import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  bool _stationLayersRegistered = false;
  bool _updatingAccuracyCircle = false;
  bool _markerRefreshInProgress = false;
  bool _markerRefreshRequested = false;
  bool _showLocationPrompt = false;
  bool _locationServiceDisabled = false;
  bool _locationPermissionDeniedForever = false;
  int? _mapThemeSignature;
  CameraPosition? _cameraBeforeStyleChange;
  String _locationPromptMessage =
      'Location is unavailable. Check your GPS signal and try again.';

  final Map<String, Station> _stationsById = {};
  Circle? _accuracyCircle;

  static const _fallbackLocation = LatLng(19.0760, 72.8777);
  static const _stationSourceId = 'chargehub-station-source';
  static const _stationLayerId = 'chargehub-stations';
  static const _clusterLayerId = 'chargehub-station-clusters';
  static const _clusterCountLayerId = 'chargehub-station-cluster-count';

  // ─────────────────────────────────────────────
  // Map style
  // ─────────────────────────────────────────────

  // The configured Stadia key is accepted for style metadata but is not
  // authorized for its OpenMapTiles vector tiles, which produces HTTP 401.
  // These existing public OSM-compatible styles include unauthenticated
  // OpenMapTiles sources that have been verified to load on Android.
  static const _lightMapStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  static const _darkMapStyleUrl = 'https://tiles.openfreemap.org/styles/fiord';

  String _activeMapStyleUrl = _lightMapStyleUrl;

  String get _mapStyleUrl => _styleFor(Theme.of(context).colorScheme);

  String _styleFor(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? _darkMapStyleUrl
        : _lightMapStyleUrl;
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
    // Hybrid composition can place the Android platform view above Flutter's
    // Drawer and AppBar. The plugin's texture composition is the supported
    // default and keeps Flutter controls interactive above the map.
    MapLibreMap.useHybridComposition = false;
    _loadCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scheme = Theme.of(context).colorScheme;
    final signature = scheme.brightness.index;

    final styleUrl = _styleFor(scheme);
    if (_mapThemeSignature == signature) {
      return;
    }
    _mapThemeSignature = signature;

    if (_mapReady) {
      // Keep the native map view mounted while applying the current app
      // palette. Replacing the platform view on theme changes can break its
      // semantics tree.
      if (styleUrl != _activeMapStyleUrl) {
        unawaited(_setMapStyle(styleUrl));
      }
    }
  }

  Future<void> _setMapStyle(String styleUrl) async {
    final controller = _mapController;
    if (controller == null) return;

    _cameraBeforeStyleChange = controller.cameraPosition;
    _mapReady = false;
    _imagesRegistered = false;
    _stationLayersRegistered = false;
    _accuracyCircle = null;
    _activeMapStyleUrl = styleUrl;
    await controller.setStyle(styleUrl);
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _finishLocationLoading(
          showPrompt: true,
          serviceDisabled: true,
          message: 'Turn on location services to center the map on you.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _finishLocationLoading(
          showPrompt: true,
          permissionDeniedForever:
              permission == LocationPermission.deniedForever,
          message: permission == LocationPermission.deniedForever
              ? 'Allow location access in app settings to center the map.'
              : 'Allow location access to center the map on you.',
        );
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
        _locationPermissionDeniedForever = false;
      });

      if (_mapReady) {
        await _moveToCurrentLocation();
        await _refreshMarkers();
      }
    } catch (_) {
      // Location services can be enabled while a fix is temporarily
      // unavailable, especially indoors or when the device has no GPS lock.
      _finishLocationLoading(
        showPrompt: true,
        message:
            'Location is unavailable. Check your GPS signal and try again.',
      );
    }
  }

  void _finishLocationLoading({
    bool showPrompt = false,
    bool serviceDisabled = false,
    bool permissionDeniedForever = false,
    String? message,
  }) {
    if (!mounted) return;

    setState(() {
      _locationLoading = false;
      _showLocationPrompt = showPrompt;
      _locationServiceDisabled = serviceDisabled;
      _locationPermissionDeniedForever = permissionDeniedForever;
      if (message != null) {
        _locationPromptMessage = message;
      }
    });
  }

  Future<void> _enableLocation() async {
    if (_locationServiceDisabled) {
      await Geolocator.openLocationSettings();
    } else if (_locationPermissionDeniedForever) {
      await Geolocator.openAppSettings();
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
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  Future<void> _onStyleLoaded() async {
    if (!mounted) return;

    _mapReady = false;
    _activeMapStyleUrl = _mapStyleUrl;
    _imagesRegistered = false;
    _stationLayersRegistered = false;
    await _applyMapPalette();
    _mapReady = true;
    await _refreshMarkers();

    final previousCamera = _cameraBeforeStyleChange;
    _cameraBeforeStyleChange = null;
    if (previousCamera != null) {
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(previousCamera),
      );
    } else {
      // Location may have resolved before the style finished loading.
      await _moveToCurrentLocation();
      final selectedStation = widget.selectedStation;
      if (selectedStation != null) {
        await _moveToStation(selectedStation);
      }
    }
  }

  Future<void> _applyMapPalette() async {
    final controller = _mapController;
    if (controller == null) return;

    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final layerIds = (await controller.getLayerIds())
        .map((id) => id.toString())
        .toSet();

    final fills = <String, FillLayerProperties>{
      'water': FillLayerProperties(fillColor: isDark ? '#273E54' : '#B9D9EB'),
      'landuse_residential': FillLayerProperties(
        fillColor: isDark ? '#2A3440' : '#EEF2F3',
      ),
      'park': FillLayerProperties(
        fillColor: isDark ? '#30463E' : '#DCEBD8',
        fillOpacity: isDark ? 0.62 : 0.72,
      ),
      'landcover_wood': FillLayerProperties(
        fillColor: isDark ? '#34483F' : '#D6E6D1',
        fillOpacity: isDark ? 0.52 : 0.42,
      ),
    };
    for (final entry in fills.entries) {
      if (layerIds.contains(entry.key)) {
        await controller.setLayerProperties(entry.key, entry.value);
      }
    }

    final parkOutline = layerIds.firstWhere(
      (id) => id == 'park_outline',
      orElse: () => '',
    );
    if (parkOutline.isNotEmpty) {
      await controller.setLayerProperties(
        parkOutline,
        LineLayerProperties(
          lineColor: isDark ? '#405B4F' : '#C9DFC3',
          lineOpacity: 0.8,
        ),
      );
    }

    for (final layerId in layerIds.where((id) => id.startsWith('poi_'))) {
      await controller.setLayerVisibility(layerId, false);
    }
  }

  @override
  void didUpdateWidget(covariant StationsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectionChanged =
        oldWidget.selectedStation?.id != widget.selectedStation?.id;
    final stationsChanged = _stationMarkerDataChanged(
      oldWidget.stations,
      widget.stations,
    );

    if ((selectionChanged || stationsChanged) && _mapReady) {
      unawaited(
        _updateMapForWidgetChange(moveToSelectedStation: selectionChanged),
      );
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

  bool _stationMarkerDataChanged(
    List<Station> previous,
    List<Station> current,
  ) {
    if (previous.length != current.length) return true;
    for (var i = 0; i < previous.length; i++) {
      final a = previous[i];
      final b = current[i];
      if (a.id != b.id ||
          a.latitude != b.latitude ||
          a.longitude != b.longitude ||
          a.operationalStatus != b.operationalStatus) {
        return true;
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // Markers
  // ─────────────────────────────────────────────

  Future<void> _refreshMarkers() async {
    if (_markerRefreshInProgress) {
      _markerRefreshRequested = true;
      return;
    }
    _markerRefreshInProgress = true;
    try {
      do {
        _markerRefreshRequested = false;
        await _refreshMarkersNow();
      } while (_markerRefreshRequested);
    } finally {
      _markerRefreshInProgress = false;
    }
  }

  Future<void> _refreshMarkersNow() async {
    final controller = _mapController;

    if (controller == null || !_mapReady) {
      return;
    }

    final scheme = Theme.of(context).colorScheme;

    if (!_imagesRegistered) {
      _imagesRegistered = true;

      await controller.addImage(
        'chargehub_charger_operational',
        await _createChargerPin(
          color: const Color(0xFF1677D2),
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_unavailable',
        await _createChargerPin(
          color: const Color(0xFF65758B),
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_unknown',
        await _createChargerPin(
          color: const Color(0xFF4B91D1),
          surface: scheme.surface,
          selected: false,
        ),
      );

      await controller.addImage(
        'chargehub_charger_selected',
        await _createChargerPin(
          color: const Color(0xFF1677D2),
          surface: scheme.surface,
          selected: true,
        ),
      );

      await controller.addImage(
        'chargehub_location',
        await _createLocationMarker(surface: scheme.surface),
      );
    }

    final position = _currentPosition;
    if (position != null) {
      await controller.clearSymbols();
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(position.latitude, position.longitude),
          iconImage: 'chargehub_location',
          iconSize: 0.62,
          zIndex: 1000,
        ),
      );
      await _updateAccuracyCircle();
    } else {
      await controller.clearSymbols();
      if (_accuracyCircle != null) {
        await controller.removeCircle(_accuracyCircle!);
        _accuracyCircle = null;
      }
    }

    await _registerStationLayers(controller);
    _stationsById
      ..clear()
      ..addEntries(
        widget.stations.map((station) => MapEntry(station.id, station)),
      );
    await controller.setGeoJsonSource(
      _stationSourceId,
      _stationFeatureCollection(),
    );
  }

  Map<String, dynamic> _stationFeatureCollection() {
    return {
      'type': 'FeatureCollection',
      'features': widget.stations.map((station) {
        final selected = widget.selectedStation?.id == station.id;
        return {
          'type': 'Feature',
          'id': station.id,
          'properties': {
            'stationId': station.id,
            'icon': selected
                ? 'chargehub_charger_selected'
                : _markerImageFor(station),
            'selected': selected,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [station.longitude, station.latitude],
          },
        };
      }).toList(),
    };
  }

  Future<void> _registerStationLayers(MapLibreMapController controller) async {
    if (_stationLayersRegistered) return;
    await controller.addSource(
      _stationSourceId,
      GeojsonSourceProperties(
        data: _stationFeatureCollection(),
        cluster: true,
        clusterRadius: 44,
        clusterMaxZoom: 13,
      ),
    );
    await controller.addLayer(
      _stationSourceId,
      _clusterLayerId,
      const CircleLayerProperties(
        circleColor: '#1677D2',
        circleRadius: [
          'step',
          ['get', 'point_count'],
          18,
          10,
          21,
          30,
          24,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
      filter: ['has', 'point_count'],
    );
    await controller.addLayer(
      _stationSourceId,
      _clusterCountLayerId,
      SymbolLayerProperties(
        textField: ['get', 'point_count_abbreviated'],
        textSize: 12,
        textColor: '#FFFFFF',
        textFont: ['Noto Sans Bold'],
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      filter: ['has', 'point_count'],
    );
    await controller.addLayer(
      _stationSourceId,
      _stationLayerId,
      const SymbolLayerProperties(
        iconImage: ['get', 'icon'],
        iconSize: [
          'case',
          ['get', 'selected'],
          0.56,
          0.43,
        ],
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
    _stationLayersRegistered = true;
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

  Future<void> _onFeatureTapped(
    math.Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) async {
    if (layerId == _clusterLayerId || layerId == _clusterCountLayerId) {
      final controller = _mapController;
      final camera = controller?.cameraPosition;
      if (controller != null && camera != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: coordinates,
              zoom: (camera.zoom + 2).clamp(0, 18),
              tilt: camera.tilt,
              bearing: camera.bearing,
            ),
          ),
        );
      }
      return;
    }

    final station = _stationsById[id];
    if (layerId != _stationLayerId || station == null) return;
    widget.onStationSelected(station);
    await _moveToStation(station);
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
    // Use the last known fix immediately so the control responds without
    // waiting for a new GPS reading. _loadCurrentLocation then refreshes the
    // position and moves the camera again when a newer fix is available.
    if (_currentPosition != null) {
      await _moveToCurrentLocation();
    }

    await _loadCurrentLocation();
  }

  // ─────────────────────────────────────────────
  // Charger marker
  // ─────────────────────────────────────────────

  Future<Uint8List> _createChargerPin({
    required Color color,
    required Color surface,
    required bool selected,
  }) async {
    const size = 144.0;
    const scale = size / 120;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    const center = Offset(60, 54);

    final paint = Paint()..isAntiAlias = true;

    if (selected) {
      paint
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.12);
      canvas.drawCircle(center, 51, paint);
    }

    final pin = Path()
      ..moveTo(60, 116)
      ..cubicTo(47, 96, 23, 77, 23, 53)
      ..cubicTo(23, 30, 40, 15, 60, 15)
      ..cubicTo(80, 15, 97, 30, 97, 53)
      ..cubicTo(97, 77, 73, 96, 60, 116)
      ..close();

    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.18), 4, true);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = surface;
    canvas.drawPath(pin, paint);

    paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        const Offset(30, 20),
        const Offset(88, 96),
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
    canvas.drawCircle(center, 25, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.20);
    canvas.drawCircle(center, 25, paint);

    final bolt = Path()
      ..moveTo(63, 31)
      ..lineTo(45, 57)
      ..lineTo(57, 57)
      ..lineTo(52, 77)
      ..lineTo(75, 48)
      ..lineTo(63, 48)
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

  Future<Uint8List> _createLocationMarker({required Color surface}) async {
    const size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(60, 60);

    final paint = Paint()..isAntiAlias = true;

    paint.color = surface;
    canvas.drawCircle(center, 24, paint);

    paint
      ..color = const Color(0xFF1677D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, 24, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1677D2);

    canvas.drawCircle(center, 8, paint);

    return _pictureToBytes(recorder.endRecording(), size);
  }

  Future<void> _updateAccuracyCircle() async {
    final controller = _mapController;
    final position = _currentPosition;
    if (controller == null ||
        position == null ||
        !_mapReady ||
        _updatingAccuracyCircle) {
      return;
    }

    _updatingAccuracyCircle = true;
    try {
      final metersPerPixel = await controller.getMetersPerPixelAtLatitude(
        position.latitude,
      );
      final radius = (position.accuracy / metersPerPixel)
          .clamp(8.0, 96.0)
          .toDouble();
      final options = CircleOptions(
        geometry: LatLng(position.latitude, position.longitude),
        circleRadius: radius,
        circleColor: '#1677D2',
        circleOpacity: 0.12,
        circleStrokeColor: '#1677D2',
        circleStrokeWidth: 1.5,
        circleStrokeOpacity: 0.4,
      );
      final currentCircle = _accuracyCircle;
      if (currentCircle == null) {
        _accuracyCircle = await controller.addCircle(options);
      } else {
        await controller.updateCircle(currentCircle, options);
      }
    } finally {
      _updatingAccuracyCircle = false;
    }
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
          styleString: _mapStyleUrl,
          initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 12.8),
          myLocationEnabled: false,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          attributionButtonMargins: const math.Point<num>(8, 56),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraIdle: () => unawaited(_updateAccuracyCircle()),
        ),

        Positioned(
          left: 12,
          top: 12,
          child: Semantics(
            label: '${widget.stations.length} charging stations on map',
            child: _MapBadge(
              icon: Icons.ev_station_rounded,
              text: '${widget.stations.length} chargers',
            ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            color: scheme.primary,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationPromptMessage,
                              softWrap: true,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _enableLocation,
                        clipBehavior: Clip.antiAlias,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          _locationServiceDisabled ||
                                  _locationPermissionDeniedForever
                              ? 'Settings'
                              : 'Retry',
                        ),
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
          child: Semantics(
            button: true,
            label: 'Current location',
            child: Material(
              color: scheme.surfaceContainer,
              elevation: 3,
              shadowColor: scheme.shadow.withValues(alpha: 0.22),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _recenter,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: const Color(0xFF1677D2),
                    size: 22,
                  ),
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
    _mapController?.onFeatureTapped.remove(_onFeatureTapped);
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
