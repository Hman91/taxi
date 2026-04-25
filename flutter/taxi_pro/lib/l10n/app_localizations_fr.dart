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
  String get homeWhatIsTitle => 'Qu\'est-ce que Taxi Pro ?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisie vous met en relation avec des chauffeurs pour les transferts aéroport et les trajets urbains. Les prix sont fixes par trajet dans l\'application ; un supplément de nuit peut s\'appliquer entre 21 h et 5 h. Réservez dans l\'application, suivez votre trajet et utilisez l\'aide intégrée si besoin.';

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
  String get passengerFareFinalEstimate => 'Estimation finale de la course';

  @override
  String get passengerPayCash => 'Espèces';

  @override
  String get passengerPayCardTpe => 'Carte (TPE)';

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
  String get operatorEntryGateLabel => 'Porte d\'entrée :';

  @override
  String get operatorEmployeePasswordLabel => 'Mot de passe employé :';

  @override
  String get operatorWelcomeOperatingRoom =>
      'Bienvenue dans la salle d\'opérations.';

  @override
  String get operatorTabTodaysArrivals => 'Arrivées du jour';

  @override
  String get operatorTabLiveOrders => 'Commandes en direct';

  @override
  String get operatorTabDriverManagement => 'Gestion des chauffeurs';

  @override
  String get operatorTabTripHistory => 'Historique des courses';

  @override
  String get operatorArrivalsDemoHeading =>
      'Arrivées du jour — Tunisie (données démo)';

  @override
  String get operatorColFlightNumber => 'Numéro de vol';

  @override
  String get operatorColDepartureAirport => 'Aéroport de départ';

  @override
  String get operatorColTakeoffTime => 'Heure de décollage';

  @override
  String get operatorColExpectedArrival => 'Arrivée prévue (aujourd\'hui)';

  @override
  String get operatorColArrivalAirportTn => 'Aéroport d\'arrivée (Tunisie)';

  @override
  String get operatorChooseDriverTopUp =>
      'Choisissez le chauffeur à recharger :';

  @override
  String get operatorAmountReceivedDt => 'Montant reçu (DT) :';

  @override
  String get operatorRechargeBalance => 'Recharger le solde';

  @override
  String get operatorCorporateBookingsSection =>
      'Réservations entreprises (B2B)';

  @override
  String get operatorRoleAdminHq => 'Admin HQ';

  @override
  String get operatorNoFlightArrivals => 'Aucune ligne d\'arrivée chargée.';

  @override
  String get operatorUserAccountsHeading =>
      'Comptes utilisateurs de l\'application';

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
  String get placeCarthageAirport => 'Carthage Airport (Tunis)';

  @override
  String get placeEnfidhaAirport => 'Enfidha–Hammamet Airport';

  @override
  String get placeMonastirAirport => 'Monastir Airport';

  @override
  String get placeSousseCenter => 'Centre-ville de Sousse';

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
  String get chatScreenTitle => 'Chat de course';

  @override
  String get messageFieldHint => 'Écrire un message';

  @override
  String get sendChatMessage => 'Envoyer';

  @override
  String get accountDisabledContactAdmin =>
      'Compte désactivé. Contactez un administrateur.';

  @override
  String get signedInWithGoogle => 'Connecté avec Google';

  @override
  String get passengerGoogleLoginRequired =>
      'La connexion avec Google est obligatoire pour les passagers.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get passengerDispatchPanelTitle => 'Panneau d’expédition premium';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Courses actives : $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Total des courses : $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Réservation';

  @override
  String get passengerLocationCurrent => 'Votre position actuelle';

  @override
  String get passengerLocationDetecting => 'Détection de la position…';

  @override
  String get passengerLocationUnavailable => 'Position indisponible';

  @override
  String get passengerRefreshLocationTooltip => 'Actualiser la position';

  @override
  String passengerDriverLine(String name) {
    return 'Chauffeur : $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Téléphone : $phone';
  }

  @override
  String get rideStatusPending => 'En attente';

  @override
  String get rideStatusAccepted => 'Acceptée';

  @override
  String get rideStatusOngoing => 'En cours';

  @override
  String get rideStatusCompleted => 'Terminée';

  @override
  String get rideStatusCancelled => 'Annulée';

  @override
  String get rideStatusActive => 'Active';

  @override
  String get passengerLocationServiceDisabled =>
      'Le service de localisation est désactivé.';

  @override
  String get passengerLocationPermissionDenied =>
      'Autorisation de localisation refusée.';

  @override
  String get passengerNoNotificationsYet =>
      'Aucune notification pour le moment.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Détails de la course';

  @override
  String passengerRideNumberLine(int id) {
    return 'Course n° $id';
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
  String get ownerAppBarTitle => 'QG propriétaire';

  @override
  String get ownerPasswordCeoLabel => 'Mot de passe propriétaire (CEO) :';

  @override
  String get ownerWelcomeHq => 'Bienvenue au QG propriétaire.';

  @override
  String get ownerTabTreasury => 'Trésorerie et profits';

  @override
  String get ownerTabSettings => 'Paramètres';

  @override
  String get ownerTabHostelB2b => 'Comptes hôteliers (B2B)';

  @override
  String get ownerSettingsCommissionLabel =>
      'Pourcentage de commission déduite (%) :';

  @override
  String get ownerSettingsCommissionHint =>
      'Affichage uniquement — lier aux comptes chauffeurs pour des taux en direct.';

  @override
  String get ownerSettingsRouteFaresHeading =>
      'Tarifs de base des trajets (DT)';

  @override
  String get ownerSaveRouteFare => 'Enregistrer';

  @override
  String ownerProfitChip(String amount) {
    return 'Profit : $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Courses : $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Coffre des courses';

  @override
  String get ownerAdminOversightHeading => 'Supervision admin';

  @override
  String ownerCommissionChip(String amount) {
    return 'Commission : $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'Centre de commande HQ';

  @override
  String get operatorTabDispatch => 'Dispatch';

  @override
  String get operatorTabDrivers => 'Chauffeurs';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Coffre des courses';

  @override
  String get operatorDispatchCenterHeading => 'Dispatch et supervision';

  @override
  String get operatorDispatchPendingBlurb =>
      'Des demandes en attente doivent être attribuées.';

  @override
  String get operatorDispatchIdleBlurb =>
      'Système connecté. Aucune réservation en attente.';

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
  String get operatorPhoneLabel => 'Téléphone';

  @override
  String get operatorDriverNameLabel => 'Nom du chauffeur';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields =>
      'Saisissez téléphone, nom du chauffeur et PIN.';

  @override
  String get operatorCreateDriverAccount => 'Créer un compte chauffeur';

  @override
  String get operatorRefreshCorporateBookings =>
      'Actualiser les réservations B2B';

  @override
  String get operatorTripVaultHeading => 'Coffre des courses';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Courses : $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Revenu : $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Solde portefeuille';

  @override
  String get operatorOwnerCommissionLabel => 'Commission propriétaire %';

  @override
  String get operatorB2bCommissionLabel => 'Commission B2B %';

  @override
  String get operatorAutoDeductEnabled => 'Déduction auto activée';

  @override
  String get operatorCarModelLabel => 'Modèle de voiture';

  @override
  String get operatorCarColorLabel => 'Couleur de voiture';

  @override
  String get operatorPickFromGallery => 'Choisir une image de la galerie';

  @override
  String get operatorRemovePickedImage => 'Retirer l\'image choisie';

  @override
  String get operatorPhotoUrlOptional => 'URL photo (optionnel)';

  @override
  String get operatorCancel => 'Annuler';

  @override
  String get operatorSave => 'Enregistrer';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Portefeuille : $wallet DT | Propriétaire % : $owner | B2B % : $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | Couleur : $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nVoiture : $model';
  }

  @override
  String get statusLinePrefix => 'Statut : ';

  @override
  String get driverLabelPrefix => ' | Chauffeur : ';

  @override
  String get createdAtLinePrefix => '\nÀ : ';

  @override
  String walletWithAmount(String amount) {
    return 'Wallet: $amount DT';
  }

  @override
  String get driverWalletDepletedTitle => 'Portefeuille vide';

  @override
  String driverWalletDepletedBody(int amount) {
    return 'Payez $amount DT au propriétaire (via l’opérateur) pour recharger.';
  }

  @override
  String get ownerDriverPinWalletsHeading => 'Portefeuilles conducteurs';

  @override
  String get ownerDriverPinWalletsEmpty =>
      'Aucun compte conducteur PIN chargé.';
}
