import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/entities/station.dart';
import '../../domain/entities/station_submission.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../../providers.dart';
import 'my_station_submissions_page.dart';

class AddStationPage extends ConsumerStatefulWidget {
  const AddStationPage({
    super.key,
    this.station,
    this.knownStations = const [],
  });

  final Station? station;
  final List<Station> knownStations;

  @override
  ConsumerState<AddStationPage> createState() => _AddStationPageState();
}

class _AddStationPageState extends ConsumerState<AddStationPage> {
  final _submissionId = _createSubmissionId();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _operatorController;
  late final TextEditingController _connectorController;
  late final TextEditingController _chargersController;
  late final TextEditingController _powerController;
  late final TextEditingController _notesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  bool _saving = false;
  bool _locating = false;
  bool _possibleDuplicate = false;
  StationSubmission? _submission;

  bool get _editing => widget.station != null;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _nameController = TextEditingController(text: station?.name);
    _addressController = TextEditingController(text: station?.address);
    _operatorController = TextEditingController(text: station?.operatorName);
    final connector = station?.connectors.isNotEmpty == true
        ? station!.connectors.first
        : null;
    _connectorController = TextEditingController(
      text: connector?.type == 'Unknown' ? '' : connector?.type,
    );
    _chargersController = TextEditingController(
      text: (station?.chargerCount ?? connector?.quantity)?.toString(),
    );
    _powerController = TextEditingController(
      text: connector?.powerKw?.toString(),
    );
    _notesController = TextEditingController(text: station?.notes);
    _latitudeController = TextEditingController(
      text: station?.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: station?.longitude.toString(),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _addressController,
      _operatorController,
      _connectorController,
      _chargersController,
      _powerController,
      _notesController,
      _latitudeController,
      _longitudeController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService().getCurrentLocation();
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get your location. Enter latitude and longitude manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());
    final connectors = _connectorController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final quantity = int.tryParse(_chargersController.text.trim()) ?? 1;
    final power = double.tryParse(_powerController.text.trim());
    final duplicate = _findPotentialDuplicate(latitude, longitude);

    setState(() {
      _saving = true;
      _possibleDuplicate = duplicate;
    });
    try {
      final submission = await ref
          .read(stationSubmissionRepositoryProvider)
          .submit(
            StationSubmissionDraft(
              id: _submissionId,
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              operatorName: _operatorController.text.trim(),
              latitude: latitude,
              longitude: longitude,
              connectorTypes: connectors,
              chargerCount: quantity,
              powerKw: power,
              notes: _notesController.text.trim(),
            ),
          );
      if (mounted) setState(() => _submission = submission);
    } catch (error) {
      if (mounted) {
        final message = error is StationSubmissionFailure
            ? error.message
            : 'Could not submit this station. Check the details and try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _createSubmissionId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  bool _findPotentialDuplicate(double latitude, double longitude) {
    final values = [
      _nameController.text,
      _addressController.text,
      _operatorController.text,
    ].map(_normalize).toList();

    for (final station in widget.knownStations) {
      if (_distanceKm(
            latitude,
            longitude,
            station.latitude,
            station.longitude,
          ) >
          0.5) {
        continue;
      }
      final knownValues = [
        station.name,
        station.address,
        station.operatorName ?? '',
      ].map(_normalize).toList();
      final matchingValues = List.generate(
        values.length,
        (index) =>
            values[index].isNotEmpty && values[index] == knownValues[index],
      ).where((matches) => matches).length;
      if (matchingValues >= 2) return true;
    }
    return false;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _optionalPositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    return number == null || number < 1
        ? 'Enter a whole number greater than 0'
        : null;
  }

  String? _optionalPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    return number == null || !number.isFinite || number <= 0
        ? 'Enter a number greater than 0'
        : null;
  }

  String? _coordinate(String? value, {required bool latitude}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite) return 'Enter a valid number';
    if (latitude && (number < -90 || number > 90)) {
      return 'Latitude must be between -90 and 90';
    }
    if (!latitude && (number < -180 || number > 180)) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  Future<void> _openMySubmissions() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MyStationSubmissionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_submission != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Station Submitted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Station submitted for verification.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'It will appear in public station results only after approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openMySubmissions,
                    child: const Text('View My Submissions'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Suggest Station Changes' : 'Add Charger'),
        actions: [
          IconButton(
            tooltip: 'My submissions',
            onPressed: _openMySubmissions,
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (_editing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Your changes will be reviewed before they update this station.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              _field(
                _nameController,
                'Station name *',
                validator: (value) => _required(value, 'Station name'),
              ),
              _field(_addressController, 'Address or location description'),
              _field(_operatorController, 'Operator or network'),
              _field(_connectorController, 'Connector types (comma separated)'),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _chargersController,
                      'Number of chargers',
                      keyboardType: TextInputType.number,
                      validator: _optionalPositiveInteger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _powerController,
                      'Power (kW)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _optionalPositiveNumber,
                    ),
                  ),
                ],
              ),
              _field(_notesController, 'Notes', maxLines: 3),
              const SizedBox(height: 8),
              Text(
                'Location',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_locating ? 'Locating...' : 'Use current location'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _latitudeController,
                      'Latitude *',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _coordinate(value, latitude: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _longitudeController,
                      'Longitude *',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _coordinate(value, latitude: false),
                    ),
                  ),
                ],
              ),
              if (_possibleDuplicate) ...[
                const SizedBox(height: 8),
                Text(
                  'A nearby station has similar details. You can still submit this station; it will be checked during review.',
                  style: TextStyle(color: scheme.tertiary),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Station'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
