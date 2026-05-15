import '../api/models.dart';

/// Ride has a distance/fare snapshot saved at booking (Google route + GPS fare).
bool rideHasLockedQuote(Ride r) =>
    r.quotedFareDt != null && r.quotedDistanceKm != null;

double? rideLockedDistanceKm(Ride r) => r.quotedDistanceKm;

double? rideLockedFareDt(Ride r) {
  if (rideHasLockedQuote(r) && r.quotedFareDt != null) return r.quotedFareDt;
  return r.b2bFare ?? r.quotedFareDt;
}

int? rideLockedDurationSeconds(Ride r) {
  final s = r.quotedDurationSeconds;
  if (s == null || s <= 0) return null;
  return s;
}

String formatRideDurationSeconds(int seconds) {
  if (seconds < 60) return '< 1 min';
  final totalMin = (seconds / 60).round();
  if (totalMin < 60) return '$totalMin min';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  if (m == 0) return '$h h';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

String? rideLockedDurationLabel(Ride r) {
  final s = rideLockedDurationSeconds(r);
  if (s == null) return null;
  return formatRideDurationSeconds(s);
}
