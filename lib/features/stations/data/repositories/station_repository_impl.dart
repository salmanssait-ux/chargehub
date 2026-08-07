import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/ocm_datasource.dart';

class StationRepositoryImpl implements StationRepository {
  const StationRepositoryImpl(this._ocmDataSource);

  final OcmDataSource _ocmDataSource;

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final stations = await _ocmDataSource.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      distanceKm: radiusKm,
    );

    return stations.map((station) => station.toEntity()).toList();
  }
}
