// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro 突尼斯';

  @override
  String get loginAs => '登录身份';

  @override
  String get language => '语言';

  @override
  String get rolePassenger => '乘客';

  @override
  String get roleDriver => '司机';

  @override
  String get roleOwner => '车主';

  @override
  String get roleOperator => '调度员';

  @override
  String get roleB2b => '企业 / B2B';

  @override
  String get passengerTitle => '乘客';

  @override
  String get tabAirport => '机场';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => '路线';

  @override
  String get nightFare50 => '+50% 夜间加价';

  @override
  String get rateYourLastRide => '评价上一程';

  @override
  String get submitRating => '提交评分';

  @override
  String get thankYouFeedback => '感谢您的反馈！';

  @override
  String get distanceKmOptional => '距离（公里，可选 — 空则估算）';

  @override
  String get getEstimate => '获取估价';

  @override
  String distanceKm(Object km) {
    return '距离：$km 公里';
  }

  @override
  String fareDt(Object amount) {
    return '车费：$amount DT';
  }

  @override
  String get driverTitle => '司机';

  @override
  String get driverCode => '司机代码';

  @override
  String get login => '登录';

  @override
  String get sessionActive => '已登录';

  @override
  String get fareAmount => '车费（DT）';

  @override
  String get paymentType => '支付方式';

  @override
  String get cashOrCard => '现金 / 刷卡';

  @override
  String get b2bInvoice => '企业账单';

  @override
  String get completeTripCommission => '完成行程（10% 佣金）';

  @override
  String loggedInAs(String role) {
    return '已以 $role 身份登录';
  }

  @override
  String get loginFirst => '请先登录';

  @override
  String get invalidFare => '车费无效';

  @override
  String tripRecorded(int id, Object commission) {
    return '行程 #$id 已记录。佣金 $commission DT';
  }

  @override
  String get ownerTitle => '车主后台';

  @override
  String get ownerPassword => '车主密码';

  @override
  String get loginLoadDashboard => '登录并加载仪表盘';

  @override
  String commissionLabel(Object amount) {
    return '佣金（DT）：$amount';
  }

  @override
  String tripsCount(Object count) {
    return '行程数：$count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return '平均评分：$avg（$count 票）';
  }

  @override
  String get tripsHeading => '行程';

  @override
  String get noTripsYet => '暂无行程';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · 佣金 $commission';
  }

  @override
  String get operatorTitle => '调度 / 运营';

  @override
  String get operatorCode => '调度员代码';

  @override
  String get loginLoadTrips => '登录并加载行程';

  @override
  String get noTripsLoaded => '未加载行程';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B 企业';

  @override
  String get companyCode => '企业代码';

  @override
  String get verifyCompanyCode => '验证企业代码';

  @override
  String get b2bConnectedStub => '已连接月度账单（演示）。后续可将叫车与 PDF 发票接入 API。';
}
