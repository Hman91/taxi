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
  String get homeWhatIsTitle => 'What is Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisia connects you with drivers for airport transfers and city rides. Prices are fixed per route in the app; a night surcharge may apply between 9 PM and 5 AM. Book in the app, track your ride, and use in-app help when needed.';

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
  String get paymentType => 'Payment method';

  @override
  String get passengerFareFinalEstimate => 'Final estimate for the ride';

  @override
  String get passengerPayCash => 'Cash';

  @override
  String get passengerPayCardTpe => 'Card (TPE)';

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
  String get operatorEntryGateLabel => 'Entry gate:';

  @override
  String get operatorEmployeePasswordLabel => 'Employee password:';

  @override
  String get operatorWelcomeOperatingRoom => 'Welcome to the operating room.';

  @override
  String get operatorTabTodaysArrivals => 'Today\'s arrivals';

  @override
  String get operatorTabLiveOrders => 'Live orders';

  @override
  String get operatorTabDriverManagement => 'Driver management';

  @override
  String get operatorTabTripHistory => 'Trip history';

  @override
  String get operatorArrivalsDemoHeading =>
      'Today\'s arrivals — Tunisia (demo data)';

  @override
  String get operatorColFlightNumber => 'Flight number';

  @override
  String get operatorColDepartureAirport => 'Departure airport';

  @override
  String get operatorColTakeoffTime => 'Take-off time';

  @override
  String get operatorColExpectedArrival => 'Expected arrival (today)';

  @override
  String get operatorColArrivalAirportTn => 'Arrival airport (Tunisia)';

  @override
  String get operatorChooseDriverTopUp => 'Choose the driver to top up:';

  @override
  String get operatorAmountReceivedDt => 'Amount received (DT):';

  @override
  String get operatorRechargeBalance => 'Recharge the balance';

  @override
  String get operatorCorporateBookingsSection => 'Corporate (B2B) bookings';

  @override
  String get operatorRoleAdminHq => 'Admin HQ';

  @override
  String get operatorNoFlightArrivals => 'No arrival rows loaded.';

  @override
  String get operatorUserAccountsHeading => 'App user accounts';

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
  String get chatScreenTitle => 'Ride chat';

  @override
  String get messageFieldHint => 'Type a message';

  @override
  String get sendChatMessage => 'Send';

  @override
  String get accountDisabledContactAdmin =>
      'Account disabled. Contact an administrator.';

  @override
  String get signedInWithGoogle => 'Signed in with Google';

  @override
  String get passengerGoogleLoginRequired =>
      'Google login is required for passengers.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get passengerDispatchPanelTitle => 'Premium Dispatch Panel';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Active rides: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Total rides: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Booking';

  @override
  String get passengerLocationCurrent => 'Your current location';

  @override
  String get passengerLocationDetecting => 'Detecting location...';

  @override
  String get passengerLocationUnavailable => 'Location unavailable';

  @override
  String get passengerRefreshLocationTooltip => 'Refresh location';

  @override
  String passengerDriverLine(String name) {
    return 'Driver: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get rideStatusPending => 'Pending';

  @override
  String get rideStatusAccepted => 'Accepted';

  @override
  String get rideStatusOngoing => 'In progress';

  @override
  String get rideStatusCompleted => 'Completed';

  @override
  String get rideStatusCancelled => 'Cancelled';

  @override
  String get rideStatusActive => 'Active';

  @override
  String get passengerLocationServiceDisabled =>
      'Location service is disabled.';

  @override
  String get passengerLocationPermissionDenied => 'Location permission denied.';

  @override
  String get passengerNoNotificationsYet => 'No notifications yet.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Ride details';

  @override
  String passengerRideNumberLine(int id) {
    return 'Ride #$id';
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
  String get b2bFareAdminPercentSuffix => '• 5% admin';

  @override
  String adminB2bBookingRowSubtitle(String guest, String room, String fare) {
    return '$guest • $room • $fare DT';
  }

  @override
  String get ownerAppBarTitle => 'Owner HQ';

  @override
  String get ownerPasswordCeoLabel => 'Owner (CEO) password:';

  @override
  String get ownerWelcomeHq => 'Welcome to Owner HQ.';

  @override
  String get ownerTabTreasury => 'Treasury and profits';

  @override
  String get ownerTabSettings => 'Settings';

  @override
  String get ownerTabHostelB2b => 'Hostel Accounts (B2B)';

  @override
  String get ownerSettingsCommissionLabel =>
      'Commission deducted percentage (%):';

  @override
  String get ownerSettingsCommissionHint =>
      'Display only — link to driver accounts for live rates.';

  @override
  String get ownerSettingsRouteFaresHeading => 'Route base fares (DT)';

  @override
  String get ownerSaveRouteFare => 'Save';

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

  @override
  String get driverWalletDepletedTitle => 'Wallet empty';

  @override
  String driverWalletDepletedBody(int amount) {
    return 'Pay $amount DT to the owner (via the operator) to top up.';
  }

  @override
  String get ownerDriverPinWalletsHeading => 'Driver wallets';

  @override
  String get ownerDriverPinWalletsEmpty => 'No PIN driver accounts loaded.';
}
