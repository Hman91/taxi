import 'app_localizations.dart';

/// Matches [backend.services.pricing] route keys (`"… ➡️ …"`) and DB segment names.
const String airportRouteKeySeparator = '➡️';

/// Display label for a fare segment name as stored by the API (Arabic canonical string).
String localizedPlaceName(AppLocalizations l, String? raw) {
  final s = (raw ?? '').trim();
  switch (s) {
    case 'مطار قرطاج':
      return l.placeCarthageAirport;
    case 'مطار النفيضة':
      return l.placeEnfidhaAirport;
    case 'مطار المنستير':
      return l.placeMonastirAirport;
    case 'وسط سوسة':
      return l.placeSousseCenter;
    case 'الحمامات':
      return l.placeHammamet;
    case 'سوسة':
      return l.placeSousse;
    case 'القنطاوي':
      return l.placePortElKantaoui;
    case 'نابل':
      return l.placeNabeul;
    default:
      return s;
  }
}

String localizedRideRouteRow(AppLocalizations l, String pickup, String destination) {
  return l.adminRideRow(
    localizedPlaceName(l, pickup),
    localizedPlaceName(l, destination),
  );
}

/// Localized "A → B" for a full [routeKey] from `/fares/airport` or quote APIs.
String localizedRouteKeyForDisplay(AppLocalizations l, String routeKey) {
  final parts = routeKey.split(airportRouteKeySeparator);
  if (parts.length != 2) {
    return routeKey;
  }
  return localizedRideRouteRow(l, parts[0].trim(), parts[1].trim());
}
