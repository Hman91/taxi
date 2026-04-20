// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Tunisia';

  @override
  String get loginAs => 'Accedi come';

  @override
  String get language => 'Lingua';

  @override
  String get rolePassenger => 'Passeggero';

  @override
  String get roleDriver => 'Autista';

  @override
  String get roleOwner => 'Proprietario';

  @override
  String get roleOperator => 'Operatore';

  @override
  String get roleB2b => 'B2B / Azienda';

  @override
  String get passengerTitle => 'Passeggero';

  @override
  String get tabAirport => 'Aeroporto';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Percorso';

  @override
  String get nightFare50 => '+50% tariffa notturna';

  @override
  String get rateYourLastRide => 'Valuta l\'ultima corsa';

  @override
  String get submitRating => 'Invia valutazione';

  @override
  String get thankYouFeedback => 'Grazie per il feedback!';

  @override
  String get distanceKmOptional => 'Distanza km (opzionale — stima se vuoto)';

  @override
  String get getEstimate => 'Stima prezzo';

  @override
  String distanceKm(Object km) {
    return 'Distanza: $km km';
  }

  @override
  String fareDt(Object amount) {
    return 'Tariffa: $amount DT';
  }

  @override
  String get driverTitle => 'Autista';

  @override
  String get driverCode => 'Codice autista';

  @override
  String get login => 'Accedi';

  @override
  String get sessionActive => 'Sessione attiva';

  @override
  String get fareAmount => 'Tariffa (DT)';

  @override
  String get paymentType => 'Pagamento';

  @override
  String get cashOrCard => 'Contanti / carta';

  @override
  String get b2bInvoice => 'Fattura aziendale';

  @override
  String get completeTripCommission => 'Completa corsa (commissione 10%)';

  @override
  String loggedInAs(String role) {
    return 'Accesso come $role';
  }

  @override
  String get loginFirst => 'Accedi prima';

  @override
  String get invalidFare => 'Tariffa non valida';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Corsa #$id registrata. Commissione $commission DT';
  }

  @override
  String get ownerTitle => 'Centrale proprietario';

  @override
  String get ownerPassword => 'Password proprietario';

  @override
  String get loginLoadDashboard => 'Accedi e carica dashboard';

  @override
  String commissionLabel(Object amount) {
    return 'Commissione (DT): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Corse: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Media voti: $avg ($count voti)';
  }

  @override
  String get tripsHeading => 'Corse';

  @override
  String get noTripsYet => 'Nessuna corsa';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · comm. $commission';
  }

  @override
  String get operatorTitle => 'Operatore / Dispatch';

  @override
  String get operatorCode => 'Codice operatore';

  @override
  String get loginLoadTrips => 'Accedi e carica corse';

  @override
  String get noTripsLoaded => 'Nessuna corsa caricata';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Aziendale';

  @override
  String get companyCode => 'Codice azienda';

  @override
  String get verifyCompanyCode => 'Verifica codice azienda';

  @override
  String get b2bConnectedStub =>
      'Collegato alla fatturazione mensile (demo). Richieste e fattura PDF potranno essere collegate all\'API in seguito.';

  @override
  String get roleAppPassenger => 'Passeggero (corse e chat)';

  @override
  String get roleAppDriver => 'Autista (app)';

  @override
  String get appPassengerTitle => 'Passeggero — corse';

  @override
  String get appDriverTitle => 'Autista — app';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInApp => 'Accedi';

  @override
  String get registerAppAccount => 'Crea account passeggero';

  @override
  String get registerDriverAccount => 'Crea account autista';

  @override
  String get logoutApp => 'Esci';

  @override
  String get genericCancel => 'Annulla';

  @override
  String get syncPreferredLanguage => 'Sincronizza lingua nel profilo';

  @override
  String get profileLanguageSynced => 'Lingua preferita aggiornata.';

  @override
  String get myRidesHeading => 'Le mie corse';

  @override
  String get ridePickupLabel => 'Partenza';

  @override
  String get rideDestinationLabel => 'Destinazione';

  @override
  String get requestRideButton => 'Richiedi corsa';

  @override
  String get openChatButton => 'Chat';

  @override
  String get chatUnavailable =>
      'La chat non è ancora disponibile per questa corsa.';

  @override
  String get noRidesYetApp => 'Nessuna corsa.';

  @override
  String get driverPendingRides => 'Coda corse';

  @override
  String get acceptRide => 'Accetta';

  @override
  String get rejectRide => 'Rilascia';

  @override
  String get startRide => 'Avvia';

  @override
  String get completeRide => 'Completa';

  @override
  String get cancelRidePassenger => 'Annulla corsa';

  @override
  String rideStatusFmt(String status) {
    return 'Stato: $status';
  }

  @override
  String get adminOversightHeading => 'Monitoraggio live';

  @override
  String get adminLoadRidesBtn => 'Carica corse app';

  @override
  String get adminLoadDriversBtn => 'Posizioni autisti';

  @override
  String get adminLoadOwnerMetricsBtn => 'Metriche admin';

  @override
  String get adminRidesHeading => 'Corse app';

  @override
  String get adminDriversHeading => 'Autisti';

  @override
  String get adminNoRidesLoaded => 'Tocca «Carica corse app».';

  @override
  String get adminNoDriversData => 'Tocca «Posizioni autisti».';

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
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get chatScreenTitle => 'Chat corsa';

  @override
  String get messageFieldHint => 'Scrivi un messaggio';

  @override
  String get sendChatMessage => 'Invia';

  @override
  String get accountDisabledContactAdmin =>
      'Account disabilitato. Contatta un amministratore.';

  @override
  String get signedInWithGoogle => 'Accesso effettuato con Google';

  @override
  String get passengerGoogleLoginRequired =>
      'I passeggeri devono accedere con Google.';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get passengerDispatchPanelTitle => 'Pannello dispatch premium';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Corse attive: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Corse totali: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Prenotazione';

  @override
  String get passengerLocationCurrent => 'La tua posizione attuale';

  @override
  String get passengerLocationDetecting => 'Rilevamento posizione...';

  @override
  String get passengerLocationUnavailable => 'Posizione non disponibile';

  @override
  String get passengerRefreshLocationTooltip => 'Aggiorna posizione';

  @override
  String passengerDriverLine(String name) {
    return 'Autista: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Telefono: $phone';
  }

  @override
  String get rideStatusPending => 'In attesa';

  @override
  String get rideStatusAccepted => 'Accettata';

  @override
  String get rideStatusOngoing => 'In corso';

  @override
  String get rideStatusCompleted => 'Completata';

  @override
  String get rideStatusCancelled => 'Annullata';

  @override
  String get rideStatusActive => 'Attiva';

  @override
  String get passengerLocationServiceDisabled =>
      'Servizio di posizione disattivato.';

  @override
  String get passengerLocationPermissionDenied =>
      'Autorizzazione alla posizione negata.';

  @override
  String get passengerNoNotificationsYet => 'Nessuna notifica ancora.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Dettagli corsa';

  @override
  String passengerRideNumberLine(int id) {
    return 'Corsa n. $id';
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
