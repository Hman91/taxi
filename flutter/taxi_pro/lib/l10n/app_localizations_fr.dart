// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Tunisie';

  @override
  String get loginAs => 'Connexion en tant que';

  @override
  String get language => 'Langue';

  @override
  String get rolePassenger => 'Passager';

  @override
  String get roleDriver => 'Chauffeur';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleOperator => 'Opérateur';

  @override
  String get roleB2b => 'B2B / Entreprise';

  @override
  String get passengerTitle => 'Passager';

  @override
  String get tabAirport => 'Aéroport';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Trajet';

  @override
  String get nightFare50 => '+50 % tarif de nuit';

  @override
  String get rateYourLastRide => 'Notez votre dernière course';

  @override
  String get submitRating => 'Envoyer la note';

  @override
  String get thankYouFeedback => 'Merci pour votre avis !';

  @override
  String get distanceKmOptional =>
      'Distance en km (optionnel — estimation si vide)';

  @override
  String get getEstimate => 'Obtenir une estimation';

  @override
  String distanceKm(Object km) {
    return 'Distance : $km km';
  }

  @override
  String fareDt(Object amount) {
    return 'Tarif : $amount DT';
  }

  @override
  String get driverTitle => 'Chauffeur';

  @override
  String get driverCode => 'Code chauffeur';

  @override
  String get login => 'Connexion';

  @override
  String get sessionActive => 'Session active';

  @override
  String get fareAmount => 'Tarif (DT)';

  @override
  String get paymentType => 'Mode de paiement';

  @override
  String get cashOrCard => 'Espèces / carte';

  @override
  String get b2bInvoice => 'Facture entreprise';

  @override
  String get completeTripCommission => 'Terminer la course (commission 10 %)';

  @override
  String loggedInAs(String role) {
    return 'Connecté en tant que $role';
  }

  @override
  String get loginFirst => 'Connectez-vous d\'abord';

  @override
  String get invalidFare => 'Tarif invalide';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Course n°$id enregistrée. Commission $commission DT';
  }

  @override
  String get ownerTitle => 'Siège propriétaire';

  @override
  String get ownerPassword => 'Mot de passe propriétaire';

  @override
  String get loginLoadDashboard => 'Connexion et chargement du tableau de bord';

  @override
  String commissionLabel(Object amount) {
    return 'Commission (DT) : $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Courses : $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Note moyenne : $avg ($count votes)';
  }

  @override
  String get tripsHeading => 'Courses';

  @override
  String get noTripsYet => 'Aucune course';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · comm. $commission';
  }

  @override
  String get operatorTitle => 'Opérateur / Dispatch';

  @override
  String get operatorCode => 'Code opérateur';

  @override
  String get loginLoadTrips => 'Connexion et chargement des courses';

  @override
  String get noTripsLoaded => 'Aucune course chargée';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Entreprise';

  @override
  String get companyCode => 'Code entreprise';

  @override
  String get verifyCompanyCode => 'Vérifier le code entreprise';

  @override
  String get b2bConnectedStub =>
      'Connecté à la facturation mensuelle (démo). Les demandes et la facture PDF pourront être reliées à l\'API ensuite.';

  @override
  String get roleAppPassenger => 'Passager (courses et chat)';

  @override
  String get roleAppDriver => 'Chauffeur (appli)';

  @override
  String get appPassengerTitle => 'Passager — courses';

  @override
  String get appDriverTitle => 'Chauffeur — appli';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get signInApp => 'Connexion';

  @override
  String get registerAppAccount => 'Créer un compte passager';

  @override
  String get registerDriverAccount => 'Créer un compte chauffeur';

  @override
  String get logoutApp => 'Déconnexion';

  @override
  String get genericCancel => 'Annuler';

  @override
  String get syncPreferredLanguage => 'Synchroniser la langue du profil';

  @override
  String get profileLanguageSynced => 'Langue préférée mise à jour.';

  @override
  String get myRidesHeading => 'Mes courses';

  @override
  String get ridePickupLabel => 'Prise en charge';

  @override
  String get rideDestinationLabel => 'Destination';

  @override
  String get requestRideButton => 'Demander une course';

  @override
  String get openChatButton => 'Chat';

  @override
  String get chatUnavailable =>
      'Le chat n’est pas encore ouvert pour cette course.';

  @override
  String get noRidesYetApp => 'Aucune course.';

  @override
  String get driverPendingRides => 'File d’attente';

  @override
  String get acceptRide => 'Accepter';

  @override
  String get rejectRide => 'Libérer';

  @override
  String get startRide => 'Démarrer';

  @override
  String get completeRide => 'Terminer';

  @override
  String get cancelRidePassenger => 'Annuler la course';

  @override
  String rideStatusFmt(String status) {
    return 'Statut : $status';
  }

  @override
  String get adminOversightHeading => 'Supervision en direct';

  @override
  String get adminLoadRidesBtn => 'Charger les courses appli';

  @override
  String get adminLoadDriversBtn => 'Positions chauffeurs';

  @override
  String get adminLoadOwnerMetricsBtn => 'Métriques admin';

  @override
  String get adminRidesHeading => 'Courses appli';

  @override
  String get adminDriversHeading => 'Chauffeurs';

  @override
  String get adminNoRidesLoaded => 'Appuyez sur « Charger les courses appli ».';

  @override
  String get adminNoDriversData => 'Appuyez sur « Positions chauffeurs ».';

  @override
  String adminRideRow(String pickup, String destination) {
    return '$pickup → $destination';
  }

  @override
  String driverLocationRow(String lat, String lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get chatScreenTitle => 'Chat de course';

  @override
  String get messageFieldHint => 'Écrire un message';

  @override
  String get sendChatMessage => 'Envoyer';

  @override
  String get accountDisabledContactAdmin =>
      'Compte désactivé. Contactez un administrateur.';
}
