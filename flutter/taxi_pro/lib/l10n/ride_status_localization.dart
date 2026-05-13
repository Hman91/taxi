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
    case 'searching':
      return 'Searching';
    case 'reserved':
      return 'Driver Reserved';
    case 'upcoming':
      return 'Upcoming Ride';
    case 'in_progress':
      return l.rideStatusOngoing;
    default:
      return raw?.trim().isNotEmpty == true ? raw!.trim() : s;
  }
}
