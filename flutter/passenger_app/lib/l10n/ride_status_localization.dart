import 'app_localizations.dart';

/// Maps API/logical ride status codes to localized labels.
String localizedRideStatusLabel(AppLocalizations l, String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  switch (s) {
    case 'pending':
      return l.rideStatusPending;
    case 'accepted':
      return l.rideStatusAccepted;
    case 'ongoing':
      return l.rideStatusOngoing;
    case 'completed':
      return l.rideStatusCompleted;
    case 'cancelled':
      return l.rideStatusCancelled;
    case 'active':
      return l.rideStatusActive;
    default:
      return raw?.trim().isNotEmpty == true ? raw!.trim() : s;
  }
}
