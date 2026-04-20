// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Taxi Pro Тунис';

  @override
  String get homeWhatIsTitle => 'What is Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisia connects you with drivers for airport transfers and city rides. Prices are fixed per route in the app; a night surcharge may apply between 9 PM and 5 AM. Book in the app, track your ride, and use in-app help when needed.';

  @override
  String get loginAs => 'Войти как';

  @override
  String get language => 'Язык';

  @override
  String get rolePassenger => 'Пассажир';

  @override
  String get roleDriver => 'Водитель';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleOperator => 'Диспетчер';

  @override
  String get roleB2b => 'B2B / Компания';

  @override
  String get passengerTitle => 'Пассажир';

  @override
  String get tabAirport => 'Аэропорт';

  @override
  String get tabGps => 'GPS';

  @override
  String get route => 'Маршрут';

  @override
  String get nightFare50 => '+50% ночной тариф';

  @override
  String get rateYourLastRide => 'Оцените последнюю поездку';

  @override
  String get submitRating => 'Отправить оценку';

  @override
  String get thankYouFeedback => 'Спасибо за отзыв!';

  @override
  String get distanceKmOptional =>
      'Расстояние, км (необязательно — оценка если пусто)';

  @override
  String get getEstimate => 'Получить оценку';

  @override
  String distanceKm(Object km) {
    return 'Расстояние: $km км';
  }

  @override
  String fareDt(Object amount) {
    return 'Стоимость: $amount DT';
  }

  @override
  String get driverTitle => 'Водитель';

  @override
  String get driverCode => 'Код водителя';

  @override
  String get login => 'Войти';

  @override
  String get sessionActive => 'Сессия активна';

  @override
  String get fareAmount => 'Стоимость (DT)';

  @override
  String get paymentType => 'Способ оплаты';

  @override
  String get passengerFareFinalEstimate => 'Final estimate for the ride';

  @override
  String get passengerPayCash => 'Cash';

  @override
  String get passengerPayCardTpe => 'Card (TPE)';

  @override
  String get cashOrCard => 'Наличные / карта';

  @override
  String get b2bInvoice => 'Счёт для компании';

  @override
  String get completeTripCommission => 'Завершить поездку (комиссия 10%)';

  @override
  String loggedInAs(String role) {
    return 'Вход как $role';
  }

  @override
  String get loginFirst => 'Сначала войдите';

  @override
  String get invalidFare => 'Неверная стоимость';

  @override
  String tripRecorded(int id, Object commission) {
    return 'Поездка №$id записана. Комиссия $commission DT';
  }

  @override
  String get ownerTitle => 'Панель владельца';

  @override
  String get ownerPassword => 'Пароль владельца';

  @override
  String get loginLoadDashboard => 'Войти и загрузить панель';

  @override
  String commissionLabel(Object amount) {
    return 'Комиссия (DT): $amount';
  }

  @override
  String tripsCount(Object count) {
    return 'Поездок: $count';
  }

  @override
  String avgRatingLabel(Object avg, Object count) {
    return 'Средняя оценка: $avg ($count голосов)';
  }

  @override
  String get tripsHeading => 'Поездки';

  @override
  String get noTripsYet => 'Пока нет поездок';

  @override
  String tripListSubtitle(String date, Object commission) {
    return '$date · ком. $commission';
  }

  @override
  String get operatorTitle => 'Диспетчер';

  @override
  String get operatorCode => 'Код диспетчера';

  @override
  String get loginLoadTrips => 'Войти и загрузить поездки';

  @override
  String get noTripsLoaded => 'Поездки не загружены';

  @override
  String operatorTripSubtitle(String date, Object fare) {
    return '$date · $fare DT';
  }

  @override
  String get b2bTitle => 'B2B Корпоративный';

  @override
  String get companyCode => 'Код компании';

  @override
  String get verifyCompanyCode => 'Проверить код компании';

  @override
  String get b2bConnectedStub =>
      'Подключено к ежемесячному биллингу (демо). Заявки и PDF-счёт можно связать с API позже.';

  @override
  String get roleAppPassenger => 'Пассажир (поездки и чат)';

  @override
  String get roleAppDriver => 'Водитель (приложение)';

  @override
  String get appPassengerTitle => 'Пассажир — поездки';

  @override
  String get appDriverTitle => 'Водитель — приложение';

  @override
  String get emailLabel => 'Эл. почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get signInApp => 'Войти';

  @override
  String get registerAppAccount => 'Создать аккаунт пассажира';

  @override
  String get registerDriverAccount => 'Создать аккаунт водителя';

  @override
  String get logoutApp => 'Выйти';

  @override
  String get genericCancel => 'Отмена';

  @override
  String get syncPreferredLanguage => 'Синхронизировать язык профиля';

  @override
  String get profileLanguageSynced => 'Предпочитаемый язык обновлён.';

  @override
  String get myRidesHeading => 'Мои поездки';

  @override
  String get ridePickupLabel => 'Откуда';

  @override
  String get rideDestinationLabel => 'Куда';

  @override
  String get requestRideButton => 'Заказать поездку';

  @override
  String get openChatButton => 'Чат';

  @override
  String get chatUnavailable => 'Чат для этой поездки ещё недоступен.';

  @override
  String get noRidesYetApp => 'Нет поездок.';

  @override
  String get driverPendingRides => 'Очередь заказов';

  @override
  String get acceptRide => 'Принять';

  @override
  String get rejectRide => 'Освободить';

  @override
  String get startRide => 'Начать';

  @override
  String get completeRide => 'Завершить';

  @override
  String get cancelRidePassenger => 'Отменить поездку';

  @override
  String rideStatusFmt(String status) {
    return 'Статус: $status';
  }

  @override
  String get adminOversightHeading => 'Мониторинг в реальном времени';

  @override
  String get adminLoadRidesBtn => 'Загрузить поездки приложения';

  @override
  String get adminLoadDriversBtn => 'Позиции водителей';

  @override
  String get adminLoadOwnerMetricsBtn => 'Админ-метрики';

  @override
  String get adminRidesHeading => 'Поездки приложения';

  @override
  String get adminDriversHeading => 'Водители';

  @override
  String get adminNoRidesLoaded => 'Нажмите «Загрузить поездки приложения».';

  @override
  String get adminNoDriversData => 'Нажмите «Позиции водителей».';

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
    return 'Шир. $lat, Долг. $lng';
  }

  @override
  String get chatScreenTitle => 'Чат поездки';

  @override
  String get messageFieldHint => 'Сообщение';

  @override
  String get sendChatMessage => 'Отправить';

  @override
  String get accountDisabledContactAdmin =>
      'Аккаунт отключён. Обратитесь к администратору.';

  @override
  String get signedInWithGoogle => 'Вход выполнен через Google';

  @override
  String get passengerGoogleLoginRequired =>
      'Для пассажиров требуется вход через Google.';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get passengerDispatchPanelTitle => 'Премиум‑диспетчерская панель';

  @override
  String passengerActiveRidesChip(int count) {
    return 'Активные поездки: $count';
  }

  @override
  String passengerTotalRidesChip(int count) {
    return 'Всего поездок: $count';
  }

  @override
  String get passengerBookingSectionTitle => 'Бронирование';

  @override
  String get passengerLocationCurrent => 'Ваше текущее местоположение';

  @override
  String get passengerLocationDetecting => 'Определение местоположения...';

  @override
  String get passengerLocationUnavailable => 'Местоположение недоступно';

  @override
  String get passengerRefreshLocationTooltip => 'Обновить местоположение';

  @override
  String passengerDriverLine(String name) {
    return 'Водитель: $name';
  }

  @override
  String passengerPhoneLine(String phone) {
    return 'Телефон: $phone';
  }

  @override
  String get rideStatusPending => 'Ожидает';

  @override
  String get rideStatusAccepted => 'Принята';

  @override
  String get rideStatusOngoing => 'В пути';

  @override
  String get rideStatusCompleted => 'Завершена';

  @override
  String get rideStatusCancelled => 'Отменена';

  @override
  String get rideStatusActive => 'Активна';

  @override
  String get passengerLocationServiceDisabled => 'Служба геолокации отключена.';

  @override
  String get passengerLocationPermissionDenied =>
      'Доступ к геолокации запрещён.';

  @override
  String get passengerNoNotificationsYet => 'Пока нет уведомлений.';

  @override
  String get dialogOk => 'OK';

  @override
  String get passengerRideNotificationTitle => 'Детали поездки';

  @override
  String passengerRideNumberLine(int id) {
    return 'Поездка № $id';
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
