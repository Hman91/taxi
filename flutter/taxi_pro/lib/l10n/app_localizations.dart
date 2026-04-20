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
  /// **'Payment type'**
  String get paymentType;

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

  /// No description provided for @passengerAirportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Airport transfers'**
  String get passengerAirportCardTitle;

  /// No description provided for @passengerLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email and password, or continue with Google on supported devices.'**
  String get passengerLoginDescription;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInWithGoogle;

  /// No description provided for @signedInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInWithPassword;

  /// No description provided for @fillEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password.'**
  String get fillEmailPassword;

  /// No description provided for @registerSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created. You can sign in now.'**
  String get registerSuccessMessage;

  /// No description provided for @googleUnavailableOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this platform. Use email and password.'**
  String get googleUnavailableOnThisDevice;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountDisabledContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Account disabled. Contact an administrator.'**
  String get accountDisabledContactAdmin;
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
