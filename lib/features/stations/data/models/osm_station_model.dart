import 'dart:math';

import '../../domain/entities/station.dart';

class OsmStationModel {
  const OsmStationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.operationalStatus,
    required this.isPublic,
    required this.connectors,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final StationOperationalStatus operationalStatus;
  final bool? isPublic;
  final List<Connector> connectors;

  factory OsmStationModel.fromJson(
      Map<String, dynamic> json, {
        required double userLat,
        required double userLon,
      }) {
    final id = 'osm_${json['type']}_${json['id']}';

    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    final center = json['center'] as Map<String, dynamic>?;

    final latValue = json['lat'] ?? center?['lat'];
    final lonValue = json['lon'] ?? center?['lon'];

    final lat = (latValue as num?)?.toDouble();
    final lon = (lonValue as num?)?.toDouble();

    if (lat == null || lon == null) {
      throw const FormatException(
        'OSM station does not contain valid coordinates',
      );
    }

    return OsmStationModel(
      id: id,
      name: _buildStationName(tags),
      address: _buildAddress(tags),
      latitude: lat,
      longitude: lon,
      distanceKm: _calculateDistance(
        userLat,
        userLon,
        lat,
        lon,
      ),
      operationalStatus: _parseOperationalStatus(tags),
      isPublic: _parseAccess(tags),
      connectors: _parseConnectors(tags),
    );
  }

  Station toEntity() {
    return Station(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      operationalStatus: operationalStatus,
      isPublic: isPublic,
      connectors: connectors,
      source: StationSource.osm,
    );
  }

  static String _buildStationName(
      Map<String, dynamic> tags,
      ) {
    final name = tags['name']?.toString().trim();
    final brand = tags['brand']?.toString().trim();
    final operator = tags['operator']?.toString().trim();
    final reference = tags['ref']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (brand != null && brand.isNotEmpty) {
      return '$brand Charging Station';
    }

    if (operator != null && operator.isNotEmpty) {
      return '$operator Charging Station';
    }

    if (reference != null && reference.isNotEmpty) {
      return 'Charging Station $reference';
    }

    return 'EV Charging Station';
  }

  static String _buildAddress(
      Map<String, dynamic> tags,
      ) {
    final houseNumber =
    tags['addr:housenumber']?.toString().trim();

    final street =
    tags['addr:street']?.toString().trim();

    final city =
    tags['addr:city']?.toString().trim();

    final postcode =
    tags['addr:postcode']?.toString().trim();

    final addressParts = <String>[];

    if (houseNumber != null && houseNumber.isNotEmpty) {
      addressParts.add(houseNumber);
    }

    if (street != null && street.isNotEmpty) {
      addressParts.add(street);
    }

    if (city != null && city.isNotEmpty) {
      addressParts.add(city);
    }

    if (postcode != null && postcode.isNotEmpty) {
      addressParts.add(postcode);
    }

    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    final description =
    tags['description']?.toString().trim();

    if (description != null && description.isNotEmpty) {
      return description;
    }

    return 'Address unavailable';
  }

  static StationOperationalStatus _parseOperationalStatus(
      Map<String, dynamic> tags,
      ) {
    final status =
    tags['operational_status']?.toString().toLowerCase().trim();

    if (status == null || status.isEmpty) {
      return StationOperationalStatus.unknown;
    }

    switch (status) {
      case 'operational':
      case 'open':
      case 'yes':
        return StationOperationalStatus.operational;

      case 'broken':
      case 'closed':
      case 'no':
        return StationOperationalStatus.unavailable;

      default:
        return StationOperationalStatus.unknown;
    }
  }

  static bool? _parseAccess(
      Map<String, dynamic> tags,
      ) {
    final access =
    tags['access']?.toString().toLowerCase().trim();

    if (access == null || access.isEmpty) {
      return null;
    }

    switch (access) {
      case 'yes':
      case 'public':
        return true;

      case 'private':
      case 'customers':
        return false;

      default:
        return null;
    }
  }

  static List<Connector> _parseConnectors(
      Map<String, dynamic> tags,
      ) {
    final connectors = <Connector>[];

    _addConnector(
      connectors,
      tags,
      key: 'socket:type2_combo',
      type: 'CCS2',
      currentType: 'DC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:ccs2',
      type: 'CCS2',
      currentType: 'DC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:ccs',
      type: 'CCS',
      currentType: 'DC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:type2',
      type: 'Type 2',
      currentType: 'AC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:type1',
      type: 'Type 1',
      currentType: 'AC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:chademo',
      type: 'CHAdeMO',
      currentType: 'DC',
    );

    _addConnector(
      connectors,
      tags,
      key: 'socket:schuko',
      type: 'Schuko',
      currentType: 'AC',
    );

    if (connectors.isEmpty) {
      connectors.add(
        const Connector(
          type: 'Unknown',
          currentType: 'Unknown',
          powerKw: null,
          quantity: 1,
        ),
      );
    }

    return connectors;
  }

  static void _addConnector(
      List<Connector> connectors,
      Map<String, dynamic> tags, {
        required String key,
        required String type,
        required String currentType,
      }) {
    final value = tags[key];

    if (value == null) {
      return;
    }

    final quantity =
        int.tryParse(value.toString()) ?? 1;

    final powerKw = _parsePower(
      tags['$key:output'],
    );

    connectors.add(
      Connector(
        type: type,
        currentType: currentType,
        powerKw: powerKw,
        quantity: quantity,
      ),
    );
  }

  static double? _parsePower(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value
        .toString()
        .toLowerCase()
        .replaceAll('kw', '')
        .trim();

    return double.tryParse(text);
  }

  static double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final deltaLat =
        (lat2 - lat1) * pi / 180;

    final deltaLon =
        (lon2 - lon1) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
            cos(lat1Rad) *
                cos(lat2Rad) *
                sin(deltaLon / 2) *
                sin(deltaLon / 2);

    final c = 2 * atan2(
      sqrt(a),
      sqrt(1 - a),
    );

    return earthRadiusKm * c;
  }
}