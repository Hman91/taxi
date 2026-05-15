/// Heuristics for airport vs city POIs (Places labels + catalog zone keys).
abstract final class AirportPlaceHeuristics {
  AirportPlaceHeuristics._();

  static bool labelLooksLikeAirport(String label) {
    final t = label.toLowerCase();
    if (label.contains('مطار')) return true;
    if (t.contains('airport')) return true;
    if (t.contains('aéroport') || t.contains('aeroport')) return true;
    if (t.contains('international airport')) return true;
    return false;
  }

  static bool zoneKeyLooksLikeAirport(String zoneKey) {
    final k = zoneKey.trim();
    if (k.contains('مطار')) return true;
    return labelLooksLikeAirport(k);
  }
}
