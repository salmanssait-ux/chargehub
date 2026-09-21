import '../entities/station.dart';

abstract class StationRepository {
  Future<List<Station>> getNearbyLocalStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });
}
