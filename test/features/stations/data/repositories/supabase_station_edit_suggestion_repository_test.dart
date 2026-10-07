import 'package:chargebub/features/stations/data/datasources/supabase_station_edit_suggestion_datasource.dart';
import 'package:chargebub/features/stations/data/repositories/supabase_station_edit_suggestion_repository.dart';
import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:chargebub/features/stations/domain/entities/station_edit_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SupabaseStationEditSuggestionRepository repository;

  setUp(() {
    repository = SupabaseStationEditSuggestionRepository(
      SupabaseStationEditSuggestionDataSource(null),
    );
  });

  test('rejects missing name and address before contacting Supabase', () async {
    await expectLater(
      repository.submit(_suggestion(name: ' ')),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.submit(_suggestion(address: ' ')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects invalid charger count, connector list, and status', () async {
    await expectLater(
      repository.submit(_suggestion(chargerCount: 0)),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.submit(_suggestion(connectorTypes: const [])),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.submit(
        _suggestion(operationalStatus: StationOperationalStatus.unknown),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects a complete form when no station value changed', () async {
    await expectLater(
      repository.submit(
        _suggestion(
          name: 'Station',
          address: 'Main Road',
          currentAddress: 'Main Road',
          chargerCount: 2,
          connectorTypes: const ['CCS2'],
          operationalStatus: StationOperationalStatus.operational,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}

StationEditSuggestion _suggestion({
  String name = 'Updated Station',
  String address = 'Main Road',
  String currentAddress = 'Old Road',
  int chargerCount = 4,
  List<String> connectorTypes = const ['CCS2', 'Type 2'],
  StationOperationalStatus operationalStatus =
      StationOperationalStatus.unavailable,
}) {
  return StationEditSuggestion(
    stationId: 'station-1',
    currentName: 'Station',
    currentAddress: currentAddress,
    currentChargerCount: 2,
    currentConnectorTypes: const ['CCS2'],
    currentOperationalStatus: StationOperationalStatus.operational,
    name: name,
    address: address,
    chargerCount: chargerCount,
    connectorTypes: connectorTypes,
    operationalStatus: operationalStatus,
  );
}
