import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../utils/airport_place_heuristics.dart';

/// Google Places API (New) — autocomplete + place details.
class GooglePlacesService {
  GooglePlacesService({String? apiKey}) : _key = apiKey ?? googleMapsApiKey;

  final String _key;

  bool get isConfigured => _key.trim().isNotEmpty;

  Future<List<PlaceAutocompleteItem>> autocomplete(
    String input, {
    LatLng? biasCenter,
    double radiusMeters = 85000,
  }) async {
    final q = input.trim();
    if (!isConfigured || q.length < 2) return [];

    final body = <String, dynamic>{
      'input': q,
      'includedRegionCodes': ['tn'],
      if (biasCenter != null)
        'locationBias': {
          'circle': {
            'center': {
              'latitude': biasCenter.latitude,
              'longitude': biasCenter.longitude,
            },
            'radius': radiusMeters,
          },
        },
    };

    final res = await http.post(
      Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _key,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.place,suggestions.placePrediction.text,suggestions.placePrediction.types',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) return [];

    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return [];
    final suggestions = map['suggestions'];
    if (suggestions is! List) return [];

    final out = <PlaceAutocompleteItem>[];
    for (final raw in suggestions) {
      if (raw is! Map<String, dynamic>) continue;
      final pred = raw['placePrediction'];
      if (pred is! Map<String, dynamic>) continue;
      final place = pred['place'];
      final textObj = pred['text'];
      String label = '';
      if (textObj is Map<String, dynamic>) {
        label = (textObj['text'] as String?) ?? '';
      }
      if (place is! String || place.isEmpty) continue;
      var isAirport = false;
      final typesRaw = pred['types'];
      if (typesRaw is List) {
        for (final e in typesRaw) {
          if (e == 'airport') {
            isAirport = true;
            break;
          }
        }
      }
      if (!isAirport && label.isNotEmpty) {
        isAirport = AirportPlaceHeuristics.labelLooksLikeAirport(label);
      }
      out.add(PlaceAutocompleteItem(
        placeResourceName: place,
        label: label,
        isAirport: isAirport,
      ));
    }
    return out;
  }

  Future<PlaceDetailsResult?> placeDetails(String placeResourceName) async {
    if (!isConfigured) return null;
    final name = placeResourceName.trim();
    if (name.isEmpty) return null;

    final path = name.startsWith('places/') ? 'v1/$name' : 'v1/places/$name';
    final uri = Uri.parse('https://places.googleapis.com/$path');

    final res = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': _key,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      },
    );
    if (res.statusCode != 200) return null;

    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    final loc = map['location'];
    if (loc is! Map<String, dynamic>) return null;
    final lat = (loc['latitude'] as num?)?.toDouble();
    final lng = (loc['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final dn = map['displayName'];
    String title = '';
    if (dn is Map<String, dynamic>) {
      title = (dn['text'] as String?) ?? '';
    }
    final formatted = map['formattedAddress'] as String?;

    return PlaceDetailsResult(
      placeResourceName: name,
      title: title.isNotEmpty ? title : (formatted ?? name),
      formattedAddress: formatted,
      position: LatLng(lat, lng),
    );
  }
}

class PlaceAutocompleteItem {
  const PlaceAutocompleteItem({
    required this.placeResourceName,
    required this.label,
    this.isAirport = false,
  });

  final String placeResourceName;
  final String label;
  final bool isAirport;
}

class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.placeResourceName,
    required this.title,
    required this.formattedAddress,
    required this.position,
  });

  final String placeResourceName;
  final String title;
  final String? formattedAddress;
  final LatLng position;
}
