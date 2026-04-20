// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Tunisia';

  @override
  String get loginAs => 'Login as';

  @override
  String get language => 'Language';

  @override
  String get rolePassenger => 'Passenger';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleB2b => 'B2B / Corporate';

  @override
  String get passengerTitle => 'Passenger';

  @override
  String get tabAirport => 'Airport';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Route';

  @override
  String get nightFare50 => '+50% night fare';

  @override
  String get rateYourLastRide => 'Rate your last ride';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get thankYouFeedback => 'Thank you for your feedback!';

  @override
  String get distanceKmOptional => 'Distance km (optional — stub if empty)';

  @override
  String get getEstimate => 'Get estimate';

  @override
  String distanceKm(Object km) {
    return 'Distance: $km km';
  }

  @override
  String fareDt(Object amount) {
    return 'Fare: $amount DT';
  }

  @override
  String get driverTitle => 'Driver';

  @override
  String get driverCode => 'Driver code';

  @override
  String get login => 'Login';

  @override
  String get sessionActive => 'Session active';

  @override
  String get fareAmount => 'Fare (DT)';

  @override
  String get paymentType => 'Payment type';

  @override
  String get cashOrCard => 'Cash / card';

  @override
  String get b2bInvoice => 'B2B invoice';

  @override
  String get completeTripCommission => 'Complete trip (10% commission)';

  @override
  String loggedInAs(String role) {
    return 'Logged in as $role';
  }

  @override
  String get loginFirst => 'Login first';

  @override
  String get invalidFare => 'Invalid fare';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Trip #$id recorded. Commission $commission DT';
  }

  @override
  String get ownerTitle => 'Owner HQ';

  @override
  String get ownerPassword => 'Owner password';

  @override
  String get loginLoadDashboard => 'Login & load dashboard';

  @override
  String commissionLabel(Object amount) {
    return 'Commission (DT): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Trips: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Avg rating: $avg ($count votes)';
  }

  @override
  String get tripsHeading => 'Trips';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · comm $commission';
  }

  @override
  String get operatorTitle => 'Operator / Dispatch';

  @override
  String get operatorCode => 'Operator code';

  @override
  String get loginLoadTrips => 'Login & load trips';

  @override
  String get noTripsLoaded => 'No trips loaded';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Corporate';

  @override
  String get companyCode => 'Company code';

  @override
  String get verifyCompanyCode => 'Verify company code';

  @override
  String get b2bConnectedStub =>
      'Connected to monthly billing (stub). Ride requests and PDF invoice can be wired to the API in a follow-up.';

  @override
  String get roleAppPassenger => 'Passenger (rides & chat)';

  @override
  String get roleAppDriver => 'Driver (app shifts)';

  @override
  String get appPassengerTitle => 'Passenger — rides';

  @override
  String get appDriverTitle => 'Driver — app';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInApp => 'Sign in';

  @override
  String get registerAppAccount => 'Create passenger account';

  @override
  String get registerDriverAccount => 'Create driver account';

  @override
  String get logoutApp => 'Sign out';

  @override
  String get genericCancel => 'Cancel';

  @override
  String get syncPreferredLanguage => 'Sync language to profile';

  @override
  String get profileLanguageSynced => 'Preferred language updated.';

  @override
  String get myRidesHeading => 'My rides';

  @override
  String get ridePickupLabel => 'Pickup';

  @override
  String get rideDestinationLabel => 'Destination';

  @override
  String get requestRideButton => 'Request ride';

  @override
  String get openChatButton => 'Chat';

  @override
  String get chatUnavailable => 'Chat is not open for this ride yet.';

  @override
  String get noRidesYetApp => 'No rides to show.';

  @override
  String get driverPendingRides => 'Ride pool';

  @override
  String get acceptRide => 'Accept';

  @override
  String get rejectRide => 'Release';

  @override
  String get startRide => 'Start trip';

  @override
  String get completeRide => 'Complete';

  @override
  String get cancelRidePassenger => 'Cancel ride';

  @override
  String rideStatusFmt(String status) {
    return 'Status: $status';
  }

  @override
  String get adminOversightHeading => 'Live app oversight';

  @override
  String get adminLoadRidesBtn => 'Load app rides';

  @override
  String get adminLoadDriversBtn => 'Driver locations';

  @override
  String get adminLoadOwnerMetricsBtn => 'Load admin metrics';

  @override
  String get adminRidesHeading => 'App rides';

  @override
  String get adminDriversHeading => 'Drivers';

  @override
  String get adminNoRidesLoaded => 'Tap “Load app rides” to fetch.';

  @override
  String get adminNoDriversData => 'Tap “Driver locations” to fetch.';

  @override
  String adminRideRow(String pickup, String destination) {
    return '$pickup → $destination';
  }

  @override
  String driverLocationRow(String lat, String lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get chatScreenTitle => 'Ride chat';

  @override
  String get messageFieldHint => 'Type a message';

  @override
  String get sendChatMessage => 'Send';

  @override
  String get passengerAirportCardTitle => 'Airport transfers';

  @override
  String get passengerLoginDescription =>
      'Sign in with your email and password, or continue with Google on supported devices.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signedInWithGoogle => 'Signed in with Google';

  @override
  String get signedInWithPassword => 'Signed in';

  @override
  String get fillEmailPassword => 'Enter email and password.';

  @override
  String get registerSuccessMessage => 'Account created. You can sign in now.';

  @override
  String get googleUnavailableOnThisDevice =>
      'Google sign-in is not available on this platform. Use email and password.';

  @override
  String get orDivider => 'or';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get accountDisabledContactAdmin =>
      'Account disabled. Contact an administrator.';
}
