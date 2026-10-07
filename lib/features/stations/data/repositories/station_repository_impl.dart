import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/ocm_datasource.dart';
import '../datasources/osm_datasource.dart';
import '../datasources/supabase_approved_station_datasource.dart';
import '../datasources/supabase_station_correction_datasource.dart';
import '../datasources/zigwheels_datasource.dart';
import '../models/osm_station_model.dart';
import '../utils/station_correction_applier.dart';
import '../utils/station_deduplicator.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(
    this._ocmDataSource,
    this._osmDataSource,
    this._zigWheelsDataSource,
    this._approvedStationDataSource,
    this._stationCorrectionDataSource,
  );

  final OcmDataSource _ocmDataSource;
  final OsmDataSource _osmDataSource;
  final ZigWheelsDataSource _zigWheelsDataSource;
  final SupabaseApprovedStationDataSource _approvedStationDataSource;
  final SupabaseStationCorrectionDataSource _stationCorrectionDataSource;

  final _deduplicator = const StationDeduplicator();

  static const _remoteLoadTimeout = Duration(seconds: 12);

  @override
  Future<List<Station>> getNearbyLocalStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final result = await _loadZigWheelsStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    if (result.error != null) {
      throw result.error!;
    }

    return applyApprovedStationCorrections(
      stations: result.stations,
      loadCorrections: _stationCorrectionDataSource.getForStationIds,
    );
  }

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final sourceResults = await Future.wait([
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
      _loadZigWheelsStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
      _loadApprovedStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
    ]);

    final ocmResult = sourceResults[0];
    final osmResult = sourceResults[1];
    final zigWheelsResult = sourceResults[2];
    final approvedResult = sourceResults[3];

    if (ocmResult.stations.isEmpty &&
        osmResult.stations.isEmpty &&
        zigWheelsResult.stations.isEmpty &&
        approvedResult.stations.isEmpty) {
      throw Exception(
        'No stations could be loaded.\n'
        'OCM: ${ocmResult.error ?? "No data"}\n'
        'OSM: ${osmResult.error ?? "No data"}\n'
        'ZigWheels: ${zigWheelsResult.error ?? "No data"}\n'
        'Approved stations: ${approvedResult.error ?? "No data"}',
      );
    }

    final combined = [
      ...ocmResult.stations,
      ...osmResult.stations,
      ...zigWheelsResult.stations,
      ...approvedResult.stations,
    ];

    final deduplicated = _deduplicator.deduplicate(combined);
    final correctedStations = await applyApprovedStationCorrections(
      stations: deduplicated,
      loadCorrections: _stationCorrectionDataSource.getForStationIds,
    );

    print('OCM stations: ${ocmResult.stations.length}');
    print('OSM stations: ${osmResult.stations.length}');
    print('ZigWheels stations: ${zigWheelsResult.stations.length}');
    print('Approved user stations: ${approvedResult.stations.length}');
    print('Combined stations: ${combined.length}');
    print('After deduplication: ${deduplicated.length}');
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
      print('OCM failed: $error');
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
          print('OSM station parse failed: $error');
        }
      }

      return _StationLoadResult(stations: stations);
    } catch (error) {
      print('OSM failed: $error');
      return _StationLoadResult(error: error);
    }
  }

  Future<_StationLoadResult> _loadZigWheelsStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final models = await _zigWheelsDataSource.getStations();
      final stations = models
          .map(
            (model) => model.toEntity(
              userLatitude: latitude,
              userLongitude: longitude,
            ),
          )
          .where((station) => station.distanceKm <= radiusKm)
          .toList();

      print('ZigWheels stations within $radiusKm km: ${stations.length}');
      return _StationLoadResult(stations: stations);
    } catch (error) {
      print('ZigWheels failed: $error');
      return _StationLoadResult(error: error);
    }
  }

  Future<_StationLoadResult> _loadApprovedStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final stations = await _approvedStationDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return _StationLoadResult(stations: stations);
    } catch (error) {
      print('Approved station refresh failed: $error');
      return _StationLoadResult(error: error);
    }
  }
}

class _StationLoadResult {
  const _StationLoadResult({this.stations = const [], this.error});

  final List<Station> stations;
  final Object? error;
}
