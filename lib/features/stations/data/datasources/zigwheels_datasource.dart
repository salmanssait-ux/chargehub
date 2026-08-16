import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/zigwheels_station_model.dart';

class ZigWheelsDataSource {
  const ZigWheelsDataSource();

  Future<List<ZigWheelsStationModel>> getStations() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/mumbai_chargers.json',
    );

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException(
        'ZigWheels dataset must contain a JSON array.',
      );
    }

    final stations = <ZigWheelsStationModel>[];

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final latitude = item['latitude'];
      final longitude = item['longitude'];

      if (latitude is! num || longitude is! num) {
        continue;
      }

      try {
        stations.add(
          ZigWheelsStationModel.fromJson(item),
        );
      } catch (_) {
        // Skip malformed records.
      }
    }

    return stations;
  }
}