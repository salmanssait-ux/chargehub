import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'data/datasources/ocm_datasource.dart';
import 'data/repositories/station_repository_impl.dart';
import 'domain/repositories/station_repository.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final ocmDataSourceProvider = Provider<OcmDataSource>((ref) {
  return OcmDataSource(
    ref.watch(httpClientProvider),
  );
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepositoryImpl(
    ref.watch(ocmDataSourceProvider),
  );
});