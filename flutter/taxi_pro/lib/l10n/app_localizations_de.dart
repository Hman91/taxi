// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Tunesien';

  @override
  String get homeWhatIsTitle => 'What is Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisia connects you with drivers for airport transfers and city rides. Prices are fixed per route in the app; a night surcharge may apply between 9 PM and 5 AM. Book in the app, track your ride, and use in-app help when needed.';

  @override
  String get loginAs => 'Anmelden als';

  @override
  String get language => 'Sprache';

  @override
  String get rolePassenger => 'Fahrgast';

  @override
  String get roleDriver => 'Fahrer';

  @override
  String get roleOwner => 'Inhaber';

  @override
  String get roleOperator => 'Disponent';

  @override
  String get roleB2b => 'B2B / Firma';

  @override
  String get passengerTitle => 'Fahrgast';

  @override
  String get tabAirport => 'Flughafen';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Route';

  @override
  String get nightFare50 => '+50 % Nachtzuschlag';

  @override
  String get rateYourLastRide => 'Letzte Fahrt bewerten';

  @override
  String get submitRating => 'Bewertung senden';

  @override
  String get thankYouFeedback => 'Danke für Ihr Feedback!';

  @override
  String get distanceKmOptional =>
      'Entfernung in km (optional — Schätzung wenn leer)';

  @override
  String get getEstimate => 'Schätzung anfordern';

  @override
  String distanceKm(Object km) {
    return 'Entfernung: $km km';
  }

  @override
  String fareDt(Object amount) {
    return 'Fahrpreis: $amount DT';
  }

  @override
  String get driverTitle => 'Fahrer';

  @override
  String get driverCode => 'Fahrercode';

  @override
  String get login => 'Anmelden';

  @override
  String get sessionActive => 'Sitzung aktiv';

  @override
  String get fareAmount => 'Fahrpreis (DT)';

  @override
  String get paymentType => 'Zahlungsart';

  @override
  String get passengerFareFinalEstimate => 'Final estimate for the ride';

  @override
  String get passengerPayCash => 'Cash';

  @override
  String get passengerPayCardTpe => 'Card (TPE)';

  @override
  String get cashOrCard => 'Bar / Karte';

  @override
  String get b2bInvoice => 'Firmenrechnung';

  @override
  String get completeTripCommission => 'Fahrt abschließen (10 % Provision)';

  @override
  String loggedInAs(String role) {
    return 'Angemeldet als $role';
  }

  @override
  String get loginFirst => 'Bitte zuerst anmelden';

  @override
  String get invalidFare => 'Ungültiger Fahrpreis';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Fahrt Nr. $id erfasst. Provision $commission DT';
  }

  @override
  String get ownerTitle => 'Inhaber-Zentrale';

  @override
  String get ownerPassword => 'Inhaber-Passwort';

  @override
  String get loginLoadDashboard => 'Anmelden & Dashboard laden';

  @override
  String commissionLabel(Object amount) {
    return 'Provision (DT): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Fahrten: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Ø Bewertung: $avg ($count Stimmen)';
  }

  @override
  String get tripsHeading => 'Fahrten';

  @override
  String get noTripsYet => 'Noch keine Fahrten';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · Prov. $commission';
  }

  @override
  String get operatorTitle => 'Disponent';

  @override
  String get operatorCode => 'Disponent-Code';

  @override
  String get loginLoadTrips => 'Anmelden & Fahrten laden';

  @override
  String get noTripsLoaded => 'Keine Fahrten geladen';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Unternehmen';

  @override
  String get companyCode => 'Firmencode';

  @override
  String get verifyCompanyCode => 'Firmencode prüfen';

  @override
  String get b2bConnectedStub =>
      'Mit Monatsabrechnung verbunden (Demo). Fahrtanfragen und PDF-Rechnung können später an die API angebunden werden.';

  @override
  String get roleAppPassenger => 'Fahrgast (Fahrten & Chat)';

  @override
  String get roleAppDriver => 'Fahrer (App)';

  @override
  String get appPassengerTitle => 'Fahrgast — Fahrten';

  @override
  String get appDriverTitle => 'Fahrer — App';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get signInApp => 'Anmelden';

  @override
  String get registerAppAccount => 'Fahrgastkonto erstellen';

  @override
  String get registerDriverAccount => 'Fahrerkonto erstellen';

  @override
  String get logoutApp => 'Abmelden';

  @override
  String get genericCancel => 'Abbrechen';

  @override
  String get syncPreferredLanguage => 'Sprache im Profil speichern';

  @override
  String get profileLanguageSynced => 'Bevorzugte Sprache aktualisiert.';

  @override
  String get myRidesHeading => 'Meine Fahrten';

  @override
  String get ridePickupLabel => 'Abholung';

  @override
  String get rideDestinationLabel => 'Ziel';

  @override
  String get requestRideButton => 'Fahrt anfragen';

  @override
  String get openChatButton => 'Chat';

  @override
  String get chatUnavailable => 'Chat für diese Fahrt noch nicht verfügbar.';

  @override
  String get noRidesYetApp => 'Keine Fahrten.';

  @override
  String get driverPendingRides => 'Fahrtenpool';

  @override
  String get acceptRide => 'Annehmen';

  @override
  String get rejectRide => 'Freigeben';

  @override
  String get startRide => 'Starten';

  @override
  String get completeRide => 'Beenden';

  @override
  String get cancelRidePassenger => 'Fahrt stornieren';

  @override
  String rideStatusFmt(String status) {
    return 'Status: $status';
  }

  @override
  String get adminOversightHeading => 'Live-Überblick';

  @override
  String get adminLoadRidesBtn => 'App-Fahrten laden';

  @override
  String get adminLoadDriversBtn => 'Fahrerstandorte';

  @override
  String get adminLoadOwnerMetricsBtn => 'Admin-Kennzahlen';

  @override
  String get adminRidesHeading => 'App-Fahrten';

  @override
  String get adminDriversHeading => 'Fahrer';

  @override
  String get adminNoRidesLoaded => 'Tippen Sie auf „App-Fahrten laden“.';

  @override
  String get adminNoDriversData => 'Tippen Sie auf „Fahrerstandorte“.';

  @override
  String adminRideRow(String pickup, String destination) {
    return '$pickup → $destination';
  }

  @override
  String get placeCarthageAirport => 'Carthage Airport (Tunis)';

  @override
  String get placeEnfidhaAirport => 'Enfidha–Hammamet Airport';

  @override
  String get placeMonastirAirport => 'Monastir Airport';

  @override
  String get placeSousseCenter => 'Sousse city center';

  @override
  String get placeHammamet => 'Hammamet';

  @override
  String get placeSousse => 'Sousse';

  @override
  String get placePortElKantaoui => 'Port El Kantaoui';

  @override
  String get placeNabeul => 'Nabeul';

  @override
  String driverLocationRow(String lat, String lng) {
    return 'Breite $lat, Länge $lng';
  }

  @override
  String get chatScreenTitle => 'Fahrt-Chat';

  @override
  String get messageFieldHint => 'Nachricht eingeben';

  @override
  String get sendChatMessage => 'Senden';

  @override
  String get accountDisabledContactAdmin =>
      'Konto deaktiviert. Wenden Sie sich an einen Administrator.';

  @override
  String get signedInWithGoogle => 'Mit Google angemeldet';

  @override
  String get passengerGoogleLoginRequired =>
      'Für Fahrgäste ist die Anmeldung mit Google erforderlich.';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get passengerDispatchPanelTitle => 'Premium-Dispositionspanel';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Aktive Fahrten: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Fahrten gesamt: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Buchung';

  @override
  String get passengerLocationCurrent => 'Ihr aktueller Standort';

  @override
  String get passengerLocationDetecting => 'Standort wird ermittelt…';

  @override
  String get passengerLocationUnavailable => 'Standort nicht verfügbar';

  @override
  String get passengerRefreshLocationTooltip => 'Standort aktualisieren';

  @override
  String passengerDriverLine(String name) {
    return 'Fahrer: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Telefon: $phone';
  }

  @override
  String get rideStatusPending => 'Ausstehend';

  @override
  String get rideStatusAccepted => 'Angenommen';

  @override
  String get rideStatusOngoing => 'Läuft';

  @override
  String get rideStatusCompleted => 'Abgeschlossen';

  @override
  String get rideStatusCancelled => 'Storniert';

  @override
  String get rideStatusActive => 'Aktiv';

  @override
  String get passengerLocationServiceDisabled =>
      'Standortdienst ist deaktiviert.';

  @override
  String get passengerLocationPermissionDenied =>
      'Standortberechtigung verweigert.';

  @override
  String get passengerNoNotificationsYet => 'Noch keine Benachrichtigungen.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Fahrtdetails';

  @override
  String passengerRideNumberLine(int id) {
    return 'Fahrt Nr. $id';
  }

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationRideUpdateTitle => 'Ride update';

  @override
  String notificationRideUpdatedBody(int id) {
    return 'Ride #$id updated.';
  }

  @override
  String get errorGoogleSignInMissingToken =>
      'Google sign-in failed: missing Google token.';

  @override
  String get driverNameFallback => 'Driver';

  @override
  String get notificationDriverAcceptedTitle => 'Driver accepted';

  @override
  String notificationDriverAcceptedBody(String driver, String phoneSuffix) {
    return '$driver$phoneSuffix accepted your request.';
  }

  @override
  String notificationDriverAcceptedSnack(String driver, String phoneSuffix) {
    return 'Driver accepted: $driver$phoneSuffix';
  }

  @override
  String get passengerDriverNearPickupSnack =>
      'Driver is now near your pickup point.';

  @override
  String get notificationDriverNearPickupTitle => 'Driver near pickup';

  @override
  String notificationDriverNearPickupBody(String pickup) {
    return 'Your driver is near pickup in $pickup.';
  }

  @override
  String get notificationRequestSentTitle => 'Request sent';

  @override
  String get notificationRequestSentBody =>
      'We sent your ride request to nearby drivers.';

  @override
  String requestSentSnackLine(String farePart, String promoPart) {
    return 'Request sent. $farePart$promoPart';
  }

  @override
  String get promoCodeOptionalLabel => 'Promo code';

  @override
  String get driverNotificationNewNearbyTitle => 'New nearby ride';

  @override
  String get driverNotificationNewNearbyBodyDefault =>
      'A nearby passenger requested a ride.';

  @override
  String get driverNotificationTakenTitle => 'Request already accepted';

  @override
  String get driverNotificationTakenBodyDefault =>
      'Another driver accepted this request.';

  @override
  String get driverNotificationCancelledTitle => 'Ride cancelled';

  @override
  String get driverNotificationCancelledBodyDefault =>
      'Passenger cancelled this ride request.';

  @override
  String get driverNotificationRequestClosedTitle => 'Request closed';

  @override
  String get driverNotificationRequestClosedBodyOther =>
      'This request was accepted by another driver or cancelled.';

  @override
  String get driverNotificationRequestClosedBodyTaken =>
      'This request was accepted by another driver.';

  @override
  String get driverNotificationNewRideTitle => 'New ride request';

  @override
  String get driverNotificationNewRideBodyDefault =>
      'A nearby passenger sent a new request.';

  @override
  String get snackDriverNewNearbyRide => 'New nearby ride request received.';

  @override
  String get snackDriverRideTakenOther => 'Ride accepted by another driver.';

  @override
  String get snackDriverPassengerCancelled =>
      'Passenger cancelled this request.';

  @override
  String get snackDriverChatAfterAcceptance =>
      'Chat will open after ride acceptance';

  @override
  String get driverMyVehicleTitle => 'My vehicle';

  @override
  String driverVehicleSummaryLine(String model, String color) {
    return 'Car: $model | Color: $color';
  }

  @override
  String get driverVehicleIdentityTitle => 'Vehicle identity';

  @override
  String driverOpenRequestsChip(int count) {
    return 'Open requests: $count';
  }

  @override
  String driverUnreadAlertsChip(int count) {
    return 'Unread alerts: $count';
  }

  @override
  String get b2bAppBarTitle => 'Taxi Pro Corporate';

  @override
  String get b2bPortalHeading => 'Corporate & hotel portal';

  @override
  String get b2bConnectedWorkflowSubtitle =>
      'Connected to monthly billing workflow';

  @override
  String get b2bBookOnAccountHeading => 'Book on company account';

  @override
  String get b2bMonthlyUsageTitle => 'Current month usage (stub)';

  @override
  String b2bMonthlyAmountDue(String amount) {
    return 'Amount due (DT): $amount';
  }

  @override
  String b2bBookingSuccessMessage(
      String action, Object id, String guest, String route) {
    return '$action #$id • $guest • $route';
  }

  @override
  String get b2bFareAdminPercentSuffix => '• 5% admin';

  @override
  String adminB2bBookingRowSubtitle(String guest, String room, String fare) {
    return '$guest • $room • $fare DT';
  }

  @override
  String get ownerAppBarTitle => 'Owner HQ';

  @override
  String ownerProfitChip(String amount) {
    return 'Profit: $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Trips: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Trip vault';

  @override
  String get ownerAdminOversightHeading => 'Admin oversight';

  @override
  String ownerCommissionChip(String amount) {
    return 'Commission: $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'HQ command center';

  @override
  String get operatorTabDispatch => 'Dispatch';

  @override
  String get operatorTabDrivers => 'Drivers';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Trip vault';

  @override
  String get operatorDispatchCenterHeading => 'Dispatch & monitoring';

  @override
  String get operatorDispatchPendingBlurb =>
      'There are pending requests that need assigning.';

  @override
  String get operatorDispatchIdleBlurb =>
      'System is connected. No pending bookings.';

  @override
  String operatorChipPending(int count) {
    return 'Pending: $count';
  }

  @override
  String operatorChipAccepted(int count) {
    return 'Accepted: $count';
  }

  @override
  String operatorChipOngoing(int count) {
    return 'Ongoing: $count';
  }

  @override
  String operatorChipCompleted(int count) {
    return 'Completed: $count';
  }

  @override
  String operatorRideSubtitleLine(
      String status, String driver, String created) {
    return '$status$driver$created';
  }

  @override
  String operatorDriversOnlineCount(int count) {
    return 'Drivers online: $count';
  }

  @override
  String get operatorPhoneLabel => 'Phone';

  @override
  String get operatorDriverNameLabel => 'Driver name';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields => 'Enter phone, driver name, and PIN.';

  @override
  String get operatorCreateDriverAccount => 'Create driver account';

  @override
  String get operatorRefreshCorporateBookings => 'Refresh corporate bookings';

  @override
  String get operatorTripVaultHeading => 'Trip vault';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Trips: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Revenue: $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Wallet balance';

  @override
  String get operatorOwnerCommissionLabel => 'Owner commission %';

  @override
  String get operatorB2bCommissionLabel => 'B2B commission %';

  @override
  String get operatorAutoDeductEnabled => 'Auto deduct enabled';

  @override
  String get operatorCarModelLabel => 'Car model';

  @override
  String get operatorCarColorLabel => 'Car color';

  @override
  String get operatorPickFromGallery => 'Pick image from gallery';

  @override
  String get operatorRemovePickedImage => 'Remove picked image';

  @override
  String get operatorPhotoUrlOptional => 'Photo URL (optional)';

  @override
  String get operatorCancel => 'Cancel';

  @override
  String get operatorSave => 'Save';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Wallet: $wallet DT | Owner %: $owner | B2B %: $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | Color: $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nCar: $model';
  }

  @override
  String get statusLinePrefix => 'Status: ';

  @override
  String get driverLabelPrefix => ' | Driver: ';

  @override
  String get createdAtLinePrefix => '\nAt: ';

  @override
  String walletWithAmount(String amount) {
    return 'Wallet: $amount DT';
  }
}
