import '../api/models.dart';
import 'app_localizations.dart';
import 'place_localization.dart';

/// Matches the reservation sheet: short pickup label (stored display or zone key).
String ridePickupTitle(Ride r, AppLocalizations l) {
  final n = (r.pickupDisplayName ?? '').trim();
  if (n.isNotEmpty) return n;
  return localizedPlaceName(l, r.pickup);
}

/// Reverse-geocoded / formatted pickup line under the title (when stored).
String? ridePickupAddressLine(Ride r, AppLocalizations _) {
  final t = (r.pickupAddress ?? '').trim();
  return t.isEmpty ? null : t;
}

/// Place or catalog destination label (same as reservation sheet title row).
String rideDestinationTitle(Ride r, AppLocalizations l) {
  final n = (r.destinationDisplayName ?? '').trim();
  if (n.isNotEmpty) return n;
  return localizedPlaceName(l, r.destination);
}

/// Formatted destination under the title (when stored).
String? rideDestinationAddressLine(Ride r, AppLocalizations _) {
  final t = (r.destinationAddress ?? '').trim();
  return t.isEmpty ? null : t;
}

String? rideEndpointCoordsLine(Ride r) {
  final parts = <String>[];
  if (r.pickupLat != null && r.pickupLng != null) {
    parts.add(
      '${r.pickupLat!.toStringAsFixed(5)}, ${r.pickupLng!.toStringAsFixed(5)}',
    );
  }
  if (r.destinationLat != null && r.destinationLng != null) {
    parts.add(
      '${r.destinationLat!.toStringAsFixed(5)}, ${r.destinationLng!.toStringAsFixed(5)}',
    );
  }
  if (parts.isEmpty) return null;
  return parts.join(' → ');
}
