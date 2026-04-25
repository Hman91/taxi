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
  String get homeWhatIsTitle => 'Was ist Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisia verbindet Sie mit Fahrern für Flughafentransfers und Stadtfahrten. Die Preise sind pro Strecke in der App festgelegt; zwischen 21:00 und 05:00 kann ein Nachtzuschlag gelten. Buchen Sie in der App, verfolgen Sie Ihre Fahrt und nutzen Sie bei Bedarf die Hilfe.';

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
  String get passengerFareFinalEstimate => 'Endgültige Schätzung für die Fahrt';

  @override
  String get passengerPayCash => 'Barzahlung';

  @override
  String get passengerPayCardTpe => 'Karte (TPE)';

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
  String get operatorEntryGateLabel => 'Eingangstor:';

  @override
  String get operatorEmployeePasswordLabel => 'Mitarbeiterpasswort:';

  @override
  String get operatorWelcomeOperatingRoom => 'Willkommen im Betriebsraum.';

  @override
  String get operatorTabTodaysArrivals => 'Heutige Ankünfte';

  @override
  String get operatorTabLiveOrders => 'Live-Aufträge';

  @override
  String get operatorTabDriverManagement => 'Fahrerverwaltung';

  @override
  String get operatorTabTripHistory => 'Fahrtenverlauf';

  @override
  String get operatorArrivalsDemoHeading =>
      'Heutige Ankünfte — Tunesien (Demodaten)';

  @override
  String get operatorColFlightNumber => 'Flugnummer';

  @override
  String get operatorColDepartureAirport => 'Abflughafen';

  @override
  String get operatorColTakeoffTime => 'Abflugzeit';

  @override
  String get operatorColExpectedArrival => 'Erwartete Ankunft (heute)';

  @override
  String get operatorColArrivalAirportTn => 'Ankunftsflughafen (Tunesien)';

  @override
  String get operatorChooseDriverTopUp => 'Fahrer zum Aufladen wählen:';

  @override
  String get operatorAmountReceivedDt => 'Erhaltener Betrag (DT):';

  @override
  String get operatorRechargeBalance => 'Guthaben aufladen';

  @override
  String get operatorCorporateBookingsSection => 'Firmenbuchungen (B2B)';

  @override
  String get operatorRoleAdminHq => 'Admin-Zentrale';

  @override
  String get operatorNoFlightArrivals => 'Keine Ankunftszeilen geladen.';

  @override
  String get operatorUserAccountsHeading => 'App-Benutzerkonten';

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
  String get placeSousseCenter => 'Stadtzentrum Sousse';

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
  String get driverRideRequestBannerTitle => 'New ride request!';

  @override
  String get driverOfferFromLabel => 'From';

  @override
  String get driverOfferToLabel => 'To';

  @override
  String get driverRejectOfferButton => 'Reject';

  @override
  String driverOfferFareChip(String amount) {
    return '$amount DT';
  }

  @override
  String driverOfferDistanceChip(String distance) {
    return '$distance km';
  }

  @override
  String driverOfferTimeChip(String minutes) {
    return '$minutes min';
  }

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
  String get b2bFareAdminPercentSuffix => '• 5% Admin';

  @override
  String adminB2bBookingRowSubtitle(String guest, String room, String fare) {
    return '$guest • $room • $fare DT';
  }

  @override
  String get ownerAppBarTitle => 'Inhaber-Zentrale';

  @override
  String get ownerPasswordCeoLabel => 'Eigentümer-(CEO)-Passwort:';

  @override
  String get ownerWelcomeHq => 'Willkommen in der Inhaber-Zentrale.';

  @override
  String get ownerTabTreasury => 'Kasse und Gewinne';

  @override
  String get ownerTabSettings => 'Einstellungen';

  @override
  String get ownerTabHostelB2b => 'Hotelkonten (B2B)';

  @override
  String get ownerSettingsCommissionLabel => 'Abgezogener Provisionssatz (%):';

  @override
  String get ownerSettingsCommissionHint =>
      'Nur Anzeige — mit Fahrerkonten für Live-Sätze verknüpfen.';

  @override
  String get ownerSettingsRouteFaresHeading => 'Basispreise pro Route (DT)';

  @override
  String get ownerSaveRouteFare => 'Speichern';

  @override
  String ownerProfitChip(String amount) {
    return 'Gewinn: $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Fahrten: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Fahrtenarchiv';

  @override
  String get ownerAdminOversightHeading => 'Admin-Überwachung';

  @override
  String ownerCommissionChip(String amount) {
    return 'Provision: $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'Zentralleitstelle';

  @override
  String get operatorTabDispatch => 'Disposition';

  @override
  String get operatorTabDrivers => 'Fahrer';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Fahrtenarchiv';

  @override
  String get operatorDispatchCenterHeading => 'Disposition & Überwachung';

  @override
  String get operatorDispatchPendingBlurb =>
      'Es gibt offene Anfragen, die zugewiesen werden müssen.';

  @override
  String get operatorDispatchIdleBlurb =>
      'System verbunden. Keine offenen Buchungen.';

  @override
  String operatorChipPending(int count) {
    return 'Ausstehend: $count';
  }

  @override
  String operatorChipAccepted(int count) {
    return 'Angenommen: $count';
  }

  @override
  String operatorChipOngoing(int count) {
    return 'Laufend: $count';
  }

  @override
  String operatorChipCompleted(int count) {
    return 'Abgeschlossen: $count';
  }

  @override
  String operatorRideSubtitleLine(
      String status, String driver, String created) {
    return '$status$driver$created';
  }

  @override
  String operatorDriversOnlineCount(int count) {
    return 'Fahrer online: $count';
  }

  @override
  String get operatorPhoneLabel => 'Telefon';

  @override
  String get operatorDriverNameLabel => 'Fahrername';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields =>
      'Telefon, Fahrername und PIN eingeben.';

  @override
  String get operatorCreateDriverAccount => 'Fahrerkonto erstellen';

  @override
  String get operatorRefreshCorporateBookings =>
      'Firmenbuchungen aktualisieren';

  @override
  String get operatorTripVaultHeading => 'Fahrtenarchiv';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Fahrten: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Umsatz: $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Wallet-Guthaben';

  @override
  String get operatorOwnerCommissionLabel => 'Eigentümer-Provision %';

  @override
  String get operatorB2bCommissionLabel => 'B2B-Provision %';

  @override
  String get operatorAutoDeductEnabled => 'Automatischer Abzug aktiv';

  @override
  String get operatorCarModelLabel => 'Automodell';

  @override
  String get operatorCarColorLabel => 'Autofarbe';

  @override
  String get operatorPickFromGallery => 'Bild aus Galerie wählen';

  @override
  String get operatorRemovePickedImage => 'Gewähltes Bild entfernen';

  @override
  String get operatorPhotoUrlOptional => 'Foto-URL (optional)';

  @override
  String get operatorCancel => 'Abbrechen';

  @override
  String get operatorSave => 'Speichern';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Wallet: $wallet DT | Eigentümer %: $owner | B2B %: $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | Farbe: $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nAuto: $model';
  }

  @override
  String get statusLinePrefix => 'Status: ';

  @override
  String get driverLabelPrefix => ' | Fahrer: ';

  @override
  String get createdAtLinePrefix => '\nUm: ';

  @override
  String walletWithAmount(String amount) {
    return 'Wallet: $amount DT';
  }

  @override
  String get driverWalletDepletedTitle => 'Wallet leer';

  @override
  String driverWalletDepletedBody(int amount) {
    return 'Zahlen Sie $amount DT an den Eigentümer (über den Operator) zum Aufladen.';
  }

  @override
  String get ownerDriverPinWalletsHeading => 'Fahrer-Wallets';

  @override
  String get ownerDriverPinWalletsEmpty => 'Keine PIN-Fahrerkonten geladen.';
}
