import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/location_provider.dart';
import '../../domain/entities/station.dart';
import '../../providers.dart';

final nearbyStationsProvider = FutureProvider<List<Station>>((ref) async {
  final repository = ref.watch(stationRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);

  final position = await locationService.getCurrentLocation();

  return repository.getNearbyStations(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusKm: 10,
  );
});