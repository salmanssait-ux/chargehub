import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:chargebub/features/stations/domain/entities/station_edit_suggestion.dart';
import 'package:chargebub/features/stations/domain/repositories/station_edit_suggestion_repository.dart';
import 'package:chargebub/features/stations/presentation/pages/suggest_station_edit_page.dart';
import 'package:chargebub/features/stations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prefills all five editable details from the station', (
    tester,
  ) async {
    await _showEditPage(tester, _FakeEditRepository());

    expect(_field(tester, 'edit-station-name').controller!.text, 'Old Station');
    expect(_field(tester, 'edit-station-address').controller!.text, 'Old Road');
    expect(_field(tester, 'edit-charger-count').controller!.text, '2');
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('connector-CCS2')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<SegmentedButton<StationOperationalStatus>>(
            find.byKey(const ValueKey('edit-operational-status')),
          )
          .selected,
      {StationOperationalStatus.operational},
    );
  });

  testWidgets('submits corrected values for exactly the editable fields', (
    tester,
  ) async {
    final repository = _FakeEditRepository();
    await _showEditPage(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('edit-station-name')),
      'New Station',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-station-address')),
      'New Road',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-charger-count')),
      '4',
    );
    await tester.tap(find.byKey(const ValueKey('connector-Type 2')));
    await tester.tap(find.byKey(const ValueKey('connector-CCS')));
    await tester.tap(find.text('Not Operational'));
    await tester.tap(find.text('Submit Edit'));
    await tester.pumpAndSettle();

    final suggestion = repository.suggestion!;
    expect(suggestion.stationId, 'osm:station-42');
    expect(suggestion.name, 'New Station');
    expect(suggestion.address, 'New Road');
    expect(suggestion.chargerCount, 4);
    expect(suggestion.connectorTypes, ['CCS2', 'CCS']);
    expect(suggestion.operationalStatus, StationOperationalStatus.unavailable);
    expect(
      find.text('Your station edit has been submitted for review.'),
      findsOneWidget,
    );
    expect(find.text('Additional Notes'), findsNothing);
    expect(find.text('Latitude'), findsNothing);
    expect(find.text('Longitude'), findsNothing);
  });

  testWidgets('requires valid values and at least one connector type', (
    tester,
  ) async {
    await _showEditPage(tester, _FakeEditRepository());

    await tester.enterText(find.byKey(const ValueKey('edit-station-name')), '');
    await tester.enterText(
      find.byKey(const ValueKey('edit-station-address')),
      '',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-charger-count')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('connector-CCS2')));
    await tester.tap(find.byKey(const ValueKey('connector-Type 2')));
    await tester.tap(find.text('Submit Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Station name is required.'), findsOneWidget);
    expect(find.text('Address is required.'), findsOneWidget);
    expect(find.text('Enter a positive whole number.'), findsOneWidget);
    expect(find.text('Select at least one charger type.'), findsOneWidget);
  });
}

TextFormField _field(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(ValueKey(key)));
}

Future<void> _showEditPage(
  WidgetTester tester,
  _FakeEditRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stationEditSuggestionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: SuggestStationEditPage(station: _station())),
    ),
  );
}

Station _station() {
  return const Station(
    id: 'osm:station-42',
    name: 'Old Station',
    address: 'Old Road',
    latitude: 19.07,
    longitude: 72.87,
    distanceKm: 1,
    operationalStatus: StationOperationalStatus.operational,
    isPublic: true,
    connectors: [
      Connector(type: 'CCS2', currentType: 'DC', powerKw: 50, quantity: 1),
      Connector(type: 'Type 2', currentType: 'AC', powerKw: 22, quantity: 1),
    ],
    source: StationSource.osm,
    chargerCount: 2,
  );
}

class _FakeEditRepository implements StationEditSuggestionRepository {
  StationEditSuggestion? suggestion;

  @override
  Future<void> submit(StationEditSuggestion suggestion) async {
    this.suggestion = suggestion;
  }
}
