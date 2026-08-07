import '../entities/station.dart';

abstract class StationRepository {
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });
}