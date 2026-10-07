import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../../providers.dart';

final nearbyStationsProvider =
    StateNotifierProvider<NearbyStationsController, AsyncValue<List<Station>>>((
      ref,
    ) {
      return NearbyStationsController(
        repository: ref.watch(stationRepositoryProvider),
        locationService: ref.watch(locationServiceProvider),
      );
    });

class NearbyStationsController
    extends StateNotifier<AsyncValue<List<Station>>> {
  NearbyStationsController({
    required this._repository,
    required this._locationService,
  }) : super(const AsyncLoading()) {
    _loadStations();
  }

  final StationRepository _repository;
  final LocationService _locationService;

  static const _radiusKm = 20.0;
  static const _fallbackLatitude = 19.0760;
  static const _fallbackLongitude = 72.8777;

  Future<void> retry() async {
    state = const AsyncLoading();
    await _loadStations();
  }

  Future<void> _loadStations() async {
    late double latitude;
    late double longitude;
    try {
      final position = await _locationService.getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (error) {
      debugPrint('Location unavailable, using Mumbai fallback: $error');
      latitude = _fallbackLatitude;
      longitude = _fallbackLongitude;
    }

    try {
      await _loadStationsForLocation(latitude: latitude, longitude: longitude);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _loadStationsForLocation({
    required double latitude,
    required double longitude,
  }) async {
    final stations = await _repository.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: _radiusKm,
    );
    state = AsyncData(stations);
  }
}
