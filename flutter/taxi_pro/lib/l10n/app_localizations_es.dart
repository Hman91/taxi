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
}
