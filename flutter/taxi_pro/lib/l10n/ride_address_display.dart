import '../api/models.dart';
import 'app_localizations.dart';
import 'place_localization.dart';

/// Full formatted address line shown on cards (Google reverse-geocode / Places).
String ridePickupPrimaryLine(Ride r, AppLocalizations l) {
  final addr = (r.pickupAddress ?? '').trim();
  if (addr.isNotEmpty) return addr;
  final n = (r.pickupDisplayName ?? '').trim();
  if (n.isNotEmpty) return n;
  return localizedPlaceName(l, r.pickup);
}

String rideDestinationPrimaryLine(Ride r, AppLocalizations l) {
  final addr = (r.destinationAddress ?? '').trim();
  if (addr.isNotEmpty) return addr;
  final n = (r.destinationDisplayName ?? '').trim();
  if (n.isNotEmpty) return n;
  return localizedPlaceName(l, r.destination);
}

/// Catalog zone label when it differs from [ridePickupPrimaryLine].
String? ridePickupZoneSubtitle(Ride r, AppLocalizations l) {
  final primary = ridePickupPrimaryLine(r, l).trim();
  final zone = localizedPlaceName(l, r.pickup).trim();
  if (zone.isEmpty || zone == primary) return null;
  return zone;
}

String? rideDestinationZoneSubtitle(Ride r, AppLocalizations l) {
  final primary = rideDestinationPrimaryLine(r, l).trim();
  final zone = localizedPlaceName(l, r.destination).trim();
  if (zone.isEmpty || zone == primary) return null;
  return zone;
}

String ridePickupTitle(Ride r, AppLocalizations l) => ridePickupPrimaryLine(r, l);

String? ridePickupAddressLine(Ride r, AppLocalizations l) =>
    ridePickupZoneSubtitle(r, l);

String rideDestinationTitle(Ride r, AppLocalizations l) =>
    rideDestinationPrimaryLine(r, l);

String? rideDestinationAddressLine(Ride r, AppLocalizations l) =>
    rideDestinationZoneSubtitle(r, l);

String rideRouteSummaryLine(Ride r, AppLocalizations l) =>
    '${ridePickupPrimaryLine(r, l)} → ${rideDestinationPrimaryLine(r, l)}';

String mapRidePickupPrimaryLine(Map<String, dynamic> r, AppLocalizations l) {
  final addr = (r['pickup_address'] ?? '').toString().trim();
  if (addr.isNotEmpty) return addr;
  final dn = (r['pickup_display_name'] ?? '').toString().trim();
  if (dn.isNotEmpty) return dn;
  return localizedPlaceName(l, (r['pickup'] ?? '').toString());
}

String mapRideDestinationPrimaryLine(Map<String, dynamic> r, AppLocalizations l) {
  final addr = (r['destination_address'] ?? '').toString().trim();
  if (addr.isNotEmpty) return addr;
  final dn = (r['destination_display_name'] ?? '').toString().trim();
  if (dn.isNotEmpty) return dn;
  return localizedPlaceName(l, (r['destination'] ?? '').toString());
}

String mapRideRouteSummaryLine(Map<String, dynamic> r, AppLocalizations l) =>
    '${mapRidePickupPrimaryLine(r, l)} → ${mapRideDestinationPrimaryLine(r, l)}';

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
