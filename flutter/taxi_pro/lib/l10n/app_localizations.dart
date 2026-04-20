import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxi Pro Tunisia'**
  String get appTitle;

  /// No description provided for @homeWhatIsTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Taxi Pro?'**
  String get homeWhatIsTitle;

  /// No description provided for @homeWhatIsBody.
  ///
  /// In en, this message translates to:
  /// **'Taxi Pro Tunisia connects you with drivers for airport transfers and city rides. Prices are fixed per route in the app; a night surcharge may apply between 9 PM and 5 AM. Book in the app, track your ride, and use in-app help when needed.'**
  String get homeWhatIsBody;

  /// No description provided for @loginAs.
  ///
  /// In en, this message translates to:
  /// **'Login as'**
  String get loginAs;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @rolePassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get rolePassenger;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get roleOperator;

  /// No description provided for @roleB2b.
  ///
  /// In en, this message translates to:
  /// **'B2B / Corporate'**
  String get roleB2b;

  /// No description provided for @passengerTitle.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passengerTitle;

  /// No description provided for @tabAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get tabAirport;

  /// No description provided for @tabGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get tabGps;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @nightFare50.
  ///
  /// In en, this message translates to:
  /// **'+50% night fare'**
  String get nightFare50;

  /// No description provided for @rateYourLastRide.
  ///
  /// In en, this message translates to:
  /// **'Rate your last ride'**
  String get rateYourLastRide;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouFeedback;

  /// No description provided for @distanceKmOptional.
  ///
  /// In en, this message translates to:
  /// **'Distance km (optional — stub if empty)'**
  String get distanceKmOptional;

  /// No description provided for @getEstimate.
  ///
  /// In en, this message translates to:
  /// **'Get estimate'**
  String get getEstimate;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance: {km} km'**
  String distanceKm(Object km);

  /// No description provided for @fareDt.
  ///
  /// In en, this message translates to:
  /// **'Fare: {amount} DT'**
  String fareDt(Object amount);

  /// No description provided for @driverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverTitle;

  /// No description provided for @driverCode.
  ///
  /// In en, this message translates to:
  /// **'Driver code'**
  String get driverCode;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @sessionActive.
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get sessionActive;

  /// No description provided for @fareAmount.
  ///
  /// In en, this message translates to:
  /// **'Fare (DT)'**
  String get fareAmount;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentType;

  /// No description provided for @passengerFareFinalEstimate.
  ///
  /// In en, this message translates to:
  /// **'Final estimate for the ride'**
  String get passengerFareFinalEstimate;

  /// No description provided for @passengerPayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get passengerPayCash;

  /// No description provided for @passengerPayCardTpe.
  ///
  /// In en, this message translates to:
  /// **'Card (TPE)'**
  String get passengerPayCardTpe;

  /// No description provided for @cashOrCard.
  ///
  /// In en, this message translates to:
  /// **'Cash / card'**
  String get cashOrCard;

  /// No description provided for @b2bInvoice.
  ///
  /// In en, this message translates to:
  /// **'B2B invoice'**
  String get b2bInvoice;

  /// No description provided for @completeTripCommission.
  ///
  /// In en, this message translates to:
  /// **'Complete trip (10% commission)'**
  String get completeTripCommission;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {role}'**
  String loggedInAs(String role);

  /// No description provided for @loginFirst.
  ///
  /// In en, this message translates to:
  /// **'Login first'**
  String get loginFirst;

  /// No description provided for @invalidFare.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare'**
  String get invalidFare;

  /// No description provided for @tripRecorded.
  ///
  /// In en, this message translates to:
  /// **'Trip #{id} recorded. Commission {commission} DT'**
  String tripRecorded(int id, Object commission);

  /// No description provided for @ownerTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner HQ'**
  String get ownerTitle;

  /// No description provided for @ownerPassword.
  ///
  /// In en, this message translates to:
  /// **'Owner password'**
  String get ownerPassword;

  /// No description provided for @loginLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Login & load dashboard'**
  String get loginLoadDashboard;

  /// No description provided for @commissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission (DT): {amount}'**
  String commissionLabel(Object amount);

  /// No description provided for @tripsCount.
  ///
  /// In en, this message translates to:
  /// **'Trips: {count}'**
  String tripsCount(Object count);

  /// No description provided for @avgRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg rating: {avg} ({count} votes)'**
  String avgRatingLabel(Object avg, Object count);

  /// No description provided for @tripsHeading.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsHeading;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @tripListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{date} · comm {commission}'**
  String tripListSubtitle(String date, Object commission);

  /// No description provided for @operatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Operator / Dispatch'**
  String get operatorTitle;

  /// No description provided for @operatorCode.
  ///
  /// In en, this message translates to:
  /// **'Operator code'**
  String get operatorCode;

  /// No description provided for @loginLoadTrips.
  ///
  /// In en, this message translates to:
  /// **'Login & load trips'**
  String get loginLoadTrips;

  /// No description provided for @noTripsLoaded.
  ///
  /// In en, this message translates to:
  /// **'No trips loaded'**
  String get noTripsLoaded;

  /// No description provided for @operatorTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{date} · {fare} DT'**
  String operatorTripSubtitle(String date, Object fare);

  /// No description provided for @b2bTitle.
  ///
  /// In en, this message translates to:
  /// **'B2B Corporate'**
  String get b2bTitle;

  /// No description provided for @companyCode.
  ///
  /// In en, this message translates to:
  /// **'Company code'**
  String get companyCode;

  /// No description provided for @verifyCompanyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify company code'**
  String get verifyCompanyCode;

  /// No description provided for @b2bConnectedStub.
  ///
  /// In en, this message translates to:
  /// **'Connected to monthly billing (stub). Ride requests and PDF invoice can be wired to the API in a follow-up.'**
  String get b2bConnectedStub;

  /// No description provided for @roleAppPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger (rides & chat)'**
  String get roleAppPassenger;

  /// No description provided for @roleAppDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver (app shifts)'**
  String get roleAppDriver;

  /// No description provided for @appPassengerTitle.
  ///
  /// In en, this message translates to:
  /// **'Passenger — rides'**
  String get appPassengerTitle;

  /// No description provided for @appDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver — app'**
  String get appDriverTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInApp.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInApp;

  /// No description provided for @registerAppAccount.
  ///
  /// In en, this message translates to:
  /// **'Create passenger account'**
  String get registerAppAccount;

  /// No description provided for @registerDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'Create driver account'**
  String get registerDriverAccount;

  /// No description provided for @logoutApp.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutApp;

  /// No description provided for @genericCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get genericCancel;

  /// No description provided for @syncPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Sync language to profile'**
  String get syncPreferredLanguage;

  /// No description provided for @profileLanguageSynced.
  ///
  /// In en, this message translates to:
  /// **'Preferred language updated.'**
  String get profileLanguageSynced;

  /// No description provided for @myRidesHeading.
  ///
  /// In en, this message translates to:
  /// **'My rides'**
  String get myRidesHeading;

  /// No description provided for @ridePickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get ridePickupLabel;

  /// No description provided for @rideDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get rideDestinationLabel;

  /// No description provided for @requestRideButton.
  ///
  /// In en, this message translates to:
  /// **'Request ride'**
  String get requestRideButton;

  /// No description provided for @openChatButton.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get openChatButton;

  /// No description provided for @chatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chat is not open for this ride yet.'**
  String get chatUnavailable;

  /// No description provided for @noRidesYetApp.
  ///
  /// In en, this message translates to:
  /// **'No rides to show.'**
  String get noRidesYetApp;

  /// No description provided for @driverPendingRides.
  ///
  /// In en, this message translates to:
  /// **'Ride pool'**
  String get driverPendingRides;

  /// No description provided for @acceptRide.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptRide;

  /// No description provided for @rejectRide.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get rejectRide;

  /// No description provided for @startRide.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startRide;

  /// No description provided for @completeRide.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeRide;

  /// No description provided for @cancelRidePassenger.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRidePassenger;

  /// No description provided for @rideStatusFmt.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String rideStatusFmt(String status);

  /// No description provided for @adminOversightHeading.
  ///
  /// In en, this message translates to:
  /// **'Live app oversight'**
  String get adminOversightHeading;

  /// No description provided for @adminLoadRidesBtn.
  ///
  /// In en, this message translates to:
  /// **'Load app rides'**
  String get adminLoadRidesBtn;

  /// No description provided for @adminLoadDriversBtn.
  ///
  /// In en, this message translates to:
  /// **'Driver locations'**
  String get adminLoadDriversBtn;

  /// No description provided for @adminLoadOwnerMetricsBtn.
  ///
  /// In en, this message translates to:
  /// **'Load admin metrics'**
  String get adminLoadOwnerMetricsBtn;

  /// No description provided for @adminRidesHeading.
  ///
  /// In en, this message translates to:
  /// **'App rides'**
  String get adminRidesHeading;

  /// No description provided for @adminDriversHeading.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get adminDriversHeading;

  /// No description provided for @adminNoRidesLoaded.
  ///
  /// In en, this message translates to:
  /// **'Tap “Load app rides” to fetch.'**
  String get adminNoRidesLoaded;

  /// No description provided for @adminNoDriversData.
  ///
  /// In en, this message translates to:
  /// **'Tap “Driver locations” to fetch.'**
  String get adminNoDriversData;

  /// No description provided for @adminRideRow.
  ///
  /// In en, this message translates to:
  /// **'{pickup} → {destination}'**
  String adminRideRow(String pickup, String destination);

  /// No description provided for @placeCarthageAirport.
  ///
  /// In en, this message translates to:
  /// **'Carthage Airport (Tunis)'**
  String get placeCarthageAirport;

  /// No description provided for @placeEnfidhaAirport.
  ///
  /// In en, this message translates to:
  /// **'Enfidha–Hammamet Airport'**
  String get placeEnfidhaAirport;

  /// No description provided for @placeMonastirAirport.
  ///
  /// In en, this message translates to:
  /// **'Monastir Airport'**
  String get placeMonastirAirport;

  /// No description provided for @placeSousseCenter.
  ///
  /// In en, this message translates to:
  /// **'Sousse city center'**
  String get placeSousseCenter;

  /// No description provided for @placeHammamet.
  ///
  /// In en, this message translates to:
  /// **'Hammamet'**
  String get placeHammamet;

  /// No description provided for @placeSousse.
  ///
  /// In en, this message translates to:
  /// **'Sousse'**
  String get placeSousse;

  /// No description provided for @placePortElKantaoui.
  ///
  /// In en, this message translates to:
  /// **'Port El Kantaoui'**
  String get placePortElKantaoui;

  /// No description provided for @placeNabeul.
  ///
  /// In en, this message translates to:
  /// **'Nabeul'**
  String get placeNabeul;

  /// No description provided for @driverLocationRow.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat}, Lng {lng}'**
  String driverLocationRow(String lat, String lng);

  /// No description provided for @chatScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride chat'**
  String get chatScreenTitle;

  /// No description provided for @messageFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get messageFieldHint;

  /// No description provided for @sendChatMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendChatMessage;

  /// No description provided for @accountDisabledContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Account disabled. Contact an administrator.'**
  String get accountDisabledContactAdmin;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInWithGoogle;

  /// No description provided for @passengerGoogleLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Google login is required for passengers.'**
  String get passengerGoogleLoginRequired;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @passengerDispatchPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Dispatch Panel'**
  String get passengerDispatchPanelTitle;

  /// No description provided for @passengerActiveRidesChip.
  ///
  /// In en, this message translates to:
  /// **'Active rides: {count}'**
  String passengerActiveRidesChip(int count);

  /// No description provided for @passengerTotalRidesChip.
  ///
  /// In en, this message translates to:
  /// **'Total rides: {count}'**
  String passengerTotalRidesChip(int count);

  /// No description provided for @passengerBookingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get passengerBookingSectionTitle;

  /// No description provided for @passengerLocationCurrent.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get passengerLocationCurrent;

  /// No description provided for @passengerLocationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get passengerLocationDetecting;

  /// No description provided for @passengerLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get passengerLocationUnavailable;

  /// No description provided for @passengerRefreshLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get passengerRefreshLocationTooltip;

  /// No description provided for @passengerDriverLine.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String passengerDriverLine(String name);

  /// No description provided for @passengerPhoneLine.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String passengerPhoneLine(String phone);

  /// No description provided for @rideStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get rideStatusPending;

  /// No description provided for @rideStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get rideStatusAccepted;

  /// No description provided for @rideStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get rideStatusOngoing;

  /// No description provided for @rideStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get rideStatusCompleted;

  /// No description provided for @rideStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get rideStatusCancelled;

  /// No description provided for @rideStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rideStatusActive;

  /// No description provided for @passengerLocationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled.'**
  String get passengerLocationServiceDisabled;

  /// No description provided for @passengerLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get passengerLocationPermissionDenied;

  /// No description provided for @passengerNoNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get passengerNoNotificationsYet;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @passengerRideNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride details'**
  String get passengerRideNotificationTitle;

  /// No description provided for @passengerRideNumberLine.
  ///
  /// In en, this message translates to:
  /// **'Ride #{id}'**
  String passengerRideNumberLine(int id);

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationRideUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride update'**
  String get notificationRideUpdateTitle;

  /// No description provided for @notificationRideUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Ride #{id} updated.'**
  String notificationRideUpdatedBody(int id);

  /// No description provided for @errorGoogleSignInMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: missing Google token.'**
  String get errorGoogleSignInMissingToken;

  /// No description provided for @driverNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverNameFallback;

  /// No description provided for @notificationDriverAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted'**
  String get notificationDriverAcceptedTitle;

  /// No description provided for @notificationDriverAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'{driver}{phoneSuffix} accepted your request.'**
  String notificationDriverAcceptedBody(String driver, String phoneSuffix);

  /// No description provided for @notificationDriverAcceptedSnack.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted: {driver}{phoneSuffix}'**
  String notificationDriverAcceptedSnack(String driver, String phoneSuffix);

  /// No description provided for @passengerDriverNearPickupSnack.
  ///
  /// In en, this message translates to:
  /// **'Driver is now near your pickup point.'**
  String get passengerDriverNearPickupSnack;

  /// No description provided for @notificationDriverNearPickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver near pickup'**
  String get notificationDriverNearPickupTitle;

  /// No description provided for @notificationDriverNearPickupBody.
  ///
  /// In en, this message translates to:
  /// **'Your driver is near pickup in {pickup}.'**
  String notificationDriverNearPickupBody(String pickup);

  /// No description provided for @notificationRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get notificationRequestSentTitle;

  /// No description provided for @notificationRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'We sent your ride request to nearby drivers.'**
  String get notificationRequestSentBody;

  /// No description provided for @requestSentSnackLine.
  ///
  /// In en, this message translates to:
  /// **'Request sent. {farePart}{promoPart}'**
  String requestSentSnackLine(String farePart, String promoPart);

  /// No description provided for @promoCodeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCodeOptionalLabel;

  /// No description provided for @driverNotificationNewNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'New nearby ride'**
  String get driverNotificationNewNearbyTitle;

  /// No description provided for @driverNotificationNewNearbyBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'A nearby passenger requested a ride.'**
  String get driverNotificationNewNearbyBodyDefault;

  /// No description provided for @driverNotificationTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'Request already accepted'**
  String get driverNotificationTakenTitle;

  /// No description provided for @driverNotificationTakenBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Another driver accepted this request.'**
  String get driverNotificationTakenBodyDefault;

  /// No description provided for @driverNotificationCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled'**
  String get driverNotificationCancelledTitle;

  /// No description provided for @driverNotificationCancelledBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Passenger cancelled this ride request.'**
  String get driverNotificationCancelledBodyDefault;

  /// No description provided for @driverNotificationRequestClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request closed'**
  String get driverNotificationRequestClosedTitle;

  /// No description provided for @driverNotificationRequestClosedBodyOther.
  ///
  /// In en, this message translates to:
  /// **'This request was accepted by another driver or cancelled.'**
  String get driverNotificationRequestClosedBodyOther;

  /// No description provided for @driverNotificationRequestClosedBodyTaken.
  ///
  /// In en, this message translates to:
  /// **'This request was accepted by another driver.'**
  String get driverNotificationRequestClosedBodyTaken;

  /// No description provided for @driverNotificationNewRideTitle.
  ///
  /// In en, this message translates to:
  /// **'New ride request'**
  String get driverNotificationNewRideTitle;

  /// No description provided for @driverNotificationNewRideBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'A nearby passenger sent a new request.'**
  String get driverNotificationNewRideBodyDefault;

  /// No description provided for @snackDriverNewNearbyRide.
  ///
  /// In en, this message translates to:
  /// **'New nearby ride request received.'**
  String get snackDriverNewNearbyRide;

  /// No description provided for @snackDriverRideTakenOther.
  ///
  /// In en, this message translates to:
  /// **'Ride accepted by another driver.'**
  String get snackDriverRideTakenOther;

  /// No description provided for @snackDriverPassengerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Passenger cancelled this request.'**
  String get snackDriverPassengerCancelled;

  /// No description provided for @snackDriverChatAfterAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Chat will open after ride acceptance'**
  String get snackDriverChatAfterAcceptance;

  /// No description provided for @driverMyVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'My vehicle'**
  String get driverMyVehicleTitle;

  /// No description provided for @driverVehicleSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'Car: {model} | Color: {color}'**
  String driverVehicleSummaryLine(String model, String color);

  /// No description provided for @driverVehicleIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle identity'**
  String get driverVehicleIdentityTitle;

  /// No description provided for @driverOpenRequestsChip.
  ///
  /// In en, this message translates to:
  /// **'Open requests: {count}'**
  String driverOpenRequestsChip(int count);

  /// No description provided for @driverUnreadAlertsChip.
  ///
  /// In en, this message translates to:
  /// **'Unread alerts: {count}'**
  String driverUnreadAlertsChip(int count);

  /// No description provided for @b2bAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxi Pro Corporate'**
  String get b2bAppBarTitle;

  /// No description provided for @b2bPortalHeading.
  ///
  /// In en, this message translates to:
  /// **'Corporate & hotel portal'**
  String get b2bPortalHeading;

  /// No description provided for @b2bConnectedWorkflowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connected to monthly billing workflow'**
  String get b2bConnectedWorkflowSubtitle;

  /// No description provided for @b2bBookOnAccountHeading.
  ///
  /// In en, this message translates to:
  /// **'Book on company account'**
  String get b2bBookOnAccountHeading;

  /// No description provided for @b2bMonthlyUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Current month usage (stub)'**
  String get b2bMonthlyUsageTitle;

  /// No description provided for @b2bMonthlyAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due (DT): {amount}'**
  String b2bMonthlyAmountDue(String amount);

  /// No description provided for @b2bBookingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{action} #{id} • {guest} • {route}'**
  String b2bBookingSuccessMessage(
      String action, Object id, String guest, String route);

  /// No description provided for @b2bFareAdminPercentSuffix.
  ///
  /// In en, this message translates to:
  /// **'• 5% admin'**
  String get b2bFareAdminPercentSuffix;

  /// No description provided for @adminB2bBookingRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{guest} • {room} • {fare} DT'**
  String adminB2bBookingRowSubtitle(String guest, String room, String fare);

  /// No description provided for @ownerAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner HQ'**
  String get ownerAppBarTitle;

  /// No description provided for @ownerProfitChip.
  ///
  /// In en, this message translates to:
  /// **'Profit: {amount} DT'**
  String ownerProfitChip(String amount);

  /// No description provided for @ownerTripsCountChip.
  ///
  /// In en, this message translates to:
  /// **'Trips: {count}'**
  String ownerTripsCountChip(String count);

  /// No description provided for @ownerRatingChip.
  ///
  /// In en, this message translates to:
  /// **'{avg} ★ ({votes})'**
  String ownerRatingChip(String avg, String votes);

  /// No description provided for @ownerVaultHeading.
  ///
  /// In en, this message translates to:
  /// **'Trip vault'**
  String get ownerVaultHeading;

  /// No description provided for @ownerAdminOversightHeading.
  ///
  /// In en, this message translates to:
  /// **'Admin oversight'**
  String get ownerAdminOversightHeading;

  /// No description provided for @ownerCommissionChip.
  ///
  /// In en, this message translates to:
  /// **'Commission: {amount} DT'**
  String ownerCommissionChip(String amount);

  /// No description provided for @ownerTripRouteFareRow.
  ///
  /// In en, this message translates to:
  /// **'{route} — {fare} DT'**
  String ownerTripRouteFareRow(String route, String fare);

  /// No description provided for @ownerHqPortalHeading.
  ///
  /// In en, this message translates to:
  /// **'HQ command center'**
  String get ownerHqPortalHeading;

  /// No description provided for @operatorTabDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get operatorTabDispatch;

  /// No description provided for @operatorTabDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get operatorTabDrivers;

  /// No description provided for @operatorTabB2b.
  ///
  /// In en, this message translates to:
  /// **'B2B'**
  String get operatorTabB2b;

  /// No description provided for @operatorTabTripVault.
  ///
  /// In en, this message translates to:
  /// **'Trip vault'**
  String get operatorTabTripVault;

  /// No description provided for @operatorDispatchCenterHeading.
  ///
  /// In en, this message translates to:
  /// **'Dispatch & monitoring'**
  String get operatorDispatchCenterHeading;

  /// No description provided for @operatorDispatchPendingBlurb.
  ///
  /// In en, this message translates to:
  /// **'There are pending requests that need assigning.'**
  String get operatorDispatchPendingBlurb;

  /// No description provided for @operatorDispatchIdleBlurb.
  ///
  /// In en, this message translates to:
  /// **'System is connected. No pending bookings.'**
  String get operatorDispatchIdleBlurb;

  /// No description provided for @operatorChipPending.
  ///
  /// In en, this message translates to:
  /// **'Pending: {count}'**
  String operatorChipPending(int count);

  /// No description provided for @operatorChipAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted: {count}'**
  String operatorChipAccepted(int count);

  /// No description provided for @operatorChipOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing: {count}'**
  String operatorChipOngoing(int count);

  /// No description provided for @operatorChipCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed: {count}'**
  String operatorChipCompleted(int count);

  /// No description provided for @operatorRideSubtitleLine.
  ///
  /// In en, this message translates to:
  /// **'{status}{driver}{created}'**
  String operatorRideSubtitleLine(String status, String driver, String created);

  /// No description provided for @operatorDriversOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'Drivers online: {count}'**
  String operatorDriversOnlineCount(int count);

  /// No description provided for @operatorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get operatorPhoneLabel;

  /// No description provided for @operatorDriverNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver name'**
  String get operatorDriverNameLabel;

  /// No description provided for @operatorPinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get operatorPinLabel;

  /// No description provided for @operatorFillDriverFields.
  ///
  /// In en, this message translates to:
  /// **'Enter phone, driver name, and PIN.'**
  String get operatorFillDriverFields;

  /// No description provided for @operatorCreateDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'Create driver account'**
  String get operatorCreateDriverAccount;

  /// No description provided for @operatorRefreshCorporateBookings.
  ///
  /// In en, this message translates to:
  /// **'Refresh corporate bookings'**
  String get operatorRefreshCorporateBookings;

  /// No description provided for @operatorTripVaultHeading.
  ///
  /// In en, this message translates to:
  /// **'Trip vault'**
  String get operatorTripVaultHeading;

  /// No description provided for @operatorTripVaultTripsChip.
  ///
  /// In en, this message translates to:
  /// **'Trips: {count}'**
  String operatorTripVaultTripsChip(int count);

  /// No description provided for @operatorTripVaultRevenueChip.
  ///
  /// In en, this message translates to:
  /// **'Revenue: {amount} DT'**
  String operatorTripVaultRevenueChip(String amount);

  /// No description provided for @operatorWalletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get operatorWalletBalanceLabel;

  /// No description provided for @operatorOwnerCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner commission %'**
  String get operatorOwnerCommissionLabel;

  /// No description provided for @operatorB2bCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'B2B commission %'**
  String get operatorB2bCommissionLabel;

  /// No description provided for @operatorAutoDeductEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto deduct enabled'**
  String get operatorAutoDeductEnabled;

  /// No description provided for @operatorCarModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Car model'**
  String get operatorCarModelLabel;

  /// No description provided for @operatorCarColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Car color'**
  String get operatorCarColorLabel;

  /// No description provided for @operatorPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick image from gallery'**
  String get operatorPickFromGallery;

  /// No description provided for @operatorRemovePickedImage.
  ///
  /// In en, this message translates to:
  /// **'Remove picked image'**
  String get operatorRemovePickedImage;

  /// No description provided for @operatorPhotoUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo URL (optional)'**
  String get operatorPhotoUrlOptional;

  /// No description provided for @operatorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get operatorCancel;

  /// No description provided for @operatorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get operatorSave;

  /// No description provided for @operatorDriverWalletLine.
  ///
  /// In en, this message translates to:
  /// **'Wallet: {wallet} DT | Owner %: {owner} | B2B %: {b2b}'**
  String operatorDriverWalletLine(String wallet, String owner, String b2b);

  /// No description provided for @operatorDriverCarColorAppend.
  ///
  /// In en, this message translates to:
  /// **' | Color: {color}'**
  String operatorDriverCarColorAppend(String color);

  /// No description provided for @operatorDriverCarLine.
  ///
  /// In en, this message translates to:
  /// **'\nCar: {model}'**
  String operatorDriverCarLine(String model);

  /// No description provided for @statusLinePrefix.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get statusLinePrefix;

  /// No description provided for @driverLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **' | Driver: '**
  String get driverLabelPrefix;

  /// No description provided for @createdAtLinePrefix.
  ///
  /// In en, this message translates to:
  /// **'\nAt: '**
  String get createdAtLinePrefix;

  /// No description provided for @walletWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Wallet: {amount} DT'**
  String walletWithAmount(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
