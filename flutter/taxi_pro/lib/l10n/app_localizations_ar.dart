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
  String get passengerAirportCardTitle => 'رحلات المطارات';

  @override
  String get passengerLoginDescription =>
      'سجّل الدخول بالبريد وكلمة المرور، أو تابع عبر Google على الأجهزة المدعومة.';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get signedInWithGoogle => 'تم تسجيل الدخول عبر Google';

  @override
  String get signedInWithPassword => 'تم تسجيل الدخول';

  @override
  String get fillEmailPassword => 'أدخل البريد الإلكتروني وكلمة المرور.';

  @override
  String get registerSuccessMessage =>
      'تم إنشاء الحساب. يمكنك تسجيل الدخول الآن.';

  @override
  String get googleUnavailableOnThisDevice =>
      'تسجيل الدخول عبر Google غير متاح على هذا النظام. استخدم البريد وكلمة المرور.';

  @override
  String get orDivider => 'أو';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get accountDisabledContactAdmin => 'الحساب معطّل. تواصل مع المشرف.';
}
