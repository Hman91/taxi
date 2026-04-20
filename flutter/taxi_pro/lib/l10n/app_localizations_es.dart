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
  String get passengerAirportCardTitle => 'Traslados al aeropuerto';

  @override
  String get passengerLoginDescription =>
      'Inicia sesión con correo y contraseña, o continúa con Google en dispositivos compatibles.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get signedInWithGoogle => 'Sesión iniciada con Google';

  @override
  String get signedInWithPassword => 'Sesión iniciada';

  @override
  String get fillEmailPassword => 'Introduce correo y contraseña.';

  @override
  String get registerSuccessMessage =>
      'Cuenta creada. Ya puedes iniciar sesión.';

  @override
  String get googleUnavailableOnThisDevice =>
      'El inicio de sesión con Google no está disponible en esta plataforma. Usa correo y contraseña.';

  @override
  String get orDivider => 'o';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get accountDisabledContactAdmin =>
      'Cuenta desactivada. Contacte a un administrador.';
}
