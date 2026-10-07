import 'package:chargebub/features/stations/data/utils/station_correction_applier.dart';
import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:chargebub/features/stations/domain/entities/station_correction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no correction leaves the original station unchanged', () async {
    final station = _station();
    final result = await applyApprovedStationCorrections(
      stations: [station],
      loadCorrections: (_) async => const {},
    );

    expect(identical(result.single, station), isTrue);
  });

  test('overrides only the five corrected fields', () async {
    final station = _station();
    final result = await applyApprovedStationCorrections(
      stations: [station],
      loadCorrections: (_) async => {
        station.id: const StationCorrection(
          stationId: 'zigwheels_mumbai_0003',
          name: 'Corrected station name',
          address: 'Corrected address',
          chargerCount: 4,
          connectorTypes: ['CCS2', 'Type 2'],
          operationalStatus: StationOperationalStatus.operational,
        ),
      },
    );
    final corrected = result.single;

    expect(corrected.id, station.id);
    expect(corrected.name, 'Corrected station name');
    expect(corrected.address, 'Corrected address');
    expect(corrected.chargerCount, 4);
    expect(corrected.connectors.map((connector) => connector.type), [
      'CCS2',
      'Type 2',
    ]);
    expect(corrected.operationalStatus, StationOperationalStatus.operational);
    expect(corrected.latitude, station.latitude);
    expect(corrected.longitude, station.longitude);
    expect(corrected.distanceKm, station.distanceKm);
    expect(corrected.operatorName, station.operatorName);
    expect(corrected.source, station.source);
    expect(corrected.isPublic, station.isPublic);
    expect(corrected.notes, station.notes);
    expect(corrected.connectors.first.powerKw, 50);
    expect(corrected.connectors.first.currentType, 'DC');
    expect(corrected.connectors.first.quantity, 2);
    expect(corrected.connectors.last.powerKw, isNull);
  });

  test('fetches multiple station corrections in a single batch', () async {
    final stations = [
      _station(),
      _station(
        id: 'ocm:station-2',
        name: 'Another station',
        source: StationSource.ocm,
      ),
    ];
    var loadCount = 0;
    Set<String>? requestedIds;

    final result = await applyApprovedStationCorrections(
      stations: stations,
      loadCorrections: (ids) async {
        loadCount++;
        requestedIds = ids.toSet();
        return {
          for (final station in stations)
            station.id: StationCorrection(
              stationId: station.id,
              name: 'Corrected ${station.id}',
            ),
        };
      },
    );

    expect(loadCount, 1);
    expect(requestedIds, {for (final station in stations) station.id});
    expect(result.map((station) => station.name), [
      'Corrected zigwheels_mumbai_0003',
      'Corrected ocm:station-2',
    ]);
  });

  test('keeps all original stations if correction lookup fails', () async {
    final stations = [_station(), _station(id: 'osm:station-4')];
    final result = await applyApprovedStationCorrections(
      stations: stations,
      loadCorrections: (_) => Future.error(Exception('offline')),
    );

    expect(result, hasLength(2));
    expect(identical(result[0], stations[0]), isTrue);
    expect(identical(result[1], stations[1]), isTrue);
  });

  test('does not query corrections for an empty station list', () async {
    var queried = false;
    final result = await applyApprovedStationCorrections(
      stations: const [],
      loadCorrections: (_) async {
        queried = true;
        return const {};
      },
    );

    expect(result, isEmpty);
    expect(queried, isFalse);
  });
}

Station _station({
  String id = 'zigwheels_mumbai_0003',
  String name = 'Original name',
  StationSource source = StationSource.supabase,
}) {
  return Station(
    id: id,
    name: name,
    address: 'Original address',
    latitude: 19.076,
    longitude: 72.8777,
    distanceKm: 3.2,
    operationalStatus: StationOperationalStatus.unavailable,
    isPublic: true,
    connectors: const [
      Connector(type: 'CCS2', currentType: 'DC', powerKw: 50, quantity: 2),
    ],
    source: source,
    chargerCount: 2,
    operatorName: 'Original operator',
    notes: 'Unchanged metadata',
  );
}
