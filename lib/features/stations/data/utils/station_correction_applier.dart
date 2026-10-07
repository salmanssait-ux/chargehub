import 'package:flutter/foundation.dart';

import '../../domain/entities/station.dart';
import '../../domain/entities/station_correction.dart';

typedef StationCorrectionLoader =
    Future<Map<String, StationCorrection>> Function(
      Iterable<String> stationIds,
    );

Future<List<Station>> applyApprovedStationCorrections({
  required List<Station> stations,
  required StationCorrectionLoader loadCorrections,
}) async {
  final stationIds = stations.map((station) => station.id).toSet();
  if (stationIds.isEmpty) return stations;

  late final Map<String, StationCorrection> corrections;
  try {
    corrections = await loadCorrections(stationIds);
  } catch (error) {
    debugPrint(
      'Station correction lookup failed; using original station data: $error',
    );
    return stations;
  }

  if (corrections.isEmpty) return stations;
  return [
    for (final station in stations)
      corrections[station.id]?.applyTo(station) ?? station,
  ];
}
