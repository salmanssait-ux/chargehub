import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/common_providers.dart';
import 'data/datasources/ocm_datasource.dart';
import 'data/datasources/osm_datasource.dart';
import 'data/repositories/station_repository_impl.dart';
import 'domain/repositories/station_repository.dart';

final ocmDataSourceProvider = Provider<OcmDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return OcmDataSource(client);
});

final osmDataSourceProvider = Provider<OsmDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return OsmDataSource(client);
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final ocmDataSource = ref.watch(ocmDataSourceProvider);
  final osmDataSource = ref.watch(osmDataSourceProvider);

  return StationRepositoryImpl(
    ocmDataSource,
    osmDataSource,
  );
});
