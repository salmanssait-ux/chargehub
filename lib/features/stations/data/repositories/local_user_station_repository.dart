import 'dart:math' as math;

import '../../domain/entities/station.dart';
import '../../domain/repositories/user_station_repository.dart';
import '../datasources/local_user_station_datasource.dart';

class LocalUserStationRepository implements UserStationRepository {
  LocalUserStationRepository(this._dataSource);

  final LocalUserStationDataSource _dataSource;

  @override
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async {
    return _dataSource
        .readStations()
        .map((station) => _withDistance(station, latitude, longitude))
        .where((station) => station.distanceKm <= radiusKm)
        .toList();
  }

  @override
  Future<void> save(Station station) async {
    final stations = _dataSource.readStations();
    final index = stations.indexWhere((item) => item.id == station.id);

    if (index == -1) {
      stations.add(station);
    } else {
      stations[index] = station;
    }

    await _dataSource.writeStations(stations);
  }

  @override
  Future<void> delete(String id) async {
    final stations = _dataSource
        .readStations()
        .where((station) => station.id != id)
        .toList();
    await _dataSource.writeStations(stations);
  }

  Station _withDistance(Station station, double latitude, double longitude) {
    return Station(
      id: station.id,
      name: station.name,
      address: station.address,
      latitude: station.latitude,
      longitude: station.longitude,
      distanceKm: _distanceKm(
        latitude,
        longitude,
        station.latitude,
        station.longitude,
      ),
      operationalStatus: station.operationalStatus,
      isPublic: station.isPublic,
      connectors: station.connectors,
      source: station.source,
      chargerCount: station.chargerCount,
      operatorName: station.operatorName,
      notes: station.notes,
      sourceName: station.sourceName,
    );
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
