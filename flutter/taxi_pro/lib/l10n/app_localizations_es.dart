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
  String get homeWhatIsTitle => '¿Qué es Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Túnez te conecta con conductores para traslados al aeropuerto y viajes urbanos. Los precios son fijos por ruta en la app; puede aplicarse recargo nocturno entre las 21:00 y las 05:00. Reserva en la app, sigue tu viaje y usa la ayuda integrada cuando la necesites.';

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
  String get passengerFareFinalEstimate => 'Estimación final del viaje';

  @override
  String get passengerPayCash => 'Efectivo';

  @override
  String get passengerPayCardTpe => 'Tarjeta (TPE)';

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
  String get operatorEntryGateLabel => 'Puerta de acceso:';

  @override
  String get operatorEmployeePasswordLabel => 'Contraseña del empleado:';

  @override
  String get operatorWelcomeOperatingRoom =>
      'Bienvenido a la sala de operaciones.';

  @override
  String get operatorTabTodaysArrivals => 'Llegadas de hoy';

  @override
  String get operatorTabLiveOrders => 'Pedidos en vivo';

  @override
  String get operatorTabDriverManagement => 'Gestión de conductores';

  @override
  String get operatorTabTripHistory => 'Historial de viajes';

  @override
  String get operatorArrivalsDemoHeading =>
      'Llegadas de hoy — Túnez (datos demo)';

  @override
  String get operatorColFlightNumber => 'Número de vuelo';

  @override
  String get operatorColDepartureAirport => 'Aeropuerto de salida';

  @override
  String get operatorColTakeoffTime => 'Hora de despegue';

  @override
  String get operatorColExpectedArrival => 'Llegada prevista (hoy)';

  @override
  String get operatorColArrivalAirportTn => 'Aeropuerto de llegada (Túnez)';

  @override
  String get operatorChooseDriverTopUp => 'Elegir conductor a recargar:';

  @override
  String get operatorAmountReceivedDt => 'Importe recibido (DT):';

  @override
  String get operatorRechargeBalance => 'Recargar saldo';

  @override
  String get operatorCorporateBookingsSection => 'Reservas corporativas (B2B)';

  @override
  String get operatorRoleAdminHq => 'Admin central';

  @override
  String get operatorNoFlightArrivals => 'No hay llegadas cargadas.';

  @override
  String get operatorUserAccountsHeading => 'Cuentas de usuarios de la app';

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
  String get placeCarthageAirport => 'Aeropuerto de Cartago (Túnez)';

  @override
  String get placeEnfidhaAirport => 'Aeropuerto Enfidha–Hammamet';

  @override
  String get placeMonastirAirport => 'Aeropuerto de Monastir';

  @override
  String get placeSousseCenter => 'Centro de Sousse';

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
  String get notificationRideUpdateTitle => 'Actualización de viaje';

  @override
  String notificationRideUpdatedBody(int id) {
    return 'Viaje #$id actualizado.';
  }

  @override
  String get errorGoogleSignInMissingToken =>
      'Google sign-in failed: missing Google token.';

  @override
  String get driverNameFallback => 'Conductor';

  @override
  String get notificationDriverAcceptedTitle => 'Conductor aceptado';

  @override
  String notificationDriverAcceptedBody(String driver, String phoneSuffix) {
    return '$driver$phoneSuffix aceptó tu solicitud.';
  }

  @override
  String notificationDriverAcceptedSnack(String driver, String phoneSuffix) {
    return 'Conductor aceptado: $driver$phoneSuffix';
  }

  @override
  String get passengerDriverNearPickupSnack =>
      'El conductor está cerca de tu punto de recogida.';

  @override
  String get notificationDriverNearPickupTitle => 'Conductor cerca de recogida';

  @override
  String notificationDriverNearPickupBody(String pickup) {
    return 'Tu conductor está cerca del punto de recogida en $pickup.';
  }

  @override
  String get notificationRequestSentTitle => 'Solicitud enviada';

  @override
  String get notificationRequestSentBody =>
      'Enviamos tu solicitud de viaje a conductores cercanos.';

  @override
  String requestSentSnackLine(String farePart, String promoPart) {
    return 'Solicitud enviada. $farePart$promoPart';
  }

  @override
  String get promoCodeOptionalLabel => 'Promo code';

  @override
  String get driverNotificationNewNearbyTitle => 'Nuevo viaje cercano';

  @override
  String get driverNotificationNewNearbyBodyDefault =>
      'Un pasajero cercano solicitó un viaje.';

  @override
  String get driverNotificationTakenTitle => 'Solicitud ya aceptada';

  @override
  String get driverNotificationTakenBodyDefault =>
      'Otro conductor aceptó esta solicitud.';

  @override
  String get driverNotificationCancelledTitle => 'Viaje cancelado';

  @override
  String get driverNotificationCancelledBodyDefault =>
      'El pasajero canceló esta solicitud.';

  @override
  String get driverNotificationRequestClosedTitle => 'Solicitud cerrada';

  @override
  String get driverNotificationRequestClosedBodyOther =>
      'Esta solicitud fue aceptada por otro conductor o cancelada.';

  @override
  String get driverNotificationRequestClosedBodyTaken =>
      'Esta solicitud fue aceptada por otro conductor.';

  @override
  String get driverNotificationNewRideTitle => 'Nueva solicitud de viaje';

  @override
  String get driverNotificationNewRideBodyDefault =>
      'Un pasajero cercano envió una nueva solicitud.';

  @override
  String get snackDriverNewNearbyRide =>
      'Se recibió una nueva solicitud cercana.';

  @override
  String get driverRideRequestBannerTitle => '¡Nueva solicitud de viaje!';

  @override
  String get driverOfferFromLabel => 'Desde';

  @override
  String get driverOfferToLabel => 'Hasta';

  @override
  String get driverRejectOfferButton => 'Rechazar';

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
  String get snackDriverRideTakenOther => 'Viaje aceptado por otro conductor.';

  @override
  String get snackDriverPassengerCancelled =>
      'El pasajero canceló esta solicitud.';

  @override
  String get snackDriverChatAfterAcceptance =>
      'El chat se abrirá tras aceptar el viaje';

  @override
  String get driverMyVehicleTitle => 'Mi vehículo';

  @override
  String driverVehicleSummaryLine(String model, String color) {
    return 'Auto: $model | Color: $color';
  }

  @override
  String get driverVehicleIdentityTitle => 'Identidad del vehículo';

  @override
  String driverOpenRequestsChip(int count) {
    return 'Solicitudes abiertas: $count';
  }

  @override
  String driverUnreadAlertsChip(int count) {
    return 'Alertas sin leer: $count';
  }

  @override
  String get b2bAppBarTitle => 'Taxi Pro Corporativo';

  @override
  String get b2bPortalHeading => 'Portal corporativo y hotelero';

  @override
  String get b2bConnectedWorkflowSubtitle =>
      'Conectado al flujo de facturación mensual';

  @override
  String get b2bBookOnAccountHeading => 'Reservar en cuenta de empresa';

  @override
  String get b2bMonthlyUsageTitle => 'Uso del mes actual (demo)';

  @override
  String b2bMonthlyAmountDue(String amount) {
    return 'Importe adeudado (DT): $amount';
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
  String get ownerAppBarTitle => 'Sede del propietario';

  @override
  String get ownerPasswordCeoLabel => 'Contraseña del propietario (CEO):';

  @override
  String get ownerWelcomeHq => 'Bienvenido a la sede del propietario.';

  @override
  String get ownerTabTreasury => 'Tesorería y beneficios';

  @override
  String get ownerTabSettings => 'Configuración';

  @override
  String get ownerTabHostelB2b => 'Cuentas de hotel (B2B)';

  @override
  String get ownerSettingsCommissionLabel =>
      'Porcentaje de comisión deducida (%):';

  @override
  String get ownerSettingsCommissionHint =>
      'Solo visualización — vincular con cuentas de conductor para tasas en vivo.';

  @override
  String get ownerSettingsRouteFaresHeading => 'Tarifas base de rutas (DT)';

  @override
  String get ownerSaveRouteFare => 'Guardar';

  @override
  String ownerProfitChip(String amount) {
    return 'Beneficio: $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Viajes: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Registro de viajes';

  @override
  String get ownerAdminOversightHeading => 'Supervisión administrativa';

  @override
  String ownerCommissionChip(String amount) {
    return 'Comisión: $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'Centro de mando HQ';

  @override
  String get operatorTabDispatch => 'Despacho';

  @override
  String get operatorTabDrivers => 'Conductores';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Registro de viajes';

  @override
  String get operatorDispatchCenterHeading => 'Despacho y monitoreo';

  @override
  String get operatorDispatchPendingBlurb =>
      'Hay solicitudes pendientes que deben asignarse.';

  @override
  String get operatorDispatchIdleBlurb =>
      'El sistema está conectado. No hay reservas pendientes.';

  @override
  String operatorChipPending(int count) {
    return 'Pendientes: $count';
  }

  @override
  String operatorChipAccepted(int count) {
    return 'Aceptados: $count';
  }

  @override
  String operatorChipOngoing(int count) {
    return 'En curso: $count';
  }

  @override
  String operatorChipCompleted(int count) {
    return 'Completados: $count';
  }

  @override
  String operatorRideSubtitleLine(
      String status, String driver, String created) {
    return '$status$driver$created';
  }

  @override
  String operatorDriversOnlineCount(int count) {
    return 'Conductores en línea: $count';
  }

  @override
  String get operatorPhoneLabel => 'Teléfono';

  @override
  String get operatorDriverNameLabel => 'Nombre del conductor';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields =>
      'Ingrese teléfono, nombre del conductor y PIN.';

  @override
  String get operatorCreateDriverAccount => 'Crear cuenta de conductor';

  @override
  String get operatorRefreshCorporateBookings =>
      'Actualizar reservas corporativas';

  @override
  String get operatorTripVaultHeading => 'Registro de viajes';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Viajes: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Ingresos: $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Saldo de billetera';

  @override
  String get operatorOwnerCommissionLabel => 'Comisión del propietario %';

  @override
  String get operatorB2bCommissionLabel => 'Comisión B2B %';

  @override
  String get operatorAutoDeductEnabled => 'Deducción automática activa';

  @override
  String get operatorCarModelLabel => 'Modelo del auto';

  @override
  String get operatorCarColorLabel => 'Color del auto';

  @override
  String get operatorPickFromGallery => 'Elegir imagen de la galería';

  @override
  String get operatorRemovePickedImage => 'Quitar imagen seleccionada';

  @override
  String get operatorPhotoUrlOptional => 'URL de foto (opcional)';

  @override
  String get operatorCancel => 'Cancelar';

  @override
  String get operatorSave => 'Guardar';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Billetera: $wallet DT | Propietario %: $owner | B2B %: $b2b';
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
  String get statusLinePrefix => 'Estado: ';

  @override
  String get driverLabelPrefix => ' | Conductor: ';

  @override
  String get createdAtLinePrefix => '\nEn: ';

  @override
  String walletWithAmount(String amount) {
    return 'Billetera: $amount DT';
  }

  @override
  String get driverWalletDepletedTitle => 'Monedero vacío';

  @override
  String driverWalletDepletedBody(int amount) {
    return 'Pague $amount DT al propietario (vía el operador) para recargar.';
  }

  @override
  String get ownerDriverPinWalletsHeading => 'Carteras de conductores';

  @override
  String get ownerDriverPinWalletsEmpty =>
      'No hay cuentas de conductor PIN cargadas.';
}
