import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class GoogleGeocodingService {
  GoogleGeocodingService({String? apiKey}) : _key = apiKey ?? googleMapsApiKey;

  final String _key;

  bool get isConfigured => _key.trim().isNotEmpty;

  Future<String?> reverseFormattedAddress(LatLng p, {String? language}) async {
    if (!isConfigured) return null;
    final raw = language?.trim();
    final langCode =
        (raw == null || raw.isEmpty) ? 'fr' : raw;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${p.latitude},${p.longitude}',
      'key': _key,
      'language': langCode,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    final results = map['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map<String, dynamic>) return null;
    final addr = first['formatted_address'];
    if (addr is String && addr.trim().isNotEmpty) return addr.trim();
    return null;
  }
}
