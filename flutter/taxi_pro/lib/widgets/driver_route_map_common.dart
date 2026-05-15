import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/models.dart';
import '../maps/tunisia_zone_coordinates.dart';

/// Resolves pickup / destination coordinates for map + directions (API or zone centroid).
class RideRouteCoords {
  RideRouteCoords._();

  static LatLng? pickup(Ride r) {
    final la = r.pickupLat;
    final ln = r.pickupLng;
    if (la != null && ln != null) return LatLng(la, ln);
    return TunisiaZoneCoordinates.lookup(r.pickup);
  }

  static LatLng? destination(Ride r) {
    final la = r.destinationLat;
    final ln = r.destinationLng;
    if (la != null && ln != null) return LatLng(la, ln);
    return TunisiaZoneCoordinates.lookup(r.destination);
  }
}
