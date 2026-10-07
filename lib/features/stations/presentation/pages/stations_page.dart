import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../settings/presentation/widgets/chargehub_drawer.dart';
import '../../../settings/presentation/widgets/theme_selector.dart';
import '../../domain/entities/station.dart';
import '../controllers/stations_controller.dart';
import '../widgets/station_card.dart';
import 'add_station_page.dart';
import 'stations_map_page.dart';
import 'suggest_station_edit_page.dart';

class StationsPage extends ConsumerStatefulWidget {
  const StationsPage({super.key});

  @override
  ConsumerState<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends ConsumerState<StationsPage> {
  Station? _selectedStation;
  String _searchQuery = '';
  double _maxDistanceKm = 20;
  StationOperationalStatus? _statusFilter;

  void _selectStation(Station station) {
    _dismissKeyboard();

    setState(() {
      _selectedStation = station;
    });
  }

  void _clearSelectedStation() {
    setState(() {
      _selectedStation = null;
    });
  }

  Future<void> _openAddStation([Station? station]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStationPage(
          station: station,
          knownStations:
              ref.read(nearbyStationsProvider).valueOrNull ?? const [],
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() => _selectedStation = null);
      await ref.read(nearbyStationsProvider.notifier).retry();
    }
  }

  Future<void> _suggestStationEdit(Station station) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SuggestStationEditPage(station: station),
      ),
    );
  }

  bool _matchesSearch(Station station) {
    final query = _searchQuery.toLowerCase();

    final matchesSearch =
        query.isEmpty ||
        station.name.toLowerCase().contains(query) ||
        station.address.toLowerCase().contains(query);

    final matchesDistance = station.distanceKm <= _maxDistanceKm;

    final matchesStatus =
        _statusFilter == null || station.operationalStatus == _statusFilter;

    return matchesSearch && matchesDistance && matchesStatus;
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value.trim();

      if (_selectedStation != null && !_matchesSearch(_selectedStation!)) {
        _selectedStation = null;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
  }

  bool get _hasActiveFilters => _maxDistanceKm < 20 || _statusFilter != null;

  void _showFilters() {
    final scheme = Theme.of(context).colorScheme;

    double distance = _maxDistanceKm;
    StationOperationalStatus? status = _statusFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            distance = 20;
                            status = null;
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${distance.round()} km',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: distance,
                    min: 1,
                    max: 20,
                    onChanged: (value) {
                      setSheetState(() {
                        distance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: status == null,
                        onSelected: (_) {
                          setSheetState(() {
                            status = null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Operational'),
                        selected:
                            status == StationOperationalStatus.operational,
                        onSelected: (_) {
                          setSheetState(() {
                            status = StationOperationalStatus.operational;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Unavailable'),
                        selected:
                            status == StationOperationalStatus.unavailable,
                        onSelected: (_) {
                          setSheetState(() {
                            status = StationOperationalStatus.unavailable;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Unknown'),
                        selected: status == StationOperationalStatus.unknown,
                        onSelected: (_) {
                          setSheetState(() {
                            status = StationOperationalStatus.unknown;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _maxDistanceKm = distance;
                          _statusFilter = status;

                          if (_selectedStation != null &&
                              !_matchesSearch(_selectedStation!)) {
                            _selectedStation = null;
                          }
                        });

                        Navigator.pop(context);
                      },
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showThemes() {
    ThemeSelector.show(context);
  }

  Future<void> _openGoogleMaps(Station station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${station.latitude},${station.longitude}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final stationsAsync = ref.watch(nearbyStationsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      drawer: ChargeHubDrawer(
        onAddCharger: _openAddStation,
        onShowThemes: _showThemes,
      ),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        titleSpacing: 8,
        title: const Text(
          'ChargeHub',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Charger',
            onPressed: _openAddStation,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: stationsAsync.when(
          loading: () {
            return const _StationsPageSkeleton();
          },
          error: (_, _) {
            return _buildMapWithMessage(
              'Stations could not be loaded. The map is still available; try refreshing.',
              showRetry: true,
            );
          },
          data: (stations) {
            if (stations.isEmpty) {
              return _buildMapWithMessage('No charging stations found nearby.');
            }

            final filteredStations = stations.where(_matchesSearch).toList();

            return Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: _updateSearch,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search charging stations',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: _clearSearch,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _hasActiveFilters
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _showFilters,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.tune_rounded,
                              color: _hasActiveFilters
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (filteredStations.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ev_station_outlined,
                            size: 44,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No stations found',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try another name or address.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Map
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: StationsMapPage(
                                stations: filteredStations,
                                selectedStation: _selectedStation,
                                onStationSelected: _selectStation,
                              ),
                            ),
                          ),
                        ),

                        // Lower section
                        Expanded(
                          flex: 5,
                          child: _selectedStation == null
                              ? _StationList(
                                  stations: filteredStations,
                                  isSearching: _searchQuery.isNotEmpty,
                                  onStationSelected: _selectStation,
                                )
                              : _StationDetails(
                                  station: _selectedStation!,
                                  onBack: _clearSelectedStation,
                                  onOpenMaps: () =>
                                      _openGoogleMaps(_selectedStation!),
                                  onSuggestEdit: () =>
                                      _suggestStationEdit(_selectedStation!),
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapWithMessage(String message, {bool showRetry = false}) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: StationsMapPage(
                stations: const [],
                selectedStation: null,
                onStationSelected: _selectStation,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ev_station_outlined,
                    size: 42,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  if (showRetry) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(nearbyStationsProvider.notifier).retry();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StationsPageSkeleton extends StatelessWidget {
  const _StationsPageSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _SkeletonBlock(height: 50)),
              const SizedBox(width: 8),
              const _SkeletonBlock(width: 50, height: 50),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 22,
                    child: _SkeletonBlock(width: 94, height: 26),
                  ),
                  Center(child: Icon(Icons.map_rounded, size: 44)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            flex: 5,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, _) => const _SkeletonBlock(height: 82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ================================================================
// STATION LIST
// ================================================================

class _StationList extends StatelessWidget {
  const _StationList({
    required this.stations,
    required this.isSearching,
    required this.onStationSelected,
  });

  final List<Station> stations;
  final bool isSearching;
  final ValueChanged<Station> onStationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(
                isSearching ? 'Search Results' : 'Nearby Stations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stations.length} found',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    onStationSelected(station);
                  },
                  child: StationCard(station: station),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================================================================
// STATION DETAILS
// ================================================================

class _StationDetails extends StatelessWidget {
  const _StationDetails({
    required this.station,
    required this.onBack,
    required this.onOpenMaps,
    required this.onSuggestEdit,
  });

  final Station station;
  final VoidCallback onBack;
  final VoidCallback onOpenMaps;
  final VoidCallback onSuggestEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Station Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Card(
              color: colorScheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
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

                    const SizedBox(height: 12),

                    Text(
                      station.address.isEmpty
                          ? 'Address unavailable'
                          : station.address,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    if (station.operatorName != null ||
                        station.notes != null) ...[
                      const SizedBox(height: 12),
                      if (station.operatorName != null)
                        Text(
                          'Operator: ${station.operatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (station.notes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          station.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 14),

                    _DetailStatus(status: station.operationalStatus),

                    if (station.chargerCount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Charging points: ${station.chargerCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    Text(
                      'Connectors',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (station.connectors.isEmpty)
                      const _ConnectorChip(text: 'Unknown')
                    else
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: station.connectors
                            .map(
                              (connector) => _ConnectorChip(
                                text: _connectorText(connector),
                              ),
                            )
                            .toList(),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onSuggestEdit,
                        icon: const Icon(Icons.edit_note_rounded, size: 19),
                        label: const Text('Suggest an Edit'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onOpenMaps,
                        icon: const Icon(Icons.map_rounded, size: 19),
                        label: const Text(
                          'Open in Google Maps',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _connectorText(Connector connector) {
    final quantity = connector.quantity > 1 ? ' × ${connector.quantity}' : '';

    final power = connector.powerKw != null
        ? ' • ${connector.powerKw!.toStringAsFixed(1)} kW'
        : '';

    return '${connector.type}$quantity$power';
  }
}

// ================================================================
// CONNECTOR CHIP
// ================================================================

class _ConnectorChip extends StatelessWidget {
  const _ConnectorChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ================================================================
// STATUS
// ================================================================

class _DetailStatus extends StatelessWidget {
  const _DetailStatus({required this.status});

  final StationOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    late final Color statusColor;
    late final String text;

    switch (status) {
      case StationOperationalStatus.operational:
        statusColor = Colors.green;
        text = 'Operational';

      case StationOperationalStatus.unavailable:
        statusColor = Colors.red;
        text = 'Unavailable';

      case StationOperationalStatus.unknown:
        statusColor = colorScheme.onSurfaceVariant;
        text = 'Status unknown';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: statusColor),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
