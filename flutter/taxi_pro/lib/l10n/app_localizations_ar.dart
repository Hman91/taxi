// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تاكسي برو تونس';

  @override
  String get homeWhatIsTitle => 'ما هو تاكسي برو؟';

  @override
  String get homeWhatIsBody =>
      'يربطك تاكسي برو تونس بالسائقين لنقل المطار والرحلات داخل المدينة. الأسعار ثابتة لكل مسار في التطبيق؛ وقد يُطبق رسم ليلي بين 9 مساءً و5 صباحًا. احجز في التطبيق، تتبع رحلتك، واستخدم المساعدة عند الحاجة.';

  @override
  String get loginAs => 'تسجيل الدخول كـ';

  @override
  String get language => 'اللغة';

  @override
  String get rolePassenger => 'حريف';

  @override
  String get roleDriver => 'سائق';

  @override
  String get roleOwner => 'مالك';

  @override
  String get roleOperator => 'موظف';

  @override
  String get roleB2b => 'شركات / B2B';

  @override
  String get passengerTitle => 'الحريف';

  @override
  String get tabAirport => 'المطار';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'المسار';

  @override
  String get nightFare50 => '+50٪ تعريفة ليلية';

  @override
  String get rateYourLastRide => 'قيّم رحلتك الأخيرة';

  @override
  String get submitRating => 'إرسال التقييم';

  @override
  String get thankYouFeedback => 'شكراً على ملاحظاتك!';

  @override
  String get distanceKmOptional => 'المسافة بالكم (اختياري — تقدير إن وُجد)';

  @override
  String get getEstimate => 'احصل على تقدير';

  @override
  String distanceKm(Object km) {
    return 'المسافة: $km كم';
  }

  @override
  String fareDt(Object amount) {
    return 'الأجرة: $amount د.ت';
  }

  @override
  String get driverTitle => 'السائق';

  @override
  String get driverCode => 'رمز السائق';

  @override
  String get login => 'دخول';

  @override
  String get sessionActive => 'جلسة نشطة';

  @override
  String get fareAmount => 'الأجرة (د.ت)';

  @override
  String get paymentType => 'طريقة الدفع';

  @override
  String get passengerFareFinalEstimate => 'تقدير نهائي للرحلة';

  @override
  String get passengerPayCash => 'كاش';

  @override
  String get passengerPayCardTpe => 'بطاقة (TPE)';

  @override
  String get cashOrCard => 'نقد / بطاقة';

  @override
  String get b2bInvoice => 'فاتورة شركة';

  @override
  String get completeTripCommission => 'إنهاء الرحلة (عمولة 10٪)';

  @override
  String loggedInAs(String role) {
    return 'تم الدخول كـ $role';
  }

  @override
  String get loginFirst => 'سجّل الدخول أولاً';

  @override
  String get invalidFare => 'أجرة غير صالحة';

  @override
  String tripRecorded(int id, Object commission) {
    return 'رحلة رقم $id مسجّلة. العمولة $commission د.ت';
  }

  @override
  String get ownerTitle => 'لوحة المالك';

  @override
  String get ownerPassword => 'كلمة سر المالك';

  @override
  String get loginLoadDashboard => 'دخول وتحميل اللوحة';

  @override
  String commissionLabel(Object amount) {
    return 'العمولة (د.ت): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'الرحلات: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'متوسط التقييم: $avg ($count صوت)';
  }

  @override
  String get tripsHeading => 'الرحلات';

  @override
  String get noTripsYet => 'لا رحلات بعد';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · عمولة $commission';
  }

  @override
  String get operatorTitle => 'الموظف / التوزيع';

  @override
  String get operatorCode => 'رمز الموظف';

  @override
  String get loginLoadTrips => 'دخول وتحميل الرحلات';

  @override
  String get noTripsLoaded => 'لم تُحمّل رحلات';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare د.ت';
  }

  @override
  String get b2bTitle => 'بوابة الشركات';

  @override
  String get companyCode => 'رمز الشركة';

  @override
  String get verifyCompanyCode => 'التحقق من رمز الشركة';

  @override
  String get b2bConnectedStub =>
      'متصل بالفوترة الشهرية (وضع تجريبي). يمكن ربط طلبات الرحلات والفاتورة PDF بالواجهة لاحقاً.';

  @override
  String get roleAppPassenger => 'حريف (رحلات ومحادثة)';

  @override
  String get roleAppDriver => 'سائق (تطبيق)';

  @override
  String get appPassengerTitle => 'الحريف — الرحلات';

  @override
  String get appDriverTitle => 'السائق — التطبيق';

  @override
  String get emailLabel => 'البريد';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signInApp => 'دخول';

  @override
  String get registerAppAccount => 'إنشاء حساب حريف';

  @override
  String get registerDriverAccount => 'إنشاء حساب سائق';

  @override
  String get logoutApp => 'خروج';

  @override
  String get genericCancel => 'إلغاء';

  @override
  String get syncPreferredLanguage => 'مزامنة اللغة مع الملف';

  @override
  String get profileLanguageSynced => 'تم تحديث اللغة المفضّلة.';

  @override
  String get myRidesHeading => 'رحلاتي';

  @override
  String get ridePickupLabel => 'الانطلاق';

  @override
  String get rideDestinationLabel => 'الوجهة';

  @override
  String get requestRideButton => 'طلب رحلة';

  @override
  String get openChatButton => 'محادثة';

  @override
  String get chatUnavailable => 'المحادثة غير متاحة لهذه الرحلة بعد.';

  @override
  String get noRidesYetApp => 'لا رحلات.';

  @override
  String get driverPendingRides => 'طلبات الرحلات';

  @override
  String get acceptRide => 'قبول';

  @override
  String get rejectRide => 'تحرير';

  @override
  String get startRide => 'بدء';

  @override
  String get completeRide => 'إنهاء';

  @override
  String get cancelRidePassenger => 'إلغاء الرحلة';

  @override
  String rideStatusFmt(String status) {
    return 'الحالة: $status';
  }

  @override
  String get adminOversightHeading => 'مراقبة مباشرة';

  @override
  String get adminLoadRidesBtn => 'تحميل رحلات التطبيق';

  @override
  String get adminLoadDriversBtn => 'مواقع السائقين';

  @override
  String get adminLoadOwnerMetricsBtn => 'مقاييس الإدارة';

  @override
  String get adminRidesHeading => 'رحلات التطبيق';

  @override
  String get adminDriversHeading => 'السائقون';

  @override
  String get adminNoRidesLoaded => 'اضغط «تحميل رحلات التطبيق».';

  @override
  String get adminNoDriversData => 'اضغط «مواقع السائقين».';

  @override
  String adminRideRow(String pickup, String destination) {
    return '$pickup → $destination';
  }

  @override
  String get placeCarthageAirport => 'مطار قرطاج';

  @override
  String get placeEnfidhaAirport => 'مطار النفيضة';

  @override
  String get placeMonastirAirport => 'مطار المنستير';

  @override
  String get placeSousseCenter => 'وسط سوسة';

  @override
  String get placeHammamet => 'الحمامات';

  @override
  String get placeSousse => 'سوسة';

  @override
  String get placePortElKantaoui => 'القنطاوي';

  @override
  String get placeNabeul => 'نابل';

  @override
  String driverLocationRow(String lat, String lng) {
    return 'خط العرض $lat، خط الطول $lng';
  }

  @override
  String get chatScreenTitle => 'محادثة الرحلة';

  @override
  String get messageFieldHint => 'اكتب رسالة';

  @override
  String get sendChatMessage => 'إرسال';

  @override
  String get accountDisabledContactAdmin => 'الحساب معطّل. تواصل مع المشرف.';

  @override
  String get signedInWithGoogle => 'تم تسجيل الدخول باستخدام Google';

  @override
  String get passengerGoogleLoginRequired =>
      'تسجيل الدخول عبر Google مطلوب للركاب.';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get passengerDispatchPanelTitle => 'لوحة التوزيع المميزة';

  @override
  String passengerActiveRidesChip(int count) {
    return 'رحلات نشطة: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'إجمالي الرحلات: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'الحجز';

  @override
  String get passengerLocationCurrent => 'موقعك الحالي';

  @override
  String get passengerLocationDetecting => 'جاري تحديد الموقع...';

  @override
  String get passengerLocationUnavailable => 'الموقع غير متاح';

  @override
  String get passengerRefreshLocationTooltip => 'تحديث الموقع';

  @override
  String passengerDriverLine(String name) {
    return 'السائق: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'الهاتف: $phone';
  }

  @override
  String get rideStatusPending => 'قيد الانتظار';

  @override
  String get rideStatusAccepted => 'مقبولة';

  @override
  String get rideStatusOngoing => 'جارية';

  @override
  String get rideStatusCompleted => 'مكتملة';

  @override
  String get rideStatusCancelled => 'ملغاة';

  @override
  String get rideStatusActive => 'نشطة';

  @override
  String get passengerLocationServiceDisabled => 'خدمة الموقع معطّلة.';

  @override
  String get passengerLocationPermissionDenied => 'لم يُمنح إذن الموقع.';

  @override
  String get passengerNoNotificationsYet => 'لا إشعارات بعد.';

  @override
  String get dialogOk => 'حسناً';

  @override
  String get passengerRideNotificationTitle => 'تفاصيل الرحلة';

  @override
  String passengerRideNumberLine(int id) {
    return 'الرحلة #$id';
  }

  @override
  String get notificationsEmpty => 'لا إشعارات بعد.';

  @override
  String get notificationRideUpdateTitle => 'تحديث الرحلة';

  @override
  String notificationRideUpdatedBody(int id) {
    return 'تم تحديث الرحلة #$id.';
  }

  @override
  String get errorGoogleSignInMissingToken =>
      'فشل تسجيل الدخول عبر Google: رمز مفقود.';

  @override
  String get driverNameFallback => 'سائق';

  @override
  String get notificationDriverAcceptedTitle => 'قبِل السائق';

  @override
  String notificationDriverAcceptedBody(String driver, String phoneSuffix) {
    return '$driver$phoneSuffix قبل طلبك.';
  }

  @override
  String notificationDriverAcceptedSnack(String driver, String phoneSuffix) {
    return 'قُبِل السائق: $driver$phoneSuffix';
  }

  @override
  String get passengerDriverNearPickupSnack => 'السائق قريب من نقطة الانطلاق.';

  @override
  String get notificationDriverNearPickupTitle => 'السائق قريب';

  @override
  String notificationDriverNearPickupBody(String pickup) {
    return 'سائقك قريب من الانطلاق في $pickup.';
  }

  @override
  String get notificationRequestSentTitle => 'تم إرسال الطلب';

  @override
  String get notificationRequestSentBody =>
      'أرسلنا طلبك إلى السائقين القريبين.';

  @override
  String requestSentSnackLine(String farePart, String promoPart) {
    return 'تم الإرسال. $farePart$promoPart';
  }

  @override
  String get promoCodeOptionalLabel => 'رمز ترويجي';

  @override
  String get driverNotificationNewNearbyTitle => 'رحلة جديدة قريبة';

  @override
  String get driverNotificationNewNearbyBodyDefault => 'طلب راكب قريباً رحلة.';

  @override
  String get driverNotificationTakenTitle => 'تم قبول الطلب مسبقاً';

  @override
  String get driverNotificationTakenBodyDefault => 'سائق آخر قبل هذا الطلب.';

  @override
  String get driverNotificationCancelledTitle => 'أُلغيت الرحلة';

  @override
  String get driverNotificationCancelledBodyDefault => 'ألغى الراكب الطلب.';

  @override
  String get driverNotificationRequestClosedTitle => 'أُغلق الطلب';

  @override
  String get driverNotificationRequestClosedBodyOther =>
      'قبل سائق آخر هذا الطلب أو أُلغي.';

  @override
  String get driverNotificationRequestClosedBodyTaken =>
      'قبل سائق آخر هذا الطلب.';

  @override
  String get driverNotificationNewRideTitle => 'طلب رحلة جديد';

  @override
  String get driverNotificationNewRideBodyDefault =>
      'أرسل راكب قريب طلباً جديداً.';

  @override
  String get snackDriverNewNearbyRide => 'وصل طلب رحلة جديد قريباً.';

  @override
  String get snackDriverRideTakenOther => 'قبل سائق آخر هذه الرحلة.';

  @override
  String get snackDriverPassengerCancelled => 'ألغى الراكب الطلب.';

  @override
  String get snackDriverChatAfterAcceptance =>
      'تُفتح المحادثة بعد قبول الرحلة.';

  @override
  String get driverMyVehicleTitle => 'مركبتي';

  @override
  String driverVehicleSummaryLine(String model, String color) {
    return 'النوع: $model | اللون: $color';
  }

  @override
  String get driverVehicleIdentityTitle => 'هوية المركبة';

  @override
  String driverOpenRequestsChip(int count) {
    return 'طلبات مفتوحة: $count';
  }

  @override
  String driverUnreadAlertsChip(int count) {
    return 'تنبيهات غير مقروءة: $count';
  }

  @override
  String get b2bAppBarTitle => 'تاكسي برو — الشركات';

  @override
  String get b2bPortalHeading => 'بوابة الشركات والنزل';

  @override
  String get b2bConnectedWorkflowSubtitle => 'متصل بمسار الفوترة الشهرية';

  @override
  String get b2bBookOnAccountHeading => 'احجز على حساب الشركة';

  @override
  String get b2bMonthlyUsageTitle => 'استهلاك الشهر الحالي (تجريبي)';

  @override
  String b2bMonthlyAmountDue(String amount) {
    return 'المبلغ المستحق (د.ت): $amount';
  }

  @override
  String b2bBookingSuccessMessage(
      String action, Object id, String guest, String route) {
    return '$action #$id • $guest • $route';
  }

  @override
  String get b2bFareAdminPercentSuffix => '• 5٪ إداري';

  @override
  String adminB2bBookingRowSubtitle(String guest, String room, String fare) {
    return '$guest • $room • $fare د.ت';
  }

  @override
  String get ownerAppBarTitle => 'لوحة المالك';

  @override
  String ownerProfitChip(String amount) {
    return 'الربح: $amount د.ت';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'الرحلات: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'خزنة الرحلات';

  @override
  String get ownerAdminOversightHeading => 'مراقبة الإدارة';

  @override
  String ownerCommissionChip(String amount) {
    return 'العمولة: $amount د.ت';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare د.ت';
  }

  @override
  String get ownerHqPortalHeading => 'مركز القيادة';

  @override
  String get operatorTabDispatch => 'الإرسال';

  @override
  String get operatorTabDrivers => 'السائقون';

  @override
  String get operatorTabB2b => 'شركات';

  @override
  String get operatorTabTripVault => 'سجل الرحلات';

  @override
  String get operatorDispatchCenterHeading => 'النداء والمراقبة';

  @override
  String get operatorDispatchPendingBlurb =>
      'يوجد طلبات معلّقة تحتاج توزيعاً على السائقين.';

  @override
  String get operatorDispatchIdleBlurb => 'النظام متصل. لا طلبات معلّقة.';

  @override
  String operatorChipPending(int count) {
    return 'معلّقة: $count';
  }

  @override
  String operatorChipAccepted(int count) {
    return 'مقبولة: $count';
  }

  @override
  String operatorChipOngoing(int count) {
    return 'جارية: $count';
  }

  @override
  String operatorChipCompleted(int count) {
    return 'مكتملة: $count';
  }

  @override
  String operatorRideSubtitleLine(
      String status, String driver, String created) {
    return '$status$driver$created';
  }

  @override
  String operatorDriversOnlineCount(int count) {
    return 'سائقون متصلون: $count';
  }

  @override
  String get operatorPhoneLabel => 'الهاتف';

  @override
  String get operatorDriverNameLabel => 'اسم السائق';

  @override
  String get operatorPinLabel => 'رمز PIN';

  @override
  String get operatorFillDriverFields =>
      'أدخل الهاتف واسم السائق والرقم السري.';

  @override
  String get operatorCreateDriverAccount => 'إنشاء حساب سائق';

  @override
  String get operatorRefreshCorporateBookings => 'تحديث حجوزات الشركات';

  @override
  String get operatorTripVaultHeading => 'خزنة الرحلات';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'الرحلات: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'الإيرادات: $amount د.ت';
  }

  @override
  String get operatorWalletBalanceLabel => 'رصيد المحفظة';

  @override
  String get operatorOwnerCommissionLabel => 'عمولة المالك %';

  @override
  String get operatorB2bCommissionLabel => 'عمولة الشركات %';

  @override
  String get operatorAutoDeductEnabled => 'الخصم التلقائي مفعّل';

  @override
  String get operatorCarModelLabel => 'طراز السيارة';

  @override
  String get operatorCarColorLabel => 'لون السيارة';

  @override
  String get operatorPickFromGallery => 'اختيار صورة من المعرض';

  @override
  String get operatorRemovePickedImage => 'إزالة الصورة';

  @override
  String get operatorPhotoUrlOptional => 'رابط الصورة (اختياري)';

  @override
  String get operatorCancel => 'إلغاء';

  @override
  String get operatorSave => 'حفظ';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'المحفظة: $wallet د.ت | مالك %: $owner | شركات %: $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | اللون: $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nالسيارة: $model';
  }

  @override
  String get statusLinePrefix => 'الحالة: ';

  @override
  String get driverLabelPrefix => ' | السائق: ';

  @override
  String get createdAtLinePrefix => '\nالوقت: ';

  @override
  String walletWithAmount(String amount) {
    return 'المحفظة: $amount د.ت';
  }
}
