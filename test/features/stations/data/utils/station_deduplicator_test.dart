import 'package:chargebub/features/stations/data/utils/station_deduplicator.dart';
import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a public Supabase station ID when merging a live duplicate', () {
    const supabaseStation = Station(
      id: '11111111-1111-4111-8111-111111111111',
      name: 'Charging Hub',
      address: 'Main Road',
      latitude: 19.076,
      longitude: 72.8777,
      distanceKm: 1,
      operationalStatus: StationOperationalStatus.operational,
      isPublic: true,
      connectors: [],
      source: StationSource.supabase,
      sourceName: 'EcoGears June 2026',
    );
    const osmStation = Station(
      id: 'osm-123',
      name: 'Charging Hub',
      address: 'Main Road',
      latitude: 19.076,
      longitude: 72.8777,
      distanceKm: 1,
      operationalStatus: StationOperationalStatus.unknown,
      isPublic: null,
      connectors: [],
      source: StationSource.osm,
    );

    final stations = const StationDeduplicator().deduplicate([
      osmStation,
      supabaseStation,
    ]);

    expect(stations, hasLength(1));
    expect(stations.single.id, supabaseStation.id);
    expect(stations.single.source, StationSource.supabase);
    expect(stations.single.sourceName, 'EcoGears June 2026');
  });
}
