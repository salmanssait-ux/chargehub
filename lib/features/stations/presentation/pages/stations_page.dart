import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/stations_controller.dart';
import '../../domain/entities/station.dart';
import '../widgets/station_card.dart';
import 'stations_map_page.dart';

class StationsPage extends ConsumerStatefulWidget {
  const StationsPage({super.key});

  @override
  ConsumerState<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends ConsumerState<StationsPage> {
  static const _blue = Color(0xFF2563EB);
  static const _background = Color(0xFFF4F7FB);

  Station? _selectedStation;

  void _selectStation(Station station) {
    setState(() {
      _selectedStation = station;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedStation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(nearbyStationsProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'ChargeHub',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: stationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _blue,
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (stations) {
          if (stations.isEmpty) {
            return const Center(
              child: Text(
                'No charging stations found nearby',
              ),
            );
          }

          return Column(
            children: [
              // Map
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: StationsMapPage(
                        stations: stations,
                        selectedStation: _selectedStation,
                        onStationSelected: _selectStation,
                      ),
                    ),
                  ),
                ),
              ),

              // Lower section
              Expanded(
                flex: 5,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _selectedStation == null
                      ? _StationList(
                    key: const ValueKey('station-list'),
                    stations: stations,
                    onStationSelected: _selectStation,
                  )
                      : _StationDetails(
                    key: ValueKey(
                      _selectedStation!.name,
                    ),
                    station: _selectedStation!,
                    onBack: _clearSelection,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StationList extends StatelessWidget {
  const _StationList({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  final List<Station> stations;
  final ValueChanged<Station> onStationSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8,
          ),
          child: Row(
            children: [
              const Text(
                'Nearby Stations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stations.length} found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              2,
              16,
              16,
            ),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  onStationSelected(stations[index]);
                },
                child: StationCard(
                  station: stations[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StationDetails extends StatelessWidget {
  const _StationDetails({
    super.key,
    required this.station,
    required this.onBack,
  });

  final Station station;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              4,
              16,
              4,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                  color: const Color(0xFF2563EB),
                ),
                const Text(
                  'Station Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.10),
                            borderRadius:
                            BorderRadius.circular(20),
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

                    const SizedBox(height: 10),

                    Text(
                      station.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _StatusRow(
                      status: station.operationalStatus,
                    ),

                    if (station.connectors.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Connectors',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                        station.connectors.map((connector) {
                          final quantity =
                          connector.quantity > 1
                              ? ' × ${connector.quantity}'
                              : '';

                          final power =
                          connector.powerKw != null
                              ? ' • ${connector.powerKw!.toStringAsFixed(1)} kW'
                              : '';

                          return Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F5FF),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${connector.type}$quantity$power',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _openGoogleMaps(
                            context,
                            station,
                          );
                        },
                        icon: const Icon(
                          Icons.map_rounded,
                          size: 19,
                        ),
                        label: const Text(
                          'Open in Google Maps',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    Station station,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${station.latitude},${station.longitude}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
        ),
      );
    }
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
  });

  final StationOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StationOperationalStatus.operational:
        return const Row(
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: Colors.green,
            ),
            SizedBox(width: 6),
            Text(
              'Operational',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case StationOperationalStatus.unavailable:
        return const Row(
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: Colors.red,
            ),
            SizedBox(width: 6),
            Text(
              'Unavailable',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case StationOperationalStatus.unknown:
        return Row(
          children: [
            const Icon(
              Icons.circle,
              size: 9,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              'Status unknown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}