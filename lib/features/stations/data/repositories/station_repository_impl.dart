import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/ocm_datasource.dart';
import '../datasources/osm_datasource.dart';
import '../models/osm_station_model.dart';
import '../utils/station_deduplicator.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(
      this._ocmDataSource,
      this._osmDataSource,
      );

  final OcmDataSource _ocmDataSource;
  final OsmDataSource _osmDataSource;

  final _deduplicator = const StationDeduplicator();

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    List<Station> ocmStations = [];
    List<Station> osmStations = [];

    Object? ocmError;
    Object? osmError;

    try {
      final ocmModels =
      await _ocmDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        distanceKm: radiusKm,
        maxResults: 100,
      );

      ocmStations = ocmModels
          .map((model) => model.toEntity())
          .toList();
    } catch (e) {
      ocmError = e;
      print('OCM failed: $e');
    }

    try {
      final osmJson =
      await _osmDataSource.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        distanceKm: radiusKm,
      );

      for (final json in osmJson) {
        try {
          final station = OsmStationModel.fromJson(
            json,
            userLat: latitude,
            userLon: longitude,
          ).toEntity();

          osmStations.add(station);
        } catch (e) {
          print('OSM station parse failed: $e');
        }
      }
    } catch (e) {
      osmError = e;
      print('OSM failed: $e');
    }

    if (ocmStations.isEmpty && osmStations.isEmpty) {
      throw Exception(
        'No stations could be loaded.\n'
            'OCM: ${ocmError ?? "No data"}\n'
            'OSM: ${osmError ?? "No data"}',
      );
    }

    final combined = [
      ...ocmStations,
      ...osmStations,
    ];

    return _deduplicator.deduplicate(combined);
  }
}