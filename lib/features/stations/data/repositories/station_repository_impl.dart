import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/ocm_datasource.dart';
import '../datasources/osm_datasource.dart';
import '../datasources/zigwheels_datasource.dart';
import '../models/osm_station_model.dart';
import '../utils/station_deduplicator.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(
      this._ocmDataSource,
      this._osmDataSource,
      this._zigWheelsDataSource,
      );

  final OcmDataSource _ocmDataSource;
  final OsmDataSource _osmDataSource;
  final ZigWheelsDataSource _zigWheelsDataSource;

  final _deduplicator = const StationDeduplicator();

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    List<Station> ocmStations = [];
    List<Station> osmStations = [];
    List<Station> zigWheelsStations = [];

    Object? ocmError;
    Object? osmError;
    Object? zigWheelsError;

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

    try {
      final zigWheelsModels =
      await _zigWheelsDataSource.getStations();

      zigWheelsStations = zigWheelsModels
          .map(
            (model) => model.toEntity(
          userLatitude: latitude,
          userLongitude: longitude,
        ),
      )
          .where(
            (station) => station.distanceKm <= radiusKm,
      )
          .toList();

      print(
        'ZigWheels stations within $radiusKm km: '
        '${zigWheelsStations.length}',
      );
    } catch (e) {
      zigWheelsError = e;
      print('ZigWheels failed: $e');
    }

    if (ocmStations.isEmpty &&
        osmStations.isEmpty &&
        zigWheelsStations.isEmpty) {
      throw Exception(
        'No stations could be loaded.\n'
            'OCM: ${ocmError ?? "No data"}\n'
            'OSM: ${osmError ?? "No data"}\n'
            'ZigWheels: ${zigWheelsError ?? "No data"}',
      );
    }

    final combined = [
      ...ocmStations,
      ...osmStations,
      ...zigWheelsStations,
    ];

    final deduplicated =
        _deduplicator.deduplicate(combined);

    print('OCM stations: ${ocmStations.length}');
    print('OSM stations: ${osmStations.length}');
    print(
      'ZigWheels stations: ${zigWheelsStations.length}',
    );
    print('Combined stations: ${combined.length}');
    print(
      'After deduplication: ${deduplicated.length}',
    );

    return deduplicated;
  }
}