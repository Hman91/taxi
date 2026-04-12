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
}
