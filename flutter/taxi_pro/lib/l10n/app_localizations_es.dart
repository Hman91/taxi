// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Túnez';

  @override
  String get loginAs => 'Entrar como';

  @override
  String get language => 'Idioma';

  @override
  String get rolePassenger => 'Pasajero';

  @override
  String get roleDriver => 'Conductor';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleOperator => 'Operador';

  @override
  String get roleB2b => 'B2B / Empresa';

  @override
  String get passengerTitle => 'Pasajero';

  @override
  String get tabAirport => 'Aeropuerto';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Ruta';

  @override
  String get nightFare50 => '+50% tarifa nocturna';

  @override
  String get rateYourLastRide => 'Valora tu último viaje';

  @override
  String get submitRating => 'Enviar valoración';

  @override
  String get thankYouFeedback => '¡Gracias por tu opinión!';

  @override
  String get distanceKmOptional =>
      'Distancia km (opcional — estimación si vacío)';

  @override
  String get getEstimate => 'Obtener estimación';

  @override
  String distanceKm(Object km) {
    return 'Distancia: $km km';
  }

  @override
  String fareDt(Object amount) {
    return 'Tarifa: $amount DT';
  }

  @override
  String get driverTitle => 'Conductor';

  @override
  String get driverCode => 'Código de conductor';

  @override
  String get login => 'Entrar';

  @override
  String get sessionActive => 'Sesión activa';

  @override
  String get fareAmount => 'Tarifa (DT)';

  @override
  String get paymentType => 'Forma de pago';

  @override
  String get cashOrCard => 'Efectivo / tarjeta';

  @override
  String get b2bInvoice => 'Factura empresa';

  @override
  String get completeTripCommission => 'Completar viaje (comisión 10%)';

  @override
  String loggedInAs(String role) {
    return 'Sesión como $role';
  }

  @override
  String get loginFirst => 'Inicia sesión primero';

  @override
  String get invalidFare => 'Tarifa no válida';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Viaje #$id registrado. Comisión $commission DT';
  }

  @override
  String get ownerTitle => 'Panel del propietario';

  @override
  String get ownerPassword => 'Contraseña del propietario';

  @override
  String get loginLoadDashboard => 'Entrar y cargar panel';

  @override
  String commissionLabel(Object amount) {
    return 'Comisión (DT): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Viajes: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Valoración media: $avg ($count votos)';
  }

  @override
  String get tripsHeading => 'Viajes';

  @override
  String get noTripsYet => 'Sin viajes aún';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · com. $commission';
  }

  @override
  String get operatorTitle => 'Operador / Despacho';

  @override
  String get operatorCode => 'Código de operador';

  @override
  String get loginLoadTrips => 'Entrar y cargar viajes';

  @override
  String get noTripsLoaded => 'No hay viajes cargados';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Empresas';

  @override
  String get companyCode => 'Código de empresa';

  @override
  String get verifyCompanyCode => 'Verificar código de empresa';

  @override
  String get b2bConnectedStub =>
      'Conectado a facturación mensual (demo). Las solicitudes y la factura PDF se pueden enlazar a la API después.';

  @override
  String get roleAppPassenger => 'Pasajero (viajes y chat)';

  @override
  String get roleAppDriver => 'Conductor (app)';

  @override
  String get appPassengerTitle => 'Pasajero — viajes';

  @override
  String get appDriverTitle => 'Conductor — app';

  @override
  String get emailLabel => 'Correo';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get signInApp => 'Entrar';

  @override
  String get registerAppAccount => 'Crear cuenta de pasajero';

  @override
  String get registerDriverAccount => 'Crear cuenta de conductor';

  @override
  String get logoutApp => 'Salir';

  @override
  String get genericCancel => 'Cancelar';

  @override
  String get syncPreferredLanguage => 'Sincronizar idioma del perfil';

  @override
  String get profileLanguageSynced => 'Idioma preferido actualizado.';

  @override
  String get myRidesHeading => 'Mis viajes';

  @override
  String get ridePickupLabel => 'Recogida';

  @override
  String get rideDestinationLabel => 'Destino';

  @override
  String get requestRideButton => 'Solicitar viaje';

  @override
  String get openChatButton => 'Chat';

  @override
  String get chatUnavailable => 'El chat aún no está abierto para este viaje.';

  @override
  String get noRidesYetApp => 'Sin viajes.';

  @override
  String get driverPendingRides => 'Cola de viajes';

  @override
  String get acceptRide => 'Aceptar';

  @override
  String get rejectRide => 'Liberar';

  @override
  String get startRide => 'Iniciar';

  @override
  String get completeRide => 'Completar';

  @override
  String get cancelRidePassenger => 'Cancelar viaje';

  @override
  String rideStatusFmt(String status) {
    return 'Estado: $status';
  }

  @override
  String get adminOversightHeading => 'Supervisión en vivo';

  @override
  String get adminLoadRidesBtn => 'Cargar viajes de la app';

  @override
  String get adminLoadDriversBtn => 'Ubicaciones de conductores';

  @override
  String get adminLoadOwnerMetricsBtn => 'Métricas de administración';

  @override
  String get adminRidesHeading => 'Viajes de la app';

  @override
  String get adminDriversHeading => 'Conductores';

  @override
  String get adminNoRidesLoaded => 'Pulse «Cargar viajes de la app».';

  @override
  String get adminNoDriversData => 'Pulse «Ubicaciones de conductores».';

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
  String get chatScreenTitle => 'Chat del viaje';

  @override
  String get messageFieldHint => 'Escriba un mensaje';

  @override
  String get sendChatMessage => 'Enviar';

  @override
  String get accountDisabledContactAdmin =>
      'Cuenta desactivada. Contacte a un administrador.';

  @override
  String get signedInWithGoogle => 'Sesión iniciada con Google';

  @override
  String get passengerGoogleLoginRequired =>
      'Los pasajeros deben iniciar sesión con Google.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get passengerDispatchPanelTitle => 'Panel de despacho premium';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Viajes activos: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Total de viajes: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Reserva';

  @override
  String get passengerLocationCurrent => 'Tu ubicación actual';

  @override
  String get passengerLocationDetecting => 'Detectando ubicación...';

  @override
  String get passengerLocationUnavailable => 'Ubicación no disponible';

  @override
  String get passengerRefreshLocationTooltip => 'Actualizar ubicación';

  @override
  String passengerDriverLine(String name) {
    return 'Conductor: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Teléfono: $phone';
  }

  @override
  String get rideStatusPending => 'Pendiente';

  @override
  String get rideStatusAccepted => 'Aceptado';

  @override
  String get rideStatusOngoing => 'En curso';

  @override
  String get rideStatusCompleted => 'Completado';

  @override
  String get rideStatusCancelled => 'Cancelado';

  @override
  String get rideStatusActive => 'Activo';

  @override
  String get passengerLocationServiceDisabled =>
      'El servicio de ubicación está desactivado.';

  @override
  String get passengerLocationPermissionDenied =>
      'Permiso de ubicación denegado.';

  @override
  String get passengerNoNotificationsYet => 'Aún no hay notificaciones.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Detalles del viaje';

  @override
  String passengerRideNumberLine(int id) {
    return 'Viaje n.º $id';
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
