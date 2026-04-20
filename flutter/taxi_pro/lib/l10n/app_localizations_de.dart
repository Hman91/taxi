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
  String get passengerAirportCardTitle => 'Flughafentransfers';

  @override
  String get passengerLoginDescription =>
      'Melden Sie sich mit E-Mail und Passwort an, oder fahren Sie mit Google auf unterstützten Geräten fort.';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get signedInWithGoogle => 'Mit Google angemeldet';

  @override
  String get signedInWithPassword => 'Angemeldet';

  @override
  String get fillEmailPassword => 'E-Mail und Passwort eingeben.';

  @override
  String get registerSuccessMessage =>
      'Konto erstellt. Sie können sich jetzt anmelden.';

  @override
  String get googleUnavailableOnThisDevice =>
      'Google-Anmeldung auf dieser Plattform nicht verfügbar. Bitte E-Mail und Passwort verwenden.';

  @override
  String get orDivider => 'oder';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein.';

  @override
  String get accountDisabledContactAdmin =>
      'Konto deaktiviert. Wenden Sie sich an einen Administrator.';
}
