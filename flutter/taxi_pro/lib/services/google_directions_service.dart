import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Full driving route from Google Directions API (polyline + **real** distance & duration).
class DirectionsRouteResult {
  const DirectionsRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;

  double get distanceKm => distanceMeters / 1000.0;
}

/// Driving directions (Maps Directions API).
class GoogleDirectionsService {
  GoogleDirectionsService({String? apiKey}) : _key = apiKey ?? googleMapsApiKey;

  final String _key;

  bool get isConfigured => _key.trim().isNotEmpty;

  /// Decoded polyline + summed leg distance/duration (matches the drawn route).
  Future<DirectionsRouteResult?> fetchRoute(
      LatLng origin, LatLng destination) async {
    if (!isConfigured) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': _key,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    if ((map['status'] as String?) != 'OK') return null;
    final routes = map['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final first = routes.first;
    if (first is! Map<String, dynamic>) return null;

    final overview = first['overview_polyline'];
    if (overview is! Map<String, dynamic>) return null;
    final encoded = overview['points'] as String?;
    if (encoded == null || encoded.isEmpty) return null;

    var distanceM = 0;
    var durationS = 0;
    final legs = first['legs'];
    if (legs is List) {
      for (final raw in legs) {
        if (raw is! Map<String, dynamic>) continue;
        final d = raw['distance'];
        final t = raw['duration'];
        if (d is Map<String, dynamic>) {
          distanceM += (d['value'] as num?)?.round() ?? 0;
        }
        if (t is Map<String, dynamic>) {
          durationS += (t['value'] as num?)?.round() ?? 0;
        }
      }
    }

    final decoded = PolylinePoints().decodePolyline(encoded);
    final points = decoded
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);
    if (points.length < 2) return null;

    if (distanceM <= 0) {
      distanceM = _haversineMeters(origin, destination);
    }
    if (durationS <= 0) {
      durationS = (distanceM / 1000 * 120).round().clamp(60, 86400);
    }

    return DirectionsRouteResult(
      points: points,
      distanceMeters: distanceM,
      durationSeconds: durationS,
    );
  }

  int _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final la1 = _rad(a.latitude);
    final la2 = _rad(b.latitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(la1) * math.cos(la2) * math.pow(math.sin(dLng / 2), 2);
    return (2 * r * math.asin(math.min(1.0, math.sqrt(h)))).round();
  }

  double _rad(double d) => d * math.pi / 180.0;

  Future<List<LatLng>?> routePoints(LatLng origin, LatLng destination) async {
    final full = await fetchRoute(origin, destination);
    return full?.points;
  }
}
