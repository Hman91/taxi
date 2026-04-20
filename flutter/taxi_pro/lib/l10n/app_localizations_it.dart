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
  String get passengerAirportCardTitle => 'Transfer aeroportuali';

  @override
  String get passengerLoginDescription =>
      'Accedi con email e password, o continua con Google sui dispositivi supportati.';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get signedInWithGoogle => 'Accesso con Google effettuato';

  @override
  String get signedInWithPassword => 'Accesso effettuato';

  @override
  String get fillEmailPassword => 'Inserisci email e password.';

  @override
  String get registerSuccessMessage => 'Account creato. Ora puoi accedere.';

  @override
  String get googleUnavailableOnThisDevice =>
      'Accesso Google non disponibile su questa piattaforma. Usa email e password.';

  @override
  String get orDivider => 'oppure';

  @override
  String get confirmPasswordLabel => 'Conferma password';

  @override
  String get passwordsDoNotMatch => 'Le password non coincidono.';

  @override
  String get accountDisabledContactAdmin =>
      'Account disabilitato. Contatta un amministratore.';
}
