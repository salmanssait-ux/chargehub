import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/stations_controller.dart';
import '../widgets/station_card.dart';

class StationsPage extends ConsumerWidget {
  const StationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(nearbyStationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChargeHub'),
      ),
      body: stations.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('No stations found'),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return StationCard(
                station: data[index],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
      ),
    );
  }
}
