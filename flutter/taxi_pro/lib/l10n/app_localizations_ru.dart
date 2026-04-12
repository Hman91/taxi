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
}
