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

  @override
  String get roleAppPassenger => '乘客（行程与聊天）';

  @override
  String get roleAppDriver => '司机（应用）';

  @override
  String get appPassengerTitle => '乘客 — 行程';

  @override
  String get appDriverTitle => '司机 — 应用';

  @override
  String get emailLabel => '邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get signInApp => '登录';

  @override
  String get registerAppAccount => '注册乘客账号';

  @override
  String get registerDriverAccount => '注册司机账号';

  @override
  String get logoutApp => '退出';

  @override
  String get genericCancel => '取消';

  @override
  String get syncPreferredLanguage => '将语言同步到个人资料';

  @override
  String get profileLanguageSynced => '已更新首选语言。';

  @override
  String get myRidesHeading => '我的行程';

  @override
  String get ridePickupLabel => '上车点';

  @override
  String get rideDestinationLabel => '目的地';

  @override
  String get requestRideButton => '叫车';

  @override
  String get openChatButton => '聊天';

  @override
  String get chatUnavailable => '此行程尚未开启聊天。';

  @override
  String get noRidesYetApp => '暂无行程。';

  @override
  String get driverPendingRides => '待接订单';

  @override
  String get acceptRide => '接单';

  @override
  String get rejectRide => '释放';

  @override
  String get startRide => '开始';

  @override
  String get completeRide => '完成';

  @override
  String get cancelRidePassenger => '取消行程';

  @override
  String rideStatusFmt(String status) {
    return '状态：$status';
  }

  @override
  String get adminOversightHeading => '实时监控';

  @override
  String get adminLoadRidesBtn => '加载应用行程';

  @override
  String get adminLoadDriversBtn => '司机位置';

  @override
  String get adminLoadOwnerMetricsBtn => '管理指标';

  @override
  String get adminRidesHeading => '应用行程';

  @override
  String get adminDriversHeading => '司机';

  @override
  String get adminNoRidesLoaded => '点击「加载应用行程」。';

  @override
  String get adminNoDriversData => '点击「司机位置」。';

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
  String get placeSousseCenter => 'Sousse city center';

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
    return '纬度 $lat，经度 $lng';
  }

  @override
  String get chatScreenTitle => '行程聊天';

  @override
  String get messageFieldHint => '输入消息';

  @override
  String get sendChatMessage => '发送';

  @override
  String get accountDisabledContactAdmin => '账号已停用，请联系管理员。';

  @override
  String get signedInWithGoogle => '已使用 Google 登录';

  @override
  String get passengerGoogleLoginRequired => '乘客必须使用 Google 登录。';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get passengerDispatchPanelTitle => '高级调度面板';

  @override
  String passengerActiveRidesChip(int count) {
    return '进行中的行程：$count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return '行程总数：$count';
  }

  @override
  String get passengerBookingSectionTitle => '预订';

  @override
  String get passengerLocationCurrent => '您当前的位置';

  @override
  String get passengerLocationDetecting => '正在获取位置...';

  @override
  String get passengerLocationUnavailable => '无法获取位置';

  @override
  String get passengerRefreshLocationTooltip => '刷新位置';

  @override
  String passengerDriverLine(String name) {
    return '司机：$name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return '电话：$phone';
  }

  @override
  String get rideStatusPending => '待接单';

  @override
  String get rideStatusAccepted => '已接单';

  @override
  String get rideStatusOngoing => '进行中';

  @override
  String get rideStatusCompleted => '已完成';

  @override
  String get rideStatusCancelled => '已取消';

  @override
  String get rideStatusActive => '进行中';

  @override
  String get passengerLocationServiceDisabled => '定位服务已关闭。';

  @override
  String get passengerLocationPermissionDenied => '未授予位置权限。';

  @override
  String get passengerNoNotificationsYet => '暂无通知。';

  @override
  String get dialogOk => '确定';

  @override
  String get passengerRideNotificationTitle => '行程详情';

  @override
  String passengerRideNumberLine(int id) {
    return '行程 #$id';
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
  String get ownerAppBarTitle => 'Owner HQ';

  @override
  String ownerProfitChip(String amount) {
    return 'Profit: $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Trips: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Trip vault';

  @override
  String get ownerAdminOversightHeading => 'Admin oversight';

  @override
  String ownerCommissionChip(String amount) {
    return 'Commission: $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'HQ command center';

  @override
  String get operatorTabDispatch => 'Dispatch';

  @override
  String get operatorTabDrivers => 'Drivers';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Trip vault';

  @override
  String get operatorDispatchCenterHeading => 'Dispatch & monitoring';

  @override
  String get operatorDispatchPendingBlurb =>
      'There are pending requests that need assigning.';

  @override
  String get operatorDispatchIdleBlurb =>
      'System is connected. No pending bookings.';

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
  String get operatorPhoneLabel => 'Phone';

  @override
  String get operatorDriverNameLabel => 'Driver name';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields => 'Enter phone, driver name, and PIN.';

  @override
  String get operatorCreateDriverAccount => 'Create driver account';

  @override
  String get operatorRefreshCorporateBookings => 'Refresh corporate bookings';

  @override
  String get operatorTripVaultHeading => 'Trip vault';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Trips: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Revenue: $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Wallet balance';

  @override
  String get operatorOwnerCommissionLabel => 'Owner commission %';

  @override
  String get operatorB2bCommissionLabel => 'B2B commission %';

  @override
  String get operatorAutoDeductEnabled => 'Auto deduct enabled';

  @override
  String get operatorCarModelLabel => 'Car model';

  @override
  String get operatorCarColorLabel => 'Car color';

  @override
  String get operatorPickFromGallery => 'Pick image from gallery';

  @override
  String get operatorRemovePickedImage => 'Remove picked image';

  @override
  String get operatorPhotoUrlOptional => 'Photo URL (optional)';

  @override
  String get operatorCancel => 'Cancel';

  @override
  String get operatorSave => 'Save';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Wallet: $wallet DT | Owner %: $owner | B2B %: $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | Color: $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nCar: $model';
  }

  @override
  String get statusLinePrefix => 'Status: ';

  @override
  String get driverLabelPrefix => ' | Driver: ';

  @override
  String get createdAtLinePrefix => '\nAt: ';

  @override
  String walletWithAmount(String amount) {
    return 'Wallet: $amount DT';
  }
}
