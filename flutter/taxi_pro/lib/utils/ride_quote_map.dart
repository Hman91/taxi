/// Locked quote fields on admin/owner ride JSON (`Map<String, dynamic>`).

String formatRideDurationSeconds(int seconds) {
  if (seconds < 60) return '< 1 min';
  final totalMin = (seconds / 60).round();
  if (totalMin < 60) return '$totalMin min';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  if (m == 0) return '$h h';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

bool mapHasLockedQuote(Map<String, dynamic> r) {
  final fare = r['quoted_fare_dt'];
  final km = r['quoted_distance_km'];
  return fare is num && km is num;
}

double? mapRideDistanceKm(Map<String, dynamic> r) {
  final q = r['quoted_distance_km'];
  if (q is num) return q.toDouble();
  return null;
}

String mapRidePriceLabel(Map<String, dynamic> r) {
  final b2b = r['b2b_fare'];
  if (b2b is num) return '${b2b.toStringAsFixed(2)} DT';
  final quoted = r['quoted_fare_dt'];
  if (quoted is num) return '${quoted.toStringAsFixed(2)} DT';
  return '-';
}

String mapRideDurationLabel(Map<String, dynamic> r) {
  final secs = r['quoted_duration_seconds'];
  if (secs is num && secs > 0) {
    return formatRideDurationSeconds(secs.round());
  }
  return '-';
}
