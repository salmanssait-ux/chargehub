import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../../providers.dart';

final nearbyStationsProvider = StateNotifierProvider<
    NearbyStationsController, AsyncValue<List<Station>>>((ref) {
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
  })  : super(const AsyncLoading()) {
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
    try {
      final position = await _locationService.getCurrentLocation();
      await _loadStationsForLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      print('Location unavailable, using Mumbai fallback: $error');

      try {
        await _loadStationsForLocation(
          latitude: _fallbackLatitude,
          longitude: _fallbackLongitude,
        );
      } catch (fallbackError, fallbackStackTrace) {
        state = AsyncError(fallbackError, fallbackStackTrace);
      }
    }
  }

  Future<void> _loadStationsForLocation({
    required double latitude,
    required double longitude,
  }) async {
    final localStations = await _repository.getNearbyLocalStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: _radiusKm,
    );

    state = AsyncData(localStations);
    unawaited(_refreshFromRemoteSources(latitude, longitude));
  }

  Future<void> _refreshFromRemoteSources(
    double latitude,
    double longitude,
  ) async {
    try {
      final stations = await _repository.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _radiusKm,
      );
      state = AsyncData(stations);
    } catch (error) {
      // Keep the local stations visible if an optional remote source fails.
      print('Remote station refresh failed: $error');
    }
  }
}
