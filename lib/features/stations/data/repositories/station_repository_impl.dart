import 'package:flutter/foundation.dart';

import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/supabase_stations_datasource.dart';
import '../datasources/ocm_datasource.dart';
import '../datasources/osm_datasource.dart';
import '../datasources/supabase_station_correction_datasource.dart';
import '../models/osm_station_model.dart';
import '../utils/station_correction_applier.dart';
import '../utils/station_deduplicator.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(
    this._ocmDataSource,
    this._osmDataSource,
    this._supabaseStationsDataSource,
    this._stationCorrectionDataSource,
  );

  final OcmDataSource _ocmDataSource;
  final OsmDataSource _osmDataSource;
  final SupabaseStationsDataSource _supabaseStationsDataSource;
  final SupabaseStationCorrectionDataSource _stationCorrectionDataSource;

  final _deduplicator = const StationDeduplicator();

  static const _remoteLoadTimeout = Duration(seconds: 12);

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final sourceResults = await Future.wait([
      _loadSupabaseStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
      _loadOcmStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
      _loadOsmStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ).timeout(
        _remoteLoadTimeout,
        onTimeout: () => const _StationLoadResult(
          error: 'Timed out while loading OSM stations.',
        ),
      ),
    ]);

    final supabaseResult = sourceResults[0];
    final ocmResult = sourceResults[1];
    final osmResult = sourceResults[2];

    if (supabaseResult.stations.isEmpty &&
        ocmResult.stations.isEmpty &&
        osmResult.stations.isEmpty) {
      if (supabaseResult.error == null) return const [];
      throw Exception(
        'No stations could be loaded.\n'
        'Supabase: ${supabaseResult.error ?? "No data"}\n'
        'OCM: ${ocmResult.error ?? "No data"}\n'
        'OSM: ${osmResult.error ?? "No data"}',
      );
    }

    final combined = [
      ...supabaseResult.stations,
      ...ocmResult.stations,
      ...osmResult.stations,
    ];

    final deduplicated = _deduplicator.deduplicate(combined);
    final correctedStations = await applyApprovedStationCorrections(
      stations: deduplicated,
      loadCorrections: _stationCorrectionDataSource.getForStationIds,
    );

    debugPrint('Supabase stations: ${supabaseResult.stations.length}');
    debugPrint('OCM stations: ${ocmResult.stations.length}');
    debugPrint('OSM stations: ${osmResult.stations.length}');
    debugPrint('Combined stations: ${combined.length}');
    debugPrint('After deduplication: ${deduplicated.length}');
    return correctedStations;
  }

  Future<_StationLoadResult> _loadOcmStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final models = await _ocmDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        distanceKm: radiusKm,
        maxResults: 100,
      );

      return _StationLoadResult(
        stations: models.map((model) => model.toEntity()).toList(),
      );
    } catch (error) {
      debugPrint('OCM failed: $error');
      return _StationLoadResult(error: error);
    }
  }

  Future<_StationLoadResult> _loadOsmStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final jsonStations = await _osmDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        distanceKm: radiusKm,
      );
      final stations = <Station>[];

      for (final json in jsonStations) {
        try {
          stations.add(
            OsmStationModel.fromJson(
              json,
              userLat: latitude,
              userLon: longitude,
            ).toEntity(),
          );
        } catch (error) {
          debugPrint('OSM station parse failed: $error');
        }
      }

      return _StationLoadResult(stations: stations);
    } catch (error) {
      debugPrint('OSM failed: $error');
      return _StationLoadResult(error: error);
    }
  }

  Future<_StationLoadResult> _loadSupabaseStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final stations = await _supabaseStationsDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return _StationLoadResult(stations: stations);
    } catch (error) {
      debugPrint('Supabase station refresh failed: $error');
      return _StationLoadResult(error: error);
    }
  }
}

class _StationLoadResult {
  const _StationLoadResult({this.stations = const [], this.error});

  final List<Station> stations;
  final Object? error;
}
