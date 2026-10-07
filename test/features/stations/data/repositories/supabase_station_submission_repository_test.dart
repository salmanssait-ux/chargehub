import 'package:chargebub/features/stations/data/datasources/supabase_station_submission_datasource.dart';
import 'package:chargebub/features/stations/data/repositories/supabase_station_submission_repository.dart';
import 'package:chargebub/features/stations/domain/entities/station_submission.dart';
import 'package:chargebub/features/stations/domain/errors/station_submission_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SupabaseStationSubmissionRepository repository;

  setUp(() {
    repository = SupabaseStationSubmissionRepository(
      SupabaseStationSubmissionDataSource(null),
    );
  });

  test('rejects an empty station name before contacting Supabase', () async {
    await expectLater(
      repository.submit(
        const StationSubmissionDraft(
          id: 'submission-id',
          name: ' ',
          latitude: 19.07,
          longitude: 72.87,
          connectorTypes: [],
          chargerCount: 1,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects invalid coordinates before contacting Supabase', () async {
    await expectLater(
      repository.submit(
        const StationSubmissionDraft(
          id: 'submission-id',
          name: 'Station',
          latitude: 91,
          longitude: 72.87,
          connectorTypes: [],
          chargerCount: 1,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'reports missing Supabase configuration instead of storing locally',
    () async {
      await expectLater(
        repository.submit(
          const StationSubmissionDraft(
            id: 'submission-id',
            name: 'Station',
            latitude: 19.07,
            longitude: 72.87,
            connectorTypes: [],
            chargerCount: 1,
          ),
        ),
        throwsA(isA<StationSubmissionFailure>()),
      );
    },
  );
}
