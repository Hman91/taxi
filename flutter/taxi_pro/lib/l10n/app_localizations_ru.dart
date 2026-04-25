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
  String get homeWhatIsTitle => 'Что такое Taxi Pro?';

  @override
  String get homeWhatIsBody =>
      'Taxi Pro Tunisia соединяет вас с водителями для трансферов из аэропорта и поездок по городу. Цены фиксированы по маршруту в приложении; с 21:00 до 05:00 может применяться ночная доплата. Бронируйте в приложении, отслеживайте поездку и используйте встроенную помощь при необходимости.';

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
  String get passengerFareFinalEstimate => 'Итоговая оценка поездки';

  @override
  String get passengerPayCash => 'Наличные';

  @override
  String get passengerPayCardTpe => 'Карта (TPE)';

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
  String get operatorEntryGateLabel => 'Входные ворота:';

  @override
  String get operatorEmployeePasswordLabel => 'Пароль сотрудника:';

  @override
  String get operatorWelcomeOperatingRoom =>
      'Добро пожаловать в диспетчерскую.';

  @override
  String get operatorTabTodaysArrivals => 'Прибытия сегодня';

  @override
  String get operatorTabLiveOrders => 'Заказы онлайн';

  @override
  String get operatorTabDriverManagement => 'Управление водителями';

  @override
  String get operatorTabTripHistory => 'История поездок';

  @override
  String get operatorArrivalsDemoHeading =>
      'Прибытия сегодня — Тунис (демо-данные)';

  @override
  String get operatorColFlightNumber => 'Номер рейса';

  @override
  String get operatorColDepartureAirport => 'Аэропорт вылета';

  @override
  String get operatorColTakeoffTime => 'Время вылета';

  @override
  String get operatorColExpectedArrival => 'Ожидаемое прибытие (сегодня)';

  @override
  String get operatorColArrivalAirportTn => 'Аэропорт прибытия (Тунис)';

  @override
  String get operatorChooseDriverTopUp => 'Выберите водителя для пополнения:';

  @override
  String get operatorAmountReceivedDt => 'Полученная сумма (DT):';

  @override
  String get operatorRechargeBalance => 'Пополнить баланс';

  @override
  String get operatorCorporateBookingsSection =>
      'Корпоративные бронирования (B2B)';

  @override
  String get operatorRoleAdminHq => 'Центральная админка';

  @override
  String get operatorNoFlightArrivals => 'Строки прибытия не загружены.';

  @override
  String get operatorUserAccountsHeading => 'Аккаунты пользователей приложения';

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
  String get placeSousseCenter => 'Центр Сусса';

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
  String get ownerAppBarTitle => 'Панель владельца';

  @override
  String get ownerPasswordCeoLabel => 'Пароль владельца (CEO):';

  @override
  String get ownerWelcomeHq => 'Добро пожаловать в панель владельца.';

  @override
  String get ownerTabTreasury => 'Казначейство и прибыль';

  @override
  String get ownerTabSettings => 'Настройки';

  @override
  String get ownerTabHostelB2b => 'Аккаунты отелей (B2B)';

  @override
  String get ownerSettingsCommissionLabel =>
      'Процент удерживаемой комиссии (%):';

  @override
  String get ownerSettingsCommissionHint =>
      'Только отображение — привязка к аккаунтам водителей для актуальных ставок.';

  @override
  String get ownerSettingsRouteFaresHeading => 'Базовые тарифы маршрутов (DT)';

  @override
  String get ownerSaveRouteFare => 'Сохранить';

  @override
  String ownerProfitChip(String amount) {
    return 'Прибыль: $amount DT';
  }

  @override
  String ownerTripsCountChip(String count) {
    return 'Поездки: $count';
  }

  @override
  String ownerRatingChip(String avg, String votes) {
    return '$avg ★ ($votes)';
  }

  @override
  String get ownerVaultHeading => 'Архив поездок';

  @override
  String get ownerAdminOversightHeading => 'Админ-контроль';

  @override
  String ownerCommissionChip(String amount) {
    return 'Комиссия: $amount DT';
  }

  @override
  String ownerTripRouteFareRow(String route, String fare) {
    return '$route — $fare DT';
  }

  @override
  String get ownerHqPortalHeading => 'Центр управления HQ';

  @override
  String get operatorTabDispatch => 'Диспетчеризация';

  @override
  String get operatorTabDrivers => 'Водители';

  @override
  String get operatorTabB2b => 'B2B';

  @override
  String get operatorTabTripVault => 'Архив поездок';

  @override
  String get operatorDispatchCenterHeading => 'Диспетчеризация и мониторинг';

  @override
  String get operatorDispatchPendingBlurb =>
      'Есть ожидающие заявки, которые нужно назначить.';

  @override
  String get operatorDispatchIdleBlurb =>
      'Система подключена. Ожидающих бронирований нет.';

  @override
  String operatorChipPending(int count) {
    return 'Ожидают: $count';
  }

  @override
  String operatorChipAccepted(int count) {
    return 'Приняты: $count';
  }

  @override
  String operatorChipOngoing(int count) {
    return 'В пути: $count';
  }

  @override
  String operatorChipCompleted(int count) {
    return 'Завершены: $count';
  }

  @override
  String operatorRideSubtitleLine(
      String status, String driver, String created) {
    return '$status$driver$created';
  }

  @override
  String operatorDriversOnlineCount(int count) {
    return 'Водителей онлайн: $count';
  }

  @override
  String get operatorPhoneLabel => 'Телефон';

  @override
  String get operatorDriverNameLabel => 'Имя водителя';

  @override
  String get operatorPinLabel => 'PIN';

  @override
  String get operatorFillDriverFields => 'Введите телефон, имя водителя и PIN.';

  @override
  String get operatorCreateDriverAccount => 'Создать аккаунт водителя';

  @override
  String get operatorRefreshCorporateBookings =>
      'Обновить корпоративные бронирования';

  @override
  String get operatorTripVaultHeading => 'Архив поездок';

  @override
  String operatorTripVaultTripsChip(int count) {
    return 'Поездки: $count';
  }

  @override
  String operatorTripVaultRevenueChip(String amount) {
    return 'Выручка: $amount DT';
  }

  @override
  String get operatorWalletBalanceLabel => 'Баланс кошелька';

  @override
  String get operatorOwnerCommissionLabel => 'Комиссия владельца %';

  @override
  String get operatorB2bCommissionLabel => 'Комиссия B2B %';

  @override
  String get operatorAutoDeductEnabled => 'Автосписание включено';

  @override
  String get operatorCarModelLabel => 'Модель авто';

  @override
  String get operatorCarColorLabel => 'Цвет авто';

  @override
  String get operatorPickFromGallery => 'Выбрать фото из галереи';

  @override
  String get operatorRemovePickedImage => 'Удалить выбранное фото';

  @override
  String get operatorPhotoUrlOptional => 'URL фото (необязательно)';

  @override
  String get operatorCancel => 'Отмена';

  @override
  String get operatorSave => 'Сохранить';

  @override
  String operatorDriverWalletLine(String wallet, String owner, String b2b) {
    return 'Кошелёк: $wallet DT | Владелец %: $owner | B2B %: $b2b';
  }

  @override
  String operatorDriverCarColorAppend(String color) {
    return ' | Цвет: $color';
  }

  @override
  String operatorDriverCarLine(String model) {
    return '\nАвто: $model';
  }

  @override
  String get statusLinePrefix => 'Статус: ';

  @override
  String get driverLabelPrefix => ' | Водитель: ';

  @override
  String get createdAtLinePrefix => '\nВ: ';

  @override
  String walletWithAmount(String amount) {
    return 'Wallet: $amount DT';
  }

  @override
  String get driverWalletDepletedTitle => 'Кошелёк пуст';

  @override
  String driverWalletDepletedBody(int amount) {
    return 'Внесите $amount DT владельцу (через оператора) для пополнения.';
  }

  @override
  String get ownerDriverPinWalletsHeading => 'Кошельки водителей';

  @override
  String get ownerDriverPinWalletsEmpty =>
      'Нет загруженных PIN-аккаунтов водителей.';
}
