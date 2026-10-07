import '../entities/station.dart';

abstract class UserStationRepository {
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  });

  Future<void> save(Station station);

  Future<void> delete(String id);
}
