import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Canonical zone → coordinates for airport routes and ride map pins.
/// Keys match backend `pickup` / `destination` strings (trimmed).
abstract final class TunisiaZoneCoordinates {
  TunisiaZoneCoordinates._();

  /// Default camera when nothing is resolved (Tunis).
  static const LatLng tunisOverview = LatLng(36.8065, 10.1815);

  /// All catalog keys (for nearest-zone heuristics on the map).
  static Iterable<String> get registeredZoneKeys => _zones.keys;

  static const Map<String, LatLng> _zones = {
    'مطار قرطاج': LatLng(36.8508, 10.2272),
    'مطار النفيضة': LatLng(36.0758, 10.4386),
    'مطار المنستير': LatLng(35.7581, 10.7547),
    'وسط سوسة': LatLng(35.8256, 10.63699),
    'الحمامات': LatLng(36.4000, 10.6167),
    'نابل': LatLng(36.4561, 10.7376),
    'القنطاوي': LatLng(35.8920, 10.5950),
    'Sidi Bou Saïd': LatLng(36.8710, 10.3470),
    'La Marsa': LatLng(36.8780, 10.3240),
    'Gammarth': LatLng(36.9170, 10.2870),
    'Carthage': LatLng(36.8520, 10.3230),
    'Musée du Bardo': LatLng(36.8100, 10.1400),
    'Médina de Tunis': LatLng(36.8000, 10.1700),
    'Byrsa Hill': LatLng(36.8527, 10.3295),
    'Lac de Tunis': LatLng(36.8400, 10.2400),
    'Geant': LatLng(36.8420, 10.2860),
    'Azur city': LatLng(36.7410, 10.2150),
    'tunisia mall': LatLng(36.8430, 10.2810),
    'Nabeul': LatLng(36.4510, 10.7360),
    'Hammamet': LatLng(36.4000, 10.6160),
    'Yasmine Hammamet': LatLng(36.3650, 10.5360),
    'Friguia Park': LatLng(36.1240, 10.4410),
    'Hergla park': LatLng(36.0270, 10.5090),
    'mall of sousse': LatLng(35.8290, 10.6350),
    'Skanes': LatLng(35.7650, 10.8100),
    'Marina de Monastir': LatLng(35.7770, 10.8260),
    'mahdia': LatLng(35.5050, 11.0630),
    'Skifa el Kahla': LatLng(35.5057, 11.0620),
    'Borj el Kebir': LatLng(35.5030, 11.0610),
  };

  static LatLng? lookup(String? zoneName) {
    final k = (zoneName ?? '').trim();
    if (k.isEmpty) return null;
    return _zones[k];
  }

  static LatLng lookupOrOverview(String? zoneName) =>
      lookup(zoneName) ?? tunisOverview;
}
