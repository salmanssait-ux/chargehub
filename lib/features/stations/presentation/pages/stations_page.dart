import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/stations_controller.dart';
import '../widgets/station_card.dart';
import 'stations_map_page.dart';

class StationsPage extends ConsumerWidget {
  const StationsPage({super.key});

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final stationsAsync = ref.watch(nearbyStationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ChargeHub'),
        centerTitle: true,
      ),
      body: stationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
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
                flex: 5,
                child: StationsMapPage(
                  stations: stations,
                ),
              ),

              // Station list header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  8,
                ),
                color: Colors.grey.shade50,
                child: Row(
                  children: [
                    const Text(
                      'Nearby Stations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${stations.length} found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Station list
              Expanded(
                flex: 6,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    16,
                  ),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    return StationCard(
                      station: stations[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}