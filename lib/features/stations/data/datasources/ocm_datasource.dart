import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ocm_station_model.dart';

class OcmDataSource {
  OcmDataSource(this._client);

  final http.Client _client;

  String get _apiKey => dotenv.env['OCM_API_KEY'] ?? '';

  Future<List<OcmStationModel>> getNearbyStations({
    required double latitude,
    required double longitude,
    double distanceKm = 50,
    int maxResults = 100,
  }) async {
    final uri = Uri.https(
      'api.openchargemap.io',
      '/v3/poi',
      {
        'output': 'json',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'distance': distanceKm.toString(),
        'distanceunit': 'KM',
        'maxresults': maxResults.toString(),
        'key': _apiKey,
      },
    );

    print('===========================================');
    print('OCM REQUEST');
    print('Latitude : $latitude');
    print('Longitude: $longitude');
    print('Radius   : $distanceKm km');
    print('MaxResult: $maxResults');
    print(uri);
    print('===========================================');

    final response = await _client.get(
      uri,
      headers: const {
        'User-Agent': 'ChargeHub/1.0',
      },
    );

    print('Status Code: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch stations (${response.statusCode})',
      );
    }

    final List<dynamic> json = jsonDecode(response.body);

    print('Stations returned by API: ${json.length}');

    if (json.isNotEmpty) {
      print('First station: ${json.first['AddressInfo']['Title']}');
    }

    print('===========================================');

    return json
        .map(
          (station) => OcmStationModel.fromJson(
        station as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}
