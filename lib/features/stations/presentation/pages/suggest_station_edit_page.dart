import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/station.dart';
import '../../domain/entities/station_edit_suggestion.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../../providers.dart';

class SuggestStationEditPage extends ConsumerStatefulWidget {
  const SuggestStationEditPage({super.key, required this.station});

  final Station station;

  @override
  ConsumerState<SuggestStationEditPage> createState() =>
      _SuggestStationEditPageState();
}

class _SuggestStationEditPageState
    extends ConsumerState<SuggestStationEditPage> {
  static const _standardConnectorTypes = [
    'CCS2',
    'CCS',
    'Type 2',
    'Type 1',
    'CHAdeMO',
    'Schuko',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _chargerCountController;
  late final int? _currentChargerCount;
  late final List<String> _currentConnectorTypes;
  late final List<String> _connectorOptions;
  final Set<String> _selectedConnectorTypes = {};
  StationOperationalStatus? _selectedOperationalStatus;
  String? _connectorError;
  String? _statusError;
  String? _submissionError;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _nameController = TextEditingController(text: station.name);
    _addressController = TextEditingController(text: station.address);
    _currentChargerCount =
        station.chargerCount ??
        (station.connectors.isEmpty
            ? null
            : station.connectors.fold<int>(
                0,
                (total, connector) => total + connector.quantity,
              ));
    _chargerCountController = TextEditingController(
      text: _currentChargerCount?.toString() ?? '',
    );
    _currentConnectorTypes = station.connectors
        .map((connector) => connector.type.trim())
        .where((type) => type.isNotEmpty && type.toLowerCase() != 'unknown')
        .toSet()
        .toList();
    _selectedConnectorTypes.addAll(_currentConnectorTypes);
    _connectorOptions = {
      ..._standardConnectorTypes,
      ..._currentConnectorTypes,
    }.toList();
    _selectedOperationalStatus =
        station.operationalStatus == StationOperationalStatus.unknown
        ? null
        : station.operationalStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _chargerCountController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _validateChargerCount(String? value) {
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null || count < 1) {
      return 'Enter a positive whole number.';
    }
    return null;
  }

  StationEditSuggestion _suggestion() {
    final station = widget.station;
    return StationEditSuggestion(
      stationId: station.id,
      currentName: station.name,
      currentAddress: station.address,
      currentChargerCount: _currentChargerCount,
      currentConnectorTypes: _currentConnectorTypes,
      currentOperationalStatus: station.operationalStatus,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      chargerCount: int.parse(_chargerCountController.text.trim()),
      connectorTypes: _connectorOptions
          .where(_selectedConnectorTypes.contains)
          .toList(),
      operationalStatus: _selectedOperationalStatus!,
    );
  }

  bool _hasChanges(StationEditSuggestion suggestion) {
    final oldTypes = suggestion.currentConnectorTypes
        .map((type) => type.toLowerCase())
        .toSet();
    final newTypes = suggestion.connectorTypes
        .map((type) => type.toLowerCase())
        .toSet();
    return suggestion.name != suggestion.currentName ||
        suggestion.address != suggestion.currentAddress ||
        suggestion.chargerCount != suggestion.currentChargerCount ||
        oldTypes.length != newTypes.length ||
        !oldTypes.containsAll(newTypes) ||
        suggestion.operationalStatus != suggestion.currentOperationalStatus;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _connectorError = _selectedConnectorTypes.isEmpty
          ? 'Select at least one charger type.'
          : null;
      _statusError = _selectedOperationalStatus == null
          ? 'Select a status.'
          : null;
      _submissionError = null;
    });
    if (!valid || _connectorError != null || _statusError != null) return;

    final suggestion = _suggestion();
    if (!_hasChanges(suggestion)) {
      setState(() => _submissionError = 'Update at least one station detail.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(stationEditSuggestionRepositoryProvider)
          .submit(suggestion);
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionError = error is StationSubmissionFailure
            ? error.message
            : 'We could not submit this edit. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suggest an Edit')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank you!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your station edit has been submitted for review.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suggest an Edit')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                'Update the information below with the correct station details.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('edit-station-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Station name'),
                decoration: const InputDecoration(labelText: 'Station name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('edit-station-address'),
                controller: _addressController,
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Address'),
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('edit-charger-count'),
                controller: _chargerCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateChargerCount,
                decoration: const InputDecoration(
                  labelText: 'Number of chargers',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Charger type(s)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Select every connector available at this station.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in _connectorOptions)
                    FilterChip(
                      key: ValueKey('connector-$type'),
                      label: Text(type),
                      selected: _selectedConnectorTypes.contains(type),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedConnectorTypes.add(type);
                          } else {
                            _selectedConnectorTypes.remove(type);
                          }
                          _connectorError = null;
                          _submissionError = null;
                        });
                      },
                    ),
                ],
              ),
              if (_connectorError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _connectorError!,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Operational status',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<StationOperationalStatus>(
                key: const ValueKey('edit-operational-status'),
                emptySelectionAllowed: true,
                selected: _selectedOperationalStatus == null
                    ? const {}
                    : {_selectedOperationalStatus!},
                segments: const [
                  ButtonSegment(
                    value: StationOperationalStatus.operational,
                    label: Text('Operational'),
                  ),
                  ButtonSegment(
                    value: StationOperationalStatus.unavailable,
                    label: Text('Not Operational'),
                  ),
                ],
                onSelectionChanged: (values) {
                  setState(() {
                    _selectedOperationalStatus = values.isEmpty
                        ? null
                        : values.first;
                    _statusError = null;
                    _submissionError = null;
                  });
                },
              ),
              if (_statusError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    _statusError!,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              if (widget.station.operationalStatus ==
                  StationOperationalStatus.unknown)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Current status: Unknown. Please choose the correct status.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_submissionError != null) ...[
                const SizedBox(height: 16),
                Text(_submissionError!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
