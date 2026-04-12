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
}
