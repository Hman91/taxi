import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_locale.dart'
    show
        AppUiRole,
        rememberCurrentLocaleForRole,
        restoreUiRoleLocale,
        userChoseLocaleThisSession,
        appLocale;
import '../config.dart';
import '../maps/tunisia_tourist_restaurants.dart';
import '../maps/tunisia_zone_coordinates.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_address_display.dart';
import '../l10n/ride_status_localization.dart';
import '../utils/ride_locked_quote.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../utils/chat_unread_poll.dart'
    show
        cachedOrFetchConversationId,
        computeUnreadChatDelta,
        maxChatMessageId,
        rideMayHaveConversation;
import '../utils/int_from_json.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';
import 'b2b_corporate_map_l10n.dart';
import 'corporate_reservation_map_screen.dart';
import 'ride_chat_screen.dart';
import 'unified_login_screen.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const bgWarm = Color(0xFFF8F5EC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF111111);
  static const textMid = Color(0xFF3F3F3F);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE4E4);
  static const neonBlue = Color(0xFFFFC200);
}

const Map<String, Map<String, String>> _b2bUiTranslations = {
  'driverReserved': {
    'en': 'Driver reserved',
    'fr': 'Chauffeur réservé',
    'ar': 'تم حجز سائق',
    'de': 'Fahrer reserviert',
    'es': 'Conductor reservado',
    'it': 'Autista prenotato',
    'zh': '司机已预约',
    'ru': 'Водитель забронирован',
  },
  'reservationCancelled': {
    'en': 'Reservation cancelled',
    'fr': 'Réservation annulée',
    'ar': 'تم إلغاء الحجز',
    'de': 'Reservierung storniert',
    'es': 'Reserva cancelada',
    'it': 'Prenotazione annullata',
    'zh': '预约已取消',
    'ru': 'Бронирование отменено',
  },
  'completed': {
    'en': 'Completed',
    'fr': 'Terminé',
    'ar': 'مكتمل',
    'de': 'Abgeschlossen',
    'es': 'Completado',
    'it': 'Completato',
    'zh': '已完成',
    'ru': 'Завершено',
  },
  'searching': {
    'en': 'Searching',
    'fr': 'Recherche',
    'ar': 'جارٍ البحث',
    'de': 'Suche läuft',
    'es': 'Buscando',
    'it': 'Ricerca',
    'zh': '正在搜索',
    'ru': 'Поиск',
  },
  'upcomingRide': {
    'en': 'Upcoming ride',
    'fr': 'Course à venir',
    'ar': 'رحلة قادمة',
    'de': 'Bevorstehende Fahrt',
    'es': 'Viaje próximo',
    'it': 'Corsa in arrivo',
    'zh': '即将开始的行程',
    'ru': 'Предстоящая поездка',
  },
  'scheduled': {
    'en': 'Scheduled',
    'fr': 'Planifié',
    'ar': 'مجدول',
    'de': 'Geplant',
    'es': 'Programado',
    'it': 'Programmato',
    'zh': '已预约',
    'ru': 'Запланировано',
  },
  'pickupWindowOpen': {
    'en': 'Pickup window open',
    'fr': 'Fenêtre de prise en charge ouverte',
    'ar': 'وقت الانطلاق مفتوح',
    'de': 'Abholfenster geöffnet',
    'es': 'Ventana de recogida abierta',
    'it': 'Finestra di ritiro aperta',
    'zh': '接送时间窗口已开启',
    'ru': 'Окно подачи открыто',
  },
  'editB2bAccount': {
    'en': 'Edit B2B account',
    'fr': 'Modifier le compte B2B',
    'ar': 'تعديل حساب B2B',
    'de': 'B2B-Konto bearbeiten',
    'es': 'Editar cuenta B2B',
    'it': 'Modifica account B2B',
    'zh': '编辑 B2B 账号',
    'ru': 'Редактировать аккаунт B2B',
  },
  'newPasswordOptional': {
    'en': 'New password (optional)',
    'fr': 'Nouveau mot de passe (optionnel)',
    'ar': 'كلمة مرور جديدة (اختياري)',
    'de': 'Neues Passwort (optional)',
    'es': 'Nueva contraseña (opcional)',
    'it': 'Nuova password (opzionale)',
    'zh': '新密码（可选）',
    'ru': 'Новый пароль (необязательно)',
  },
  'name': {
    'en': 'Name',
    'fr': 'Nom',
    'ar': 'الاسم',
    'de': 'Name',
    'es': 'Nombre',
    'it': 'Nome',
    'zh': '姓名',
    'ru': 'Имя',
  },
  'phone': {
    'en': 'Phone',
    'fr': 'Téléphone',
    'ar': 'الهاتف',
    'de': 'Telefon',
    'es': 'Teléfono',
    'it': 'Telefono',
    'zh': '电话',
    'ru': 'Телефон',
  },
  'save': {
    'en': 'Save',
    'fr': 'Enregistrer',
    'ar': 'حفظ',
    'de': 'Speichern',
    'es': 'Guardar',
    'it': 'Salva',
    'zh': '保存',
    'ru': 'Сохранить',
  },
  'accountUpdated': {
    'en': 'Account updated successfully.',
    'fr': 'Compte mis à jour avec succès.',
    'ar': 'تم تحديث الحساب بنجاح.',
    'de': 'Konto erfolgreich aktualisiert.',
    'es': 'Cuenta actualizada correctamente.',
    'it': 'Account aggiornato correttamente.',
    'zh': '账号已成功更新。',
    'ru': 'Аккаунт успешно обновлён.',
  },
  'loginSubtitle': {
    'en': 'Corporate access for guest ride requests and scheduled transfers.',
    'fr':
        'Accès entreprise pour les demandes de trajets invités et les transferts planifiés.',
    'ar': 'دخول الشركات لطلبات رحلات الضيوف والنقل المجدول.',
    'de': 'Firmenzugang für Gästefahrten und geplante Transfers.',
    'es':
        'Acceso corporativo para viajes de invitados y traslados programados.',
    'it': 'Accesso aziendale per corse ospiti e transfer programmati.',
    'zh': '企业入口，用于客人行程请求和预约接送。',
    'ru':
        'Корпоративный доступ для гостевых поездок и трансферов по расписанию.',
  },
  'b2bRideControl': {
    'en': 'B2B RIDE CONTROL',
    'fr': 'CONTRÔLE DES COURSES B2B',
    'ar': 'تحكم رحلات B2B',
    'de': 'B2B-FAHRTSTEUERUNG',
    'es': 'CONTROL DE VIAJES B2B',
    'it': 'CONTROLLO CORSE B2B',
    'zh': 'B2B 行程控制',
    'ru': 'УПРАВЛЕНИЕ B2B-ПОЕЗДКАМИ',
  },
  'heroBody': {
    'en':
        'Create guest rides, schedule pickup times, and track driver assignment in one clear control surface.',
    'fr':
        'Créez des courses invités, planifiez les prises en charge et suivez l’affectation du chauffeur dans une interface claire.',
    'ar':
        'أنشئ رحلات للضيوف، وجدول أوقات الانطلاق، وتابع تعيين السائق من لوحة واحدة واضحة.',
    'de':
        'Erstelle Gästefahrten, plane Abholzeiten und verfolge die Fahrerzuweisung in einer klaren Oberfläche.',
    'es':
        'Crea viajes para invitados, programa recogidas y sigue la asignación del conductor en un panel claro.',
    'it':
        'Crea corse ospiti, programma i ritiri e monitora l’assegnazione dell’autista in un unico pannello.',
    'zh': '创建客人行程、预约接送时间，并在一个清晰界面中跟踪司机分配。',
    'ru':
        'Создавайте гостевые поездки, планируйте подачу и отслеживайте назначение водителя в одном интерфейсе.',
  },
  'portalStatus': {
    'en': 'Portal status',
    'fr': 'État du portail',
    'ar': 'حالة البوابة',
    'de': 'Portalstatus',
    'es': 'Estado del portal',
    'it': 'Stato portale',
    'zh': '门户状态',
    'ru': 'Статус портала',
  },
  'tapAccountDetails': {
    'en': 'Tap to open account details',
    'fr': 'Touchez pour ouvrir les détails du compte',
    'ar': 'اضغط لفتح تفاصيل الحساب',
    'de': 'Tippen, um Kontodetails zu öffnen',
    'es': 'Toca para abrir los detalles de la cuenta',
    'it': 'Tocca per aprire i dettagli account',
    'zh': '点击打开账号详情',
    'ru': 'Нажмите, чтобы открыть данные аккаунта',
  },
  'codeUnavailable': {
    'en': 'Code unavailable',
    'fr': 'Code indisponible',
    'ar': 'الرمز غير متاح',
    'de': 'Code nicht verfügbar',
    'es': 'Código no disponible',
    'it': 'Codice non disponibile',
    'zh': '代码不可用',
    'ru': 'Код недоступен',
  },
  'codeLine': {
    'en': 'Code: {value}',
    'fr': 'Code : {value}',
    'ar': 'الرمز: {value}',
    'de': 'Code: {value}',
    'es': 'Código: {value}',
    'it': 'Codice: {value}',
    'zh': '代码：{value}',
    'ru': 'Код: {value}',
  },
  'namePinLine': {
    'en': 'Name / PIN: {value}',
    'fr': 'Nom / PIN : {value}',
    'ar': 'الاسم / PIN: {value}',
    'de': 'Name / PIN: {value}',
    'es': 'Nombre / PIN: {value}',
    'it': 'Nome / PIN: {value}',
    'zh': '姓名 / PIN：{value}',
    'ru': 'Имя / PIN: {value}',
  },
  'phoneHotelLine': {
    'en': 'Phone / Hotel: {value}',
    'fr': 'Téléphone / Hôtel : {value}',
    'ar': 'الهاتف / الفندق: {value}',
    'de': 'Telefon / Hotel: {value}',
    'es': 'Teléfono / Hotel: {value}',
    'it': 'Telefono / Hotel: {value}',
    'zh': '电话 / 酒店：{value}',
    'ru': 'Телефон / Отель: {value}',
  },
  'guestRequestSubtitle': {
    'en': 'Guest ride request',
    'fr': 'Demande de trajet invité',
    'ar': 'طلب رحلة ضيف',
    'de': 'Gastfahrt anfragen',
    'es': 'Solicitud de viaje de invitado',
    'it': 'Richiesta corsa ospite',
    'zh': '客人行程请求',
    'ru': 'Запрос гостевой поездки',
  },
  'newRideRequest': {
    'en': 'New ride request',
    'fr': 'Nouvelle demande',
    'ar': 'طلب رحلة جديد',
    'de': 'Neue Anfrage',
    'es': 'Nueva solicitud',
    'it': 'Nuova richiesta',
    'zh': '新行程请求',
    'ru': 'Новый запрос',
  },
  'tapOpenForm': {
    'en': 'Tap to open the request form',
    'fr': 'Touchez pour ouvrir le formulaire',
    'ar': 'اضغط لفتح نموذج الطلب',
    'de': 'Tippen, um das Formular zu öffnen',
    'es': 'Toca para abrir el formulario',
    'it': 'Tocca per aprire il modulo',
    'zh': '点击打开请求表单',
    'ru': 'Нажмите, чтобы открыть форму',
  },
  'guestName': {
    'en': 'Guest name',
    'fr': 'Nom du client',
    'ar': 'اسم الضيف',
    'de': 'Name des Gastes',
    'es': 'Nombre del cliente',
    'it': 'Nome ospite',
    'zh': '客人姓名',
    'ru': 'Имя гостя',
  },
  'guestPhone': {
    'en': 'Guest phone',
    'fr': 'Téléphone du client',
    'ar': 'هاتف الضيف',
    'de': 'Telefon des Gastes',
    'es': 'Teléfono del cliente',
    'it': 'Telefono ospite',
    'zh': '客人电话',
    'ru': 'Телефон гостя',
  },
  'hotel': {
    'en': 'Hotel',
    'fr': 'Hôtel',
    'ar': 'الفندق',
    'de': 'Hotel',
    'es': 'Hotel',
    'it': 'Hotel',
    'zh': '酒店',
    'ru': 'Отель',
  },
  'flightEta': {
    'en': 'Flight ETA / Stopover',
    'fr': 'ETA vol / Escale',
    'ar': 'موعد الرحلة / التوقف',
    'de': 'Flug ETA / Zwischenstopp',
    'es': 'ETA vuelo / Escala',
    'it': 'ETA volo / Scalo',
    'zh': '航班到达时间 / 经停',
    'ru': 'ETA рейса / пересадка',
  },
  'roomNumber': {
    'en': 'Room number',
    'fr': 'Numéro de chambre',
    'ar': 'رقم الغرفة',
    'de': 'Zimmernummer',
    'es': 'Número de habitación',
    'it': 'Numero camera',
    'zh': '房间号',
    'ru': 'Номер комнаты',
  },
  'gpsLine': {
    'en': 'GPS: {value}',
    'fr': 'GPS : {value}',
    'ar': 'GPS: {value}',
    'de': 'GPS: {value}',
    'es': 'GPS: {value}',
    'it': 'GPS: {value}',
    'zh': 'GPS：{value}',
    'ru': 'GPS: {value}',
  },
  'nearestZone': {
    'en': 'Nearest zone: {value}',
    'fr': 'Zone la plus proche : {value}',
    'ar': 'أقرب منطقة: {value}',
    'de': 'Nächste Zone: {value}',
    'es': 'Zona más cercana: {value}',
    'it': 'Zona più vicina: {value}',
    'zh': '最近区域：{value}',
    'ru': 'Ближайшая зона: {value}',
  },
  'departureLine': {
    'en': 'Departure: {value}',
    'fr': 'Départ : {value}',
    'ar': 'الانطلاق: {value}',
    'de': 'Abfahrt: {value}',
    'es': 'Salida: {value}',
    'it': 'Partenza: {value}',
    'zh': '出发地：{value}',
    'ru': 'Отправление: {value}',
  },
  'destination': {
    'en': 'Destination',
    'fr': 'Destination',
    'ar': 'الوجهة',
    'de': 'Ziel',
    'es': 'Destino',
    'it': 'Destinazione',
    'zh': '目的地',
    'ru': 'Пункт назначения',
  },
  'scheduledPickup': {
    'en': 'Scheduled ride pickup',
    'fr': 'Prise en charge planifiée',
    'ar': 'موعد انطلاق الرحلة المجدولة',
    'de': 'Geplante Abholung',
    'es': 'Recogida programada',
    'it': 'Ritiro programmato',
    'zh': '预约接送时间',
    'ru': 'Подача по расписанию',
  },
  'chooseDateBeforeBooking': {
    'en': 'Choose date and time before booking',
    'fr': 'Choisissez la date et l’heure avant de réserver',
    'ar': 'اختر التاريخ والوقت قبل الحجز',
    'de': 'Datum und Uhrzeit vor der Buchung wählen',
    'es': 'Elige fecha y hora antes de reservar',
    'it': 'Scegli data e ora prima di prenotare',
    'zh': '预订前请选择日期和时间',
    'ru': 'Выберите дату и время перед бронированием',
  },
  'ridesCount': {
    'en': '{value} rides',
    'fr': '{value} courses',
    'ar': '{value} رحلة',
    'de': '{value} Fahrten',
    'es': '{value} viajes',
    'it': '{value} corse',
    'zh': '{value} 个行程',
    'ru': '{value} поездок',
  },
  'departDestinationLine': {
    'en': 'Depart: {value}',
    'fr': 'Départ : {value}',
    'ar': 'الانطلاق: {value}',
    'de': 'Abfahrt: {value}',
    'es': 'Salida: {value}',
    'it': 'Partenza: {value}',
    'zh': '出发：{value}',
    'ru': 'Отправление: {value}',
  },
  'driverSearching': {
    'en': 'Looking for a driver...',
    'fr': 'Recherche d’un chauffeur...',
    'ar': 'جارٍ البحث عن سائق...',
    'de': 'Fahrer wird gesucht...',
    'es': 'Buscando conductor...',
    'it': 'Ricerca autista...',
    'zh': '正在寻找司机...',
    'ru': 'Ищем водителя...',
  },
  'fillRequiredFields': {
    'en': 'Please fill all required fields.',
    'fr': 'Veuillez remplir tous les champs obligatoires.',
    'ar': 'يرجى ملء كل الحقول المطلوبة.',
    'de': 'Bitte alle Pflichtfelder ausfüllen.',
    'es': 'Completa todos los campos obligatorios.',
    'it': 'Compila tutti i campi obbligatori.',
    'zh': '请填写所有必填字段。',
    'ru': 'Заполните все обязательные поля.',
  },
  'b2bGpsForMapPickupHint': {
    'en': 'Pickup on the next step uses your live GPS and updates automatically.',
    'fr': 'À l’étape suivante, la prise en charge suit votre GPS en direct et se met à jour automatiquement.',
    'ar': 'في الخطوة التالية، يُستخدم موقعك عبر الـGPS مباشرة ويتحدث تلقائياً.',
    'de': 'In der nächsten Abholung nutzt die App dein Live‑GPS und aktualisiert automatisch.',
    'es': 'En el siguiente paso, la recogida usa tu GPS en vivo y se actualiza sola.',
    'it': 'Nel passaggio successivo il ritiro usa il GPS in tempo reale e si aggiorna da solo.',
    'zh': '下一步上车点将使用实时 GPS 并自动更新。',
    'ru': 'На следующем шаге подача по живому GPS и обновляется автоматически.',
  },
  'b2bContinueToMap': {
    'en': 'Continue to map & destination',
    'fr': 'Continuer vers la carte et la destination',
    'ar': 'متابعة إلى الخريطة والوجهة',
    'de': 'Weiter zur Karte & Ziel',
    'es': 'Continuar al mapa y destino',
    'it': 'Continua a mappa e destinazione',
    'zh': '继续前往地图与目的地',
    'ru': 'Далее: карта и пункт назначения',
  },
  'b2bChangeRouteMap': {
    'en': 'Change route on map',
    'fr': 'Modifier l’itinéraire sur la carte',
    'ar': 'تغيير المسار على الخريطة',
    'de': 'Route auf der Karte ändern',
    'es': 'Cambiar ruta en el mapa',
    'it': 'Modifica percorso sulla mappa',
    'zh': '在地图上更改路线',
    'ru': 'Изменить маршрут на карте',
  },
  'b2bRideNowSelected': {
    'en': 'Pickup: as soon as possible',
    'fr': 'Prise en charge : dès que possible',
    'ar': 'الانطلاق: في أقرب وقت',
    'de': 'Abholung: so bald wie möglich',
    'es': 'Recogida: lo antes posible',
    'it': 'Ritiro: appena possibile',
    'zh': '上车：尽快',
    'ru': 'Подача: как можно скорее',
  },
  'b2bCompleteMapFirst': {
    'en': 'Open the map and confirm your route first.',
    'fr': 'Ouvrez la carte et confirmez d’abord votre trajet.',
    'ar': 'افتح الخريطة وأكّد مسارك أولاً.',
    'de': 'Öffne die Karte und bestätige zuerst die Route.',
    'es': 'Abre el mapa y confirma primero la ruta.',
    'it': 'Apri la mappa e conferma prima il percorso.',
    'zh': '请先打开地图并确认路线。',
    'ru': 'Сначала откройте карту и подтвердите маршрут.',
  },
};

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: _C.textSoft, fontSize: 12, fontWeight: FontWeight.w700),
      prefixIcon:
          icon == null ? null : Icon(icon, color: _C.yellowDeep, size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.84),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.9), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _C.neonBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );

class _Module extends StatelessWidget {
  const _Module({required this.child, this.accent = false});
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: accent
                ? [
                    Colors.white.withOpacity(0.96),
                    _C.yellowSoft.withOpacity(0.86)
                  ]
                : [
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0.72)
                  ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: accent
                  ? _C.yellow.withOpacity(0.72)
                  : Colors.white.withOpacity(0.9),
              width: 1.4),
          boxShadow: [
            BoxShadow(
                color: _C.yellowDeep.withOpacity(accent ? 0.18 : 0.10),
                blurRadius: accent ? 36 : 28,
                offset: const Offset(0, 16)),
            BoxShadow(
                color: Colors.white.withOpacity(0.65),
                blurRadius: 0,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );
}

Widget _rowInfoCard({
  required IconData icon,
  required Widget content,
  Widget? trailing,
  Color iconBg = _C.surfaceAlt,
  Color iconColor = _C.charcoal,
}) =>
    AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.94),
          _C.yellowSoft.withOpacity(0.28),
          _C.surfaceAlt.withOpacity(0.76)
        ]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.92), width: 1.1),
        boxShadow: [
          BoxShadow(
              color: _C.yellowDeep.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconBg, Colors.white.withOpacity(0.86)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );

Widget _metricPill(IconData icon, String label, Color accent) =>
    AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.92),
            _C.yellowSoft.withOpacity(0.62)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.yellow.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: _C.yellowDeep.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.charcoal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                    color: _C.yellow, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _C.textStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            const TextStyle(color: _C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Corporate portal: login matches API; booking is UI-only until B2B billing API exists.
class B2bScreen extends StatefulWidget {
  const B2bScreen({super.key, this.initialSession});
  final LoginResponse? initialSession;

  @override
  State<B2bScreen> createState() => _B2bScreenState();
}

class _B2bScreenState extends State<B2bScreen> {
  final _api = TaxiAppService();
  final _socket = ChatSocketService();
  final _secretController = TextEditingController();
  final _guestController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _destinationController = TextEditingController();
  final _destinationFocus = FocusNode();
  final _hotelController = TextEditingController();
  final _flightEtaController = TextEditingController();
  final _roomController = TextEditingController();
  Map<String, double> _fares = {};
  String? _routeKey;
  double? _fareQuoteFromMap;
  String? _fareQuoteRouteKey;
  bool _b2bTripConfiguredViaMap = false;
  bool _b2bScheduleLaterFromMap = false;
  CorporateReservationMapResult? _b2bLastMapResult;
  String? _locationText;
  String? _locationError;
  bool _locating = false;
  String? _nearestZoneName;
  double? _nearestZoneDistanceKm;
  String? _token;
  String? _appToken;
  int? _userId;
  List<Ride> _rides = [];
  final List<AppNotification> _notifications = [];
  final Map<int, int> _unreadChatByRideId = {};
  final Map<int, int> _rideIdByConversationId = {};
  final Map<int, int> _conversationIdByRideId = {};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  final Map<String, ImageProvider<Object>?> _photoProviderCache =
      <String, ImageProvider<Object>?>{};
  final Set<int> _ratedRideIds = <int>{};
  final Map<int, int> _ratingByRideId = <int, int>{};
  int? _activeChatRideId;
  int? _pendingRatingRideId;
  Timer? _pollingTimer;
  String? _message;
  bool _busy = false;
  bool _obscureSecret = true;
  bool _ok = false;
  bool _requestFormExpanded = false;
  DateTime? _scheduledPickupAt;
  _B2bRideFilter _rideFilter = _B2bRideFilter.all;
  String _b2bDisplayName = 'B2B account';
  String _b2bEmail = '';
  String _b2bPhone = '';
  String _b2bCode = '';
  String _b2bLabel = '';
  String _b2bContactName = '';
  String _b2bPin = '';
  String _b2bHotel = '';
  String _b2bTenantPhone = '';

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;
  int _rideUnread(int rideId) => _unreadChatByRideId[rideId] ?? 0;
  Future<void> _goToHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Widget _appBarHomeLogo() => GestureDetector(
        onTap: () => unawaited(_goToHome()),
        child: const VoomLogo(height: 30),
      );

  Map<String, dynamic> _decodeJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const <String, dynamic>{};
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  void _hydrateB2bProfileFromToken(String? token) {
    if ((token ?? '').trim().isEmpty) return;
    final claims = _decodeJwtClaims(token!);
    final email = (claims['email'] ?? claims['sub'] ?? '').toString().trim();
    final name =
        (claims['display_name'] ?? claims['name'] ?? '').toString().trim();
    final phone = (claims['phone'] ?? '').toString().trim();
    final code =
        (claims['source_code'] ?? claims['code'] ?? '').toString().trim();
    if (!mounted) return;
    setState(() {
      if (name.isNotEmpty) _b2bDisplayName = name;
      if (email.isNotEmpty) _b2bEmail = email;
      if (phone.isNotEmpty) _b2bPhone = phone;
      if (code.isNotEmpty) _b2bCode = code;
      if (_b2bDisplayName.trim().isEmpty) {
        _b2bDisplayName =
            _b2bEmail.isNotEmpty ? _b2bEmail : 'B2B #${_userId ?? ''}';
      }
    });
  }

  Future<void> _hydrateB2bProfileFromApi(String token) async {
    try {
      final data = await _api.getB2bMe(token);
      if (!mounted) return;
      final user =
          Map<String, dynamic>.from((data['user'] as Map?) ?? const {});
      final tenant =
          Map<String, dynamic>.from((data['tenant'] as Map?) ?? const {});
      final display = (user['display_name'] ?? '').toString().trim();
      final email = (user['email'] ?? '').toString().trim();
      final phone = (user['phone'] ?? '').toString().trim();
      final code = (user['source_code'] ?? '').toString().trim();
      final tenantName = (tenant['contact_name'] ?? '').toString().trim();
      final tenantLabel = (tenant['label'] ?? '').toString().trim();
      final tenantPin = (tenant['pin'] ?? '').toString().trim();
      final tenantHotel = (tenant['hotel'] ?? '').toString().trim();
      final tenantPhone = (tenant['phone'] ?? '').toString().trim();
      if (!mounted) return;
      setState(() {
        if (display.isNotEmpty) _b2bDisplayName = display;
        if (_b2bDisplayName == 'B2B account' && tenantName.isNotEmpty) {
          _b2bDisplayName = tenantName;
        }
        if (email.isNotEmpty) _b2bEmail = email;
        if (phone.isNotEmpty) _b2bPhone = phone;
        if (code.isNotEmpty) _b2bCode = code;
        if (tenantLabel.isNotEmpty) _b2bLabel = tenantLabel;
        if (tenantName.isNotEmpty) _b2bContactName = tenantName;
        if (tenantPin.isNotEmpty) _b2bPin = tenantPin;
        if (tenantHotel.isNotEmpty) _b2bHotel = tenantHotel;
        if (tenantPhone.isNotEmpty) _b2bTenantPhone = tenantPhone;
      });
    } catch (_) {}
  }

  String _uiText({
    required String en,
    required String ar,
    required String fr,
    required String es,
    required String de,
    required String it,
    required String ru,
    required String zh,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('fr')) return fr;
    if (code.startsWith('es')) return es;
    if (code.startsWith('de')) return de;
    if (code.startsWith('it')) return it;
    if (code.startsWith('ru')) return ru;
    if (code.startsWith('zh')) return zh;
    return en;
  }

  String _tx(String key, [Object? value]) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    final table = _b2bUiTranslations[key] ?? kB2bCorporateMapUiTranslations[key];
    return (table?[code] ?? table?['en'] ?? key)
        .replaceAll('{value}', '${value ?? ''}');
  }

  static String _formatSchedule(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pickScheduledPickup() async {
    final now = DateTime.now();
    final initial = _scheduledPickupAt ?? now.add(const Duration(hours: 12));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      _scheduledPickupAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _reservationStatusText(Ride ride) {
    final status = (ride.reservationStatus ?? '').trim();
    if (status == 'reserved') return _tx('driverReserved');
    if (status == 'cancelled') return _tx('reservationCancelled');
    if (status == 'completed') return _tx('completed');
    return ride.driverId == null ? _tx('searching') : _tx('upcomingRide');
  }

  String _scheduleCountdown(Ride ride) {
    final raw = ride.scheduledPickupAt;
    final dt = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return _tx('scheduled');
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return _tx('pickupWindowOpen');
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes.clamp(0, 59)}m';
  }

  static const Set<String> _airportZones = {
    'مطار قرطاج',
    'مطار النفيضة',
    'مطار المنستير',
  };

  bool _isAirport(String zone) => _airportZones.contains(zone.trim());

  static const Map<String, _ZoneCoord> _zoneCoords = {
    'مطار قرطاج': _ZoneCoord(36.8508, 10.2272),
    'مطار النفيضة': _ZoneCoord(36.0758, 10.4386),
    'مطار المنستير': _ZoneCoord(35.7581, 10.7547),
    'وسط سوسة': _ZoneCoord(35.8256, 10.63699),
    'الحمامات': _ZoneCoord(36.4000, 10.6167),
    'نابل': _ZoneCoord(36.4561, 10.7376),
    'القنطاوي': _ZoneCoord(35.8920, 10.5950),
    'Sidi Bou Saïd': _ZoneCoord(36.8710, 10.3470),
    'La Marsa': _ZoneCoord(36.8780, 10.3240),
    'Gammarth': _ZoneCoord(36.9170, 10.2870),
    'Carthage': _ZoneCoord(36.8520, 10.3230),
    'Musée du Bardo': _ZoneCoord(36.8100, 10.1400),
    'Médina de Tunis': _ZoneCoord(36.8000, 10.1700),
    'Byrsa Hill': _ZoneCoord(36.8527, 10.3295),
    'Lac de Tunis': _ZoneCoord(36.8400, 10.2400),
    'Geant': _ZoneCoord(36.8420, 10.2860),
    'Azur city': _ZoneCoord(36.7410, 10.2150),
    'tunisia mall': _ZoneCoord(36.8430, 10.2810),
    'Nabeul': _ZoneCoord(36.4510, 10.7360),
    'Hammamet': _ZoneCoord(36.4000, 10.6160),
    'Yasmine Hammamet': _ZoneCoord(36.3650, 10.5360),
    'Friguia Park': _ZoneCoord(36.1240, 10.4410),
    'Hergla park': _ZoneCoord(36.0270, 10.5090),
    'mall of sousse': _ZoneCoord(35.8290, 10.6350),
    'Skanes': _ZoneCoord(35.7650, 10.8100),
    'Marina de Monastir': _ZoneCoord(35.7770, 10.8260),
    'mahdia': _ZoneCoord(35.5050, 11.0630),
    'Skifa el Kahla': _ZoneCoord(35.5057, 11.0620),
    'Borj el Kebir': _ZoneCoord(35.5030, 11.0610),
  };

  ({String? zone, double? distanceMeters}) _nearestZoneFor(
      double lat, double lng) {
    String? bestZone;
    double? bestDist;
    for (final e in _zoneCoords.entries) {
      final d = Geolocator.distanceBetween(lat, lng, e.value.lat, e.value.lng);
      if (bestDist == null || d < bestDist) {
        bestDist = d;
        bestZone = e.key;
      }
    }
    return (zone: bestZone, distanceMeters: bestDist);
  }

  Color _distanceColor(double km) {
    if (km < 3.0) return Colors.green;
    if (km <= 10.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _detectB2bLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = l10n.passengerLocationServiceDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = l10n.passengerLocationPermissionDenied);
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nearest = _nearestZoneFor(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() {
        _locationText =
            '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
        _nearestZoneDistanceKm = nearest.distanceMeters == null
            ? null
            : nearest.distanceMeters! / 1000.0;
        _nearestZoneName = nearest.zone;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<String> _filteredRouteKeys() {
    final all = _fares.keys.toList();
    final filtered = all.where((k) {
      final parts = k.split(airportRouteKeySeparator);
      if (parts.length < 2) return false;
      final start = parts.first.trim();
      final preferredStart = (_nearestZoneName ?? '').trim();
      if (preferredStart.isNotEmpty) return start == preferredStart;
      return true;
    }).toList();
    if (filtered.isEmpty) return all..sort((a, b) => a.compareTo(b));
    filtered.sort((a, b) => a.compareTo(b));
    return filtered;
  }

  void _pruneInvalidRouteSelection() {
    final keys = _filteredRouteKeys();
    if (keys.isEmpty) {
      _routeKey = null;
      _destinationController.clear();
      _fareQuoteFromMap = null;
      _fareQuoteRouteKey = null;
      return;
    }
    if (_routeKey != null && !keys.contains(_routeKey)) {
      _routeKey = null;
      _destinationController.clear();
      _fareQuoteFromMap = null;
      _fareQuoteRouteKey = null;
    }
  }

  List<String> _catalogDestinationsForOrigin(String origin) {
    final o = origin.trim();
    if (o.isEmpty) return const [];
    final out = <String>{};
    for (final k in _fares.keys) {
      final parts = k.split(airportRouteKeySeparator);
      if (parts.length >= 2 && parts.first.trim() == o) {
        out.add(parts[1].trim());
      }
    }
    return out.toList();
  }

  String? _nearestCatalogDestinationForLatLng(LatLng p, String origin) {
    final candidates = _catalogDestinationsForOrigin(origin);
    if (candidates.isEmpty) return null;
    String? best;
    var bestM = double.infinity;
    for (final d in candidates) {
      final c = TunisiaZoneCoordinates.lookup(d);
      if (c == null) continue;
      final m = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        c.latitude,
        c.longitude,
      );
      if (m < bestM) {
        bestM = m;
        best = d;
      }
    }
    if (best == null || bestM > 120000) return null;
    return best;
  }

  String? _routeKeyForRestaurantByName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    TunisiaTouristRestaurant? hit;
    for (final r in TunisiaTouristRestaurants.all) {
      if (r.name.trim() == t) {
        hit = r;
        break;
      }
    }
    if (hit == null) return null;
    final origin = (_nearestZoneName ?? '').trim();
    if (origin.isEmpty) return null;
    final near = _nearestCatalogDestinationForLatLng(hit.position, origin);
    if (near == null) return null;
    for (final k in _fares.keys) {
      final p = k.split(airportRouteKeySeparator);
      if (p.length >= 2 &&
          p.first.trim() == origin &&
          p[1].trim() == near) {
        return k;
      }
    }
    return null;
  }

  String? _resolveAnyRouteForDestinationText(String display) {
    return _resolveRouteFromDestination(display) ??
        _routeKeyForRestaurantByName(display);
  }

  String _destinationListTitle(AppLocalizations l, String s) {
    for (final r in TunisiaTouristRestaurants.all) {
      if (r.name == s) return r.name;
    }
    return localizedPlaceName(l, s);
  }

  Future<void> _continueToB2bCorporateMap() async {
    final guest = _guestController.text.trim();
    final room = _roomController.text.trim();
    if (guest.isEmpty || room.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tx('fillRequiredFields'))),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await _detectB2bLocation();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    setState(() {
      _b2bTripConfiguredViaMap = false;
      _b2bScheduleLaterFromMap = false;
      _b2bLastMapResult = null;
      _destinationController.clear();
      _routeKey = null;
      _fareQuoteFromMap = null;
      _fareQuoteRouteKey = null;
      _scheduledPickupAt = null;
    });
    await _openCorporateReservationMap();
  }

  Future<void> _openCorporateReservationMap() async {
    final l = AppLocalizations.of(context)!;
    final allKeys = _fares.keys.toList()
      ..sort(
        (a, b) => localizedRouteKeyForDisplay(l, a)
            .compareTo(localizedRouteKeyForDisplay(l, b)),
      );
    if (allKeys.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tx('noRoutesFromYourArea'))),
        );
      }
      return;
    }
    final preferred = (_nearestZoneName ?? '').trim();
    var initial = preferred;
    if (initial.isEmpty ||
        !allKeys.any(
          (k) =>
              k.split(airportRouteKeySeparator).first.trim() == initial,
        )) {
      initial =
          allKeys.first.split(airportRouteKeySeparator).first.trim();
    }
    LatLng? passengerGps;
    final loc = _locationText;
    if (loc != null) {
      final parts = loc.split(',');
      if (parts.length == 2) {
        final la = double.tryParse(parts[0].trim());
        final ln = double.tryParse(parts[1].trim());
        if (la != null && ln != null) {
          passengerGps = LatLng(la, ln);
        }
      }
    }
    if (!mounted) return;
    final result = await Navigator.of(context)
        .push<CorporateReservationMapResult>(
      MaterialPageRoute(
        builder: (ctx) => CorporateReservationMapScreen(
          api: _api,
          l: l,
          allRouteKeys: allKeys,
          fares: _fares,
          initialPickupZone: initial,
          passengerGps: passengerGps,
          tx: _tx,
          formatScheduledDateTime: _formatSchedule,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final destLabel = (result.destinationDisplayName ?? '').trim().isNotEmpty
        ? result.destinationDisplayName!.trim()
        : result.routeKey.split(airportRouteKeySeparator).last.trim();
    setState(() {
      _routeKey = result.routeKey;
      _destinationController.text = destLabel;
      _fareQuoteFromMap = result.finalFare;
      _fareQuoteRouteKey = result.routeKey;
      _b2bLastMapResult = result;
      _b2bTripConfiguredViaMap = true;
      _b2bScheduleLaterFromMap = result.scheduleLater;
      if (result.scheduleLater && result.scheduledPickupAt != null) {
        _scheduledPickupAt = result.scheduledPickupAt;
      } else {
        _scheduledPickupAt = null;
      }
    });
  }

  List<String> _destinationChoices() {
    final set = <String>{};
    for (final key in _fares.keys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.length < 2) continue;
      final dest = parts[1].trim();
      if (dest.isNotEmpty) set.add(dest);
    }
    final l = AppLocalizations.of(context)!;
    final list = set.toList()
      ..sort((a, b) =>
          localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
    return list;
  }

  List<String> _destinationSuggestions() {
    final query = _destinationController.text.trim().toLowerCase();
    final base = _destinationChoices();
    final l = AppLocalizations.of(context)!;
    final restNames = TunisiaTouristRestaurants.all
        .where((r) =>
            query.isEmpty ||
            r.name.toLowerCase().contains(query) ||
            r.id.toLowerCase().contains(query))
        .map((r) => r.name)
        .toList();
    final merged = <String>{...base, ...restNames};
    final list = merged.toList();
    String sortLabel(String v) {
      for (final r in TunisiaTouristRestaurants.all) {
        if (r.name == v) return r.name;
      }
      return localizedPlaceName(l, v);
    }

    if (query.isEmpty) {
      list.sort((a, b) => sortLabel(a).compareTo(sortLabel(b)));
      return list.take(14).toList();
    }
    list.retainWhere((d) {
      if (d.toLowerCase().contains(query)) return true;
      return localizedPlaceName(l, d).toLowerCase().contains(query);
    });
    list.sort((a, b) => sortLabel(a).compareTo(sortLabel(b)));
    return list.take(14).toList();
  }

  String? _resolveRouteFromDestination(String destination) {
    final target = destination.trim().toLowerCase();
    if (target.isEmpty) return null;
    final keys = _fares.keys.toList();
    if (keys.isEmpty) return null;
    final preferredStart = (_nearestZoneName ?? '').trim().toLowerCase();
    final exact = keys.where((k) {
      final parts = k.split(airportRouteKeySeparator);
      return parts.length >= 2 && parts[1].trim().toLowerCase() == target;
    }).toList();
    if (exact.isNotEmpty) {
      if (preferredStart.isNotEmpty) {
        final preferred = exact.where((k) {
          final parts = k.split(airportRouteKeySeparator);
          return parts.isNotEmpty &&
              parts.first.trim().toLowerCase() == preferredStart;
        }).toList();
        if (preferred.isNotEmpty) return preferred.first;
      }
      exact.sort((a, b) => a.compareTo(b));
      return exact.first;
    }
    final fuzzy = keys.where((k) {
      final parts = k.split(airportRouteKeySeparator);
      return parts.length >= 2 &&
          parts[1].trim().toLowerCase().contains(target);
    }).toList();
    if (fuzzy.isNotEmpty) {
      if (preferredStart.isNotEmpty) {
        final preferred = fuzzy.where((k) {
          final parts = k.split(airportRouteKeySeparator);
          return parts.isNotEmpty &&
              parts.first.trim().toLowerCase() == preferredStart;
        }).toList();
        if (preferred.isNotEmpty) return preferred.first;
      }
      fuzzy.sort((a, b) => a.compareTo(b));
      return fuzzy.first;
    }
    return null;
  }

  double? _routeDistanceKm(String? routeKey) {
    if ((routeKey ?? '').trim().isEmpty) return null;
    final parts = routeKey!.split(airportRouteKeySeparator);
    if (parts.length < 2) return null;
    final start = _zoneCoords[parts.first.trim()];
    final dest = _zoneCoords[parts[1].trim()];
    if (start == null || dest == null) return null;
    final m =
        Geolocator.distanceBetween(start.lat, start.lng, dest.lat, dest.lng);
    return m / 1000.0;
  }

  String _normPlace(String s) => s.trim().toLowerCase();

  double _fareForRouteKey(String? routeKey) {
    final key = (routeKey ?? '').trim();
    if (key.isEmpty) return 0.0;
    final exact = _fares[key];
    if (exact != null) return exact.toDouble();
    final parts = key.split(airportRouteKeySeparator);
    if (parts.length < 2) return 0.0;
    final s = _normPlace(parts.first);
    final d = _normPlace(parts[1]);
    for (final e in _fares.entries) {
      final p = e.key.split(airportRouteKeySeparator);
      if (p.length < 2) continue;
      if (_normPlace(p.first) == s && _normPlace(p[1]) == d) {
        return e.value.toDouble();
      }
    }
    return 0.0;
  }

  Widget _statusFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? _C.charcoal : _C.textMid,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      selectedColor: _C.yellowSoft,
      backgroundColor: _C.surfaceAlt,
      side: BorderSide(color: selected ? _C.yellowDeep : _C.border),
    );
  }

  Future<void> _showB2bAccountDialog() async {
    final token = _token;
    if (token == null) return;
    final displayNameCtrl = TextEditingController(text: _b2bDisplayName);
    final emailCtrl = TextEditingController(text: _b2bEmail);
    final phoneCtrl = TextEditingController(text: _b2bPhone);
    final newPasswordCtrl = TextEditingController();
    var obscureNext = true;
    String? error;
    var localBusy = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(_tx('editB2bAccount')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd(AppLocalizations.of(context)!.emailLabel,
                      icon: Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: obscureNext,
                  decoration: _fd(_tx('newPasswordOptional'),
                          icon: Icons.password_rounded)
                      .copyWith(
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setLocal(() => obscureNext = !obscureNext),
                      icon: Icon(obscureNext
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: displayNameCtrl,
                  decoration:
                      _fd(_tx('name'), icon: Icons.person_outline_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fd(_tx('phone'), icon: Icons.phone_outlined),
                ),
                if ((error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(color: _C.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: localBusy ? null : () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.genericCancel)),
            FilledButton(
              onPressed: localBusy
                  ? null
                  : () async {
                      setLocal(() {
                        localBusy = true;
                        error = null;
                      });
                      try {
                        final result = await _api.patchB2bMe(
                          token: token,
                          displayName: displayNameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: newPasswordCtrl.text.trim().isEmpty
                              ? null
                              : newPasswordCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        final user = Map<String, dynamic>.from(
                            (result['user'] as Map?) ?? const {});
                        final tenant = Map<String, dynamic>.from(
                            (result['tenant'] as Map?) ?? const {});
                        setState(() {
                          _b2bEmail = (user['email'] ?? _b2bEmail).toString();
                          _b2bPhone = (user['phone'] ?? _b2bPhone).toString();
                          final dn =
                              (user['display_name'] ?? '').toString().trim();
                          if (dn.isNotEmpty) _b2bDisplayName = dn;
                          final sc =
                              (user['source_code'] ?? '').toString().trim();
                          if (sc.isNotEmpty) _b2bCode = sc;
                          _b2bLabel = (tenant['label'] ?? _b2bLabel).toString();
                          _b2bContactName =
                              (tenant['contact_name'] ?? _b2bContactName)
                                  .toString();
                          _b2bPin = (tenant['pin'] ?? _b2bPin).toString();
                          _b2bTenantPhone =
                              (tenant['phone'] ?? _b2bTenantPhone).toString();
                          _b2bHotel = (tenant['hotel'] ?? _b2bHotel).toString();
                        });
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setLocal(() {
                          error = e.toString();
                          localBusy = false;
                        });
                      }
                    },
              child: Text(_tx('save')),
            ),
          ],
        ),
      ),
    );
    displayNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    newPasswordCtrl.dispose();
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tx('accountUpdated'))),
      );
    }
  }

  void _recomputePendingRatingFromRides() {
    int? nextRatingRideId;
    for (final r in _rides) {
      if (r.status == 'completed' &&
          r.isRated != true &&
          !_ratedRideIds.contains(r.id)) {
        nextRatingRideId = r.id;
        break;
      }
    }
    _pendingRatingRideId = nextRatingRideId;
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth =
          await _api.login(role: 'b2b', secret: _secretController.text.trim());
      if (userChoseLocaleThisSession.value) {
        try {
          await _api.patchPreferredLanguage(
            token: auth.appAccessToken ?? auth.accessToken,
            preferredLanguage: appLocale.value.languageCode,
          );
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.b2b);
      await SessionStore.saveB2b(auth);
      final fares = await _api.getAirportFares();
      _token = auth.accessToken;
      _appToken = auth.appAccessToken ?? auth.accessToken;
      _userId = auth.userId;
      final entered = _secretController.text.trim();
      if (entered.isNotEmpty) {
        _b2bCode = entered;
        if (_b2bDisplayName.trim().isEmpty ||
            _b2bDisplayName == 'B2B account') {
          _b2bDisplayName = entered;
        }
      }
      if (_appToken != null) {
        _unreadChatByRideId.clear();
        _rideIdByConversationId.clear();
        _conversationIdByRideId.clear();
        _lastSeenMessageIdByConversationId.clear();
        _connectRealtime(_appToken!);
        await _refreshRides();
        _startPolling();
        await _hydrateB2bProfileFromApi(_appToken!);
      }
      setState(() {
        _ok = true;
        _fares = fares;
        _pruneInvalidRouteSelection();
        if (_b2bCode.isEmpty) _b2bCode = _secretController.text.trim();
      });
      _hydrateB2bProfileFromToken(_appToken ?? _token);
      if ((_appToken ?? _token) != null) {
        await _hydrateB2bProfileFromApi((_appToken ?? _token)!);
      }
      await _detectB2bLocation();
    } catch (e) {
      setState(() {
        _ok = false;
        _message = e.toString();
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _bookGuest() async {
    final l = AppLocalizations.of(context)!;
    final guest = _guestController.text.trim();
    final destination = _destinationController.text.trim();
    final route = _resolveAnyRouteForDestinationText(destination) ?? _routeKey;
    final token = _token;
    if (token == null) {
      setState(() => _message = l.loginFirst);
      return;
    }
    if (guest.isEmpty || destination.isEmpty || route == null) {
      setState(() => _message = _tx('fillRequiredFields'));
      return;
    }
    DateTime? scheduledForApi;
    if (isGoogleMapsPlatformSupported) {
      if (!_b2bTripConfiguredViaMap) {
        setState(() => _message = _tx('b2bCompleteMapFirst'));
        return;
      }
      scheduledForApi =
          _b2bScheduleLaterFromMap ? _scheduledPickupAt : null;
      if (_b2bScheduleLaterFromMap && scheduledForApi == null) {
        setState(() => _message = _tx('fillRequiredFields'));
        return;
      }
    } else {
      if (_scheduledPickupAt == null) {
        setState(() => _message = _tx('fillRequiredFields'));
        return;
      }
      scheduledForApi = _scheduledPickupAt;
    }
    final room = _roomController.text.trim();
    final guestPhone = _guestPhoneController.text.trim();
    final hotel = _hotelController.text.trim();
    final flightEta = _flightEtaController.text.trim();
    final mapSnap = _b2bLastMapResult;
    if (isGoogleMapsPlatformSupported &&
        (mapSnap == null || mapSnap.routeKey != route)) {
      setState(() => _message = _tx('b2bCompleteMapFirst'));
      return;
    }
    final fare = mapSnap?.finalFare ?? _fareQuoteFromMap;
    if (fare == null || fare <= 0) {
      setState(() => _message = _tx('fillRequiredFields'));
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final booking = await _api.createB2bBooking(
        token: token,
        route: route,
        guestName: guest,
        guestPhone: guestPhone,
        hotelName: hotel,
        flightEta: flightEta,
        roomNumber: room,
        fare: fare,
        sourceCode:
            (_b2bCode.isNotEmpty ? _b2bCode : _secretController.text.trim()),
        scheduledPickupAt: scheduledForApi,
        pickupAddress: mapSnap?.pickupAddress,
        pickupDisplayName: mapSnap?.pickupDisplayName,
        destinationAddress: mapSnap?.destinationAddress,
        destinationDisplayName: mapSnap?.destinationDisplayName,
        pickupLat: mapSnap?.pickupLat,
        pickupLng: mapSnap?.pickupLng,
        destinationLat: mapSnap?.destinationLat,
        destinationLng: mapSnap?.destinationLng,
        quotedDistanceKm: mapSnap?.quotedDistanceKm,
        quotedDurationSeconds: mapSnap?.quotedDurationSeconds,
        quotedFareDt: fare,
        quotedBaseFareDt: mapSnap?.quotedBaseFareDt,
        quotedNightSurchargeDt: mapSnap?.quotedNightSurchargeDt,
        quotedIsNight: mapSnap?.quotedIsNight,
      );
      if (!mounted) return;
      _refreshRides();
      setState(() {
        _busy = false;
        _scheduledPickupAt = null;
        _b2bTripConfiguredViaMap = false;
        _b2bScheduleLaterFromMap = false;
        _b2bLastMapResult = null;
        _message = l.b2bBookingSuccessMessage(
          l.requestRideButton,
          booking['id'] as Object,
          guest,
          localizedRouteKeyForDisplay(l, route),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString();
      });
    }
  }

  void _connectRealtime(String token) {
    final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
    final isWebLocal = kIsWeb &&
        (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
    // On Flutter Web local, socket_io_common polling can throw decode RangeError.
    // Keep chat/notification via HTTP fallback polling instead.
    if (isWebLocal) {
      return;
    }
    _socket.connect(
      token,
      onRideStatus: (data) {
        final rideMap = data['ride'];
        if (rideMap is! Map || !mounted) return;
        final ride = Ride.fromJson(Map<String, dynamic>.from(rideMap));
        setState(() {
          final idx = _rides.indexWhere((r) => r.id == ride.id);
          if (idx >= 0) {
            _rides[idx] = ride;
          } else {
            _rides.insert(0, ride);
          }
          _recomputePendingRatingFromRides();
        });
        final l = AppLocalizations.of(context)!;
        final msg = (data['message'] ?? '').toString();
        _pushNotification(
          title: l.notificationRideUpdateTitle,
          body: msg.isEmpty ? l.notificationRideUpdatedBody(ride.id) : msg,
          rideId: ride.id,
          event: (data['event'] ?? '').toString(),
        );
      },
      onReceiveMessage: (dynamic data) {
        dynamic raw = data;
        if (data is List && data.isNotEmpty) raw = data.first;
        if (raw is! Map) return;
        unawaited(
          _handleB2bSocketChat(Map<String, dynamic>.from(raw as Map)),
        );
      },
    );
  }

  Future<int?> _resolveB2bRideIdForConversation(int conversationId) async {
    final t = _appToken;
    if (t == null) return null;
    final cached = _rideIdByConversationId[conversationId];
    if (cached != null) return cached;
    for (final ride in _rides) {
      if (!rideMayHaveConversation(ride.status)) continue;
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
        if (info.conversationId == conversationId) return ride.id;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _handleB2bSocketChat(Map<String, dynamic> data) async {
    if (!mounted) return;
    final uid = _userId;
    if (uid == null) return;
    late final ChatMessage msg;
    try {
      msg = ChatMessage.fromJson(data);
    } catch (_) {
      return;
    }
    if (msg.senderUserId == uid) return;

    final convId = intFromDynamic(data['conversation_id']);
    var rideId = intFromDynamic(data['ride_id']);
    if (rideId == null && convId != null) {
      rideId = _rideIdByConversationId[convId];
    }
    if (rideId == null && convId != null) {
      rideId = await _resolveB2bRideIdForConversation(convId);
    }
    if (rideId == null && convId != null) {
      await _refreshRides();
      if (!mounted) return;
      rideId = _rideIdByConversationId[convId] ??
          await _resolveB2bRideIdForConversation(convId);
    }

    if (!mounted) return;
    if (rideId == null) return;
    final int rid = rideId;

    if (convId != null) {
      final prev = _lastSeenMessageIdByConversationId[convId] ?? 0;
      if (msg.id > prev) _lastSeenMessageIdByConversationId[convId] = msg.id;
      _rideIdByConversationId[convId] = rid;
      _conversationIdByRideId[rid] = convId;
    }

    if (_activeChatRideId == rid) return;

    final l = AppLocalizations.of(context)!;
    final body =
        msg.displayText.trim().isEmpty ? l.openChatButton : msg.displayText;
    final senderName = (msg.senderName ?? '').trim();
    final title = senderName.isEmpty
        ? l.openChatButton
        : '${l.openChatButton} • $senderName';

    setState(() {
      _unreadChatByRideId[rid] = (_unreadChatByRideId[rid] ?? 0) + 1;
    });
    LocalNotificationService.instance
        .show(title: title, body: body, isChat: true);
    _pushNotification(
      title: title,
      body: body,
      event: 'chat_message',
      rideId: rid,
    );
  }

  Future<void> _refreshRides() async {
    final t = _appToken ?? _token;
    if (t == null) return;
    try {
      final list = await _api.listRides(t);
      if (!mounted) return;
      setState(() {
        _rides = list;
        _recomputePendingRatingFromRides();
      });
      for (final r in list) {
        if (!rideMayHaveConversation(r.status)) continue;
        try {
          final info = await _api.getRideConversation(token: t, rideId: r.id);
          if (info == null) continue;
          _rideIdByConversationId[info.conversationId] = r.id;
          _conversationIdByRideId[r.id] = info.conversationId;
          _lastSeenMessageIdByConversationId.putIfAbsent(
              info.conversationId, () => 0);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    Future<void> tick() async {
      if (!mounted || !_ok || _appToken == null) return;
      if (!_busy) await _refreshRides();
      if (!mounted || _appToken == null) return;
      await _pollChatUnreadFallback();
    }

    unawaited(tick());
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => unawaited(tick()));
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _appToken;
    final uid = _userId;
    if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    for (final ride in _rides.where((r) => rideMayHaveConversation(r.status))) {
      if (_activeChatRideId == ride.id) continue;
      try {
        final conversationId = await cachedOrFetchConversationId(
          api: _api,
          token: t,
          rideId: ride.id,
          conversationIdByRideId: _conversationIdByRideId,
          rideIdByConversationId: _rideIdByConversationId,
        );
        if (conversationId == null) continue;
        _lastSeenMessageIdByConversationId.putIfAbsent(conversationId, () => 0);
        final msgs = await _api.listConversationMessages(
          token: t,
          conversationId: conversationId,
          limit: 20,
        );
        if (msgs.isEmpty) continue;
        final stored = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
        final delta = computeUnreadChatDelta(
            msgs: msgs, myUserId: uid, storedWatermark: stored);
        _lastSeenMessageIdByConversationId[conversationId] = delta.newWatermark;
        if (delta.incomingCount > 0) {
          if (!mounted) return;
          final int rid = ride.id;
          setState(() {
            _unreadChatByRideId[rid] =
                (_unreadChatByRideId[rid] ?? 0) + delta.incomingCount;
          });
          final latestIncoming = delta.latestIncoming;
          final body = (latestIncoming?.displayText.trim().isNotEmpty ?? false)
              ? latestIncoming!.displayText
              : l.openChatButton;
          final senderName = (latestIncoming?.senderName ?? '').trim();
          final title = senderName.isEmpty
              ? l.openChatButton
              : '${l.openChatButton} • $senderName';
          _pushNotification(
            title: title,
            body: body,
            event: 'chat_message_fallback',
            rideId: rid,
          );
          LocalNotificationService.instance
              .show(title: title, body: body, isChat: true);
        }
      } catch (_) {}
    }
  }

  void _pushNotification({
    required String title,
    required String body,
    String? event,
    int? rideId,
  }) {
    final now = DateTime.now();
    setState(() {
      _notifications.insert(
        0,
        AppNotification(
          id: '${now.microsecondsSinceEpoch}-${event ?? 'manual'}-${rideId ?? 0}',
          title: title,
          body: body,
          event: event,
          rideId: rideId,
          createdAt: now,
        ),
      );
      if (_notifications.length > 60) {
        _notifications.removeRange(60, _notifications.length);
      }
    });
  }

  void _showNotifications() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: _notifications.isEmpty
            ? SizedBox(
                height: 180, child: Center(child: Text(l.notificationsEmpty)))
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, i) {
                  final n = _notifications[i];
                  return ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.body),
                    onTap: () => setState(() => n.isRead = true),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _cancelRide(Ride ride) async {
    final t = _appToken;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.cancelRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _primeReadWatermarkAfterChat({
    required String token,
    required int conversationId,
    required int rideId,
  }) async {
    try {
      final msgs = await _api.listConversationMessages(
        token: token,
        conversationId: conversationId,
        limit: 150,
      );
      if (!mounted) return;
      final maxId = maxChatMessageId(msgs);
      setState(() {
        _lastSeenMessageIdByConversationId[conversationId] = maxId;
        _unreadChatByRideId.remove(rideId);
      });
    } catch (_) {}
  }

  Future<void> _openChat(Ride ride) async {
    final t = _appToken;
    final uid = _userId;
    if (t == null || uid == null) return;
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.chatUnavailable)),
        );
        return;
      }
      final cid = info.conversationId;
      setState(() {
        _activeChatRideId = ride.id;
        _rideIdByConversationId[cid] = ride.id;
        _conversationIdByRideId[ride.id] = cid;
        _unreadChatByRideId.remove(ride.id);
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: cid,
            showDriverQuickReplies: false,
            minimalTripHeader: true,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _activeChatRideId = null;
        _unreadChatByRideId.remove(ride.id);
      });
      await _primeReadWatermarkAfterChat(
          token: t, conversationId: cid, rideId: ride.id);
      await _pollChatUnreadFallback();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    }
  }

  Future<void> _submitRideRating(int rideId) async {
    final selected = _ratingByRideId[rideId] ?? 0;
    if (selected < 1 || selected > 5) return;
    final t = _appToken;
    if (t == null) return;
    final l = AppLocalizations.of(context)!;
    try {
      await _api.submitRating(
        token: t,
        rideId: rideId,
        stars: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.thankYouFeedback)),
      );
      setState(() {
        _ratedRideIds.add(rideId);
        _ratingByRideId.remove(rideId);
        if (_pendingRatingRideId == rideId) {
          _pendingRatingRideId = null;
        }
      });
      await _refreshRides();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('already_rated')) {
        setState(() {
          _ratedRideIds.add(rideId);
          _ratingByRideId.remove(rideId);
          _recomputePendingRatingFromRides();
          _message = null;
        });
        return;
      }
      setState(() => _message = msg);
    }
  }

  ImageProvider<Object>? _imageProviderFromString(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:image/')) {
      final commaIdx = raw.indexOf(',');
      if (commaIdx <= 0 || commaIdx + 1 >= raw.length) return null;
      try {
        return MemoryImage(base64Decode(raw.substring(commaIdx + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(raw);
  }

  ImageProvider<Object>? _stableImageProviderFromString(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (_photoProviderCache.containsKey(raw)) {
      return _photoProviderCache[raw];
    }
    final provider = _imageProviderFromString(raw);
    _photoProviderCache[raw] = provider;
    return provider;
  }

  @override
  void initState() {
    super.initState();
    _destinationFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _destinationController.addListener(() {
      final text = _destinationController.text;
      final resolved = _resolveAnyRouteForDestinationText(text);
      if (_fareQuoteRouteKey != null && resolved != _fareQuoteRouteKey) {
        _fareQuoteFromMap = null;
        _fareQuoteRouteKey = null;
      }
      if (resolved != null && resolved != _routeKey && mounted) {
        setState(() => _routeKey = resolved);
      }
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.b2b);
      final s = widget.initialSession;
      if (s != null && _appToken == null) {
        _bootstrapFromSession(s);
      }
    });
  }

  Future<void> _bootstrapFromSession(LoginResponse auth) async {
    await SessionStore.saveB2b(auth);
    if (userChoseLocaleThisSession.value) {
      try {
        await _api.patchPreferredLanguage(
          token: auth.appAccessToken ?? auth.accessToken,
          preferredLanguage: appLocale.value.languageCode,
        );
      } catch (_) {}
    }
    rememberCurrentLocaleForRole(AppUiRole.b2b);
    final fares = await _api.getAirportFares();
    _token = auth.accessToken;
    _appToken = auth.appAccessToken ?? auth.accessToken;
    _userId = auth.userId;
    if (_appToken != null) {
      _unreadChatByRideId.clear();
      _rideIdByConversationId.clear();
      _conversationIdByRideId.clear();
      _lastSeenMessageIdByConversationId.clear();
      _connectRealtime(_appToken!);
      await _refreshRides();
      _startPolling();
      await _hydrateB2bProfileFromApi(_appToken!);
    }
    if (!mounted) return;
    setState(() {
      _ok = true;
      _fares = fares;
      _pruneInvalidRouteSelection();
    });
    await _detectB2bLocation();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socket.disconnect();
    _secretController.dispose();
    _guestController.dispose();
    _guestPhoneController.dispose();
    _destinationController.dispose();
    _destinationFocus.dispose();
    _hotelController.dispose();
    _flightEtaController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPhone = MediaQuery.of(context).size.width < 700;
    const activeStatuses = {'pending', 'accepted', 'ongoing'};
    final activeCount =
        _rides.where((r) => activeStatuses.contains(r.status)).length;
    final routeKeys = _filteredRouteKeys();
    final filteredRides = _rides.where((r) {
      switch (_rideFilter) {
        case _B2bRideFilter.pending:
          return r.status == 'pending';
        case _B2bRideFilter.accepted:
          return r.status == 'accepted' || r.status == 'ongoing';
        case _B2bRideFilter.cancelled:
          return r.status == 'cancelled';
        case _B2bRideFilter.completed:
          return r.status == 'completed';
        case _B2bRideFilter.all:
          return true;
      }
    }).toList();
    if (_routeKey != null && !routeKeys.contains(_routeKey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _routeKey = null;
          _fareQuoteFromMap = null;
          _fareQuoteRouteKey = null;
          _destinationController.clear();
        });
      });
    }
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goToHome,
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        centerTitle: true,
        title: Text(
          _uiText(
            en: 'B2B Portal',
            ar: 'بوابة B2B',
            fr: 'Portail B2B',
            es: 'Portal B2B',
            de: 'B2B-Portal',
            it: 'Portale B2B',
            ru: 'Портал B2B',
            zh: 'B2B门户',
          ),
          style: const TextStyle(
              color: _C.charcoal, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: _C.yellow,
        foregroundColor: _C.charcoal,
        elevation: 0,
        actions: [
          LocalePopupMenuButton(
            authToken: _appToken ?? _token,
            uiRole: AppUiRole.b2b,
            foregroundColor: _C.charcoal,
          ),
          if (_ok)
            IconButton(
              onPressed: () => unawaited(_logout()),
              tooltip: l.logoutApp,
              icon: const Icon(Icons.logout_rounded),
            ),
          if (_ok)
            IconButton(
              onPressed: _showNotifications,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _C.yellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            isPhone ? 12 : 16, isPhone ? 14 : 18, isPhone ? 12 : 16, 40),
        children: [
          if (!_ok)
            _Module(
              accent: true,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(colors: [
                          _C.surface,
                          _C.yellowSoft,
                          _C.yellowLight
                        ]),
                        border: Border.all(color: _C.yellow.withOpacity(0.65)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.business_center_rounded,
                              color: _C.yellow, size: 26),
                          const SizedBox(height: 12),
                          Text(l.b2bPortalHeading,
                              style: const TextStyle(
                                  color: _C.charcoal,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: 6),
                          Text(_tx('loginSubtitle'),
                              style: const TextStyle(
                                  color: _C.textMid,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _secretController,
                      obscureText: _obscureSecret,
                      decoration:
                          _fd(l.companyCode, icon: Icons.business_rounded)
                              .copyWith(
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscureSecret = !_obscureSecret),
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _C.charcoal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.yellow,
                          foregroundColor: _C.charcoal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: _busy ? null : _login,
                        child: Text(l.verifyCompanyCode,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_ok)
            Padding(
              padding: EdgeInsets.only(top: isPhone ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.yellow, _C.yellowLight, _C.yellowSoft],
                      ),
                      border: Border.all(color: _C.yellow.withOpacity(0.65)),
                      boxShadow: [
                        BoxShadow(
                            color: _C.yellowDeep.withOpacity(0.20),
                            blurRadius: 38,
                            offset: const Offset(0, 18))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.78),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: _C.yellow.withOpacity(0.65)),
                              ),
                              child: Text(_tx('b2bRideControl'),
                                  style: const TextStyle(
                                      color: _C.charcoal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.25)),
                            ),
                            const Spacer(),
                            const Icon(Icons.auto_awesome_rounded,
                                color: _C.yellowDeep, size: 22),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _b2bDisplayName.trim().isEmpty ||
                                  _b2bDisplayName == 'B2B account'
                              ? l.b2bPortalHeading
                              : _b2bDisplayName,
                          style: const TextStyle(
                              color: _C.charcoal,
                              fontSize: 25,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tx('heroBody'),
                          style: const TextStyle(
                              color: _C.textMid,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                                child: _metricPill(
                                    Icons.bolt_rounded,
                                    l.passengerActiveRidesChip(activeCount),
                                    _C.neonBlue)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _metricPill(
                                    Icons.route_rounded,
                                    l.passengerTotalRidesChip(_rides.length),
                                    _C.yellow)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Module(
                    accent: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHead(_tx('portalStatus'),
                            subtitle:
                                '${l.passengerActiveRidesChip(activeCount)} • ${l.passengerTotalRidesChip(_rides.length)}'),
                        InkWell(
                          onTap: _busy
                              ? null
                              : () => unawaited(_showB2bAccountDialog()),
                          borderRadius: BorderRadius.circular(12),
                          child: _rowInfoCard(
                            icon: Icons.account_circle_outlined,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _b2bDisplayName == 'B2B account'
                                      ? l.b2bPortalHeading
                                      : _b2bDisplayName,
                                  style: const TextStyle(
                                    color: _C.textStrong,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (_b2bEmail.isNotEmpty
                                          ? _b2bEmail
                                          : _tx('tapAccountDetails')) +
                                      (_b2bPhone.isNotEmpty
                                          ? ' · $_b2bPhone'
                                          : ''),
                                  style: const TextStyle(
                                      color: _C.textSoft, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _b2bCode.trim().isEmpty
                                      ? _tx('codeUnavailable')
                                      : _tx('codeLine', _b2bCode.trim()),
                                  style: const TextStyle(
                                      color: _C.textSoft, fontSize: 11),
                                ),
                                if (_b2bContactName.trim().isNotEmpty ||
                                    _b2bPin.trim().isNotEmpty)
                                  Text(
                                    _tx('namePinLine',
                                        '${_b2bContactName.trim().isEmpty ? '-' : _b2bContactName} | ${_b2bPin.trim().isEmpty ? '-' : _b2bPin}'),
                                    style: const TextStyle(
                                        color: _C.textSoft, fontSize: 11),
                                  ),
                                if (_b2bTenantPhone.trim().isNotEmpty ||
                                    _b2bHotel.trim().isNotEmpty)
                                  Text(
                                    _tx('phoneHotelLine',
                                        '${_b2bTenantPhone.trim().isEmpty ? '-' : _b2bTenantPhone} | ${_b2bHotel.trim().isEmpty ? '-' : _b2bHotel}'),
                                    style: const TextStyle(
                                        color: _C.textSoft, fontSize: 11),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.edit_outlined,
                                size: 18, color: _C.textMid),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Module(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHead(
                            l.b2bBookOnAccountHeading,
                            subtitle: _tx('guestRequestSubtitle'),
                          ),
                          Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _requestFormExpanded,
                              onExpansionChanged: (v) =>
                                  setState(() => _requestFormExpanded = v),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(
                                    color: _C.yellowDeep, width: 1.2),
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(
                                    color: _C.yellowDeep, width: 1.2),
                              ),
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: _C.yellow,
                              iconColor: _C.charcoal,
                              collapsedIconColor: _C.charcoal,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _C.charcoal,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.add_road_rounded,
                                    color: _C.yellow, size: 19),
                              ),
                              title: Text(
                                _tx('newRideRequest'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: _C.charcoal),
                              ),
                              subtitle: Text(
                                _tx('tapOpenForm'),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textStrong,
                                    fontWeight: FontWeight.w700),
                              ),
                              children: [
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _guestController,
                                  decoration: _fd(
                                    _tx('guestName'),
                                    icon: Icons.person_outline_rounded,
                                  ),
                                ),
                                TextField(
                                  controller: _guestPhoneController,
                                  decoration: _fd(
                                    _tx('guestPhone'),
                                    icon: Icons.phone_outlined,
                                  ),
                                ),
                                TextField(
                                  controller: _hotelController,
                                  decoration: _fd(
                                    _tx('hotel'),
                                    icon: Icons.apartment_rounded,
                                  ),
                                ),
                                TextField(
                                  controller: _flightEtaController,
                                  decoration: _fd(
                                    _tx('flightEta'),
                                    icon: Icons.flight_land_rounded,
                                  ),
                                ),
                                TextField(
                                  controller: _roomController,
                                  decoration: _fd(
                                    _tx('roomNumber'),
                                    icon: Icons.meeting_room_outlined,
                                  ),
                                ),
                                if (!isGoogleMapsPlatformSupported) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _locationText != null
                                                ? _tx('gpsLine', _locationText)
                                                : (_locationError ??
                                                    (_locating
                                                        ? l.passengerLocationDetecting
                                                        : l.passengerLocationUnavailable)),
                                            style: const TextStyle(
                                                color: _C.textSoft,
                                                fontSize: 11),
                                          ),
                                          if (_nearestZoneDistanceKm != null &&
                                              (_nearestZoneName ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              _tx('nearestZone',
                                                  '${localizedPlaceName(l, _nearestZoneName)} (${_nearestZoneDistanceKm!.toStringAsFixed(1)} km)'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _distanceColor(
                                                    _nearestZoneDistanceKm!),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _locating
                                          ? null
                                          : () =>
                                              unawaited(_detectB2bLocation()),
                                      icon: const Icon(
                                          Icons.my_location_rounded,
                                          size: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _rowInfoCard(
                                  icon: Icons.my_location_rounded,
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _tx(
                                            'departureLine',
                                            _nearestZoneName != null
                                                ? localizedPlaceName(
                                                    l, _nearestZoneName)
                                                : l.passengerLocationCurrent),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _locationText != null
                                            ? _tx('gpsLine', _locationText)
                                            : (_locationError ??
                                                (_locating
                                                    ? l.passengerLocationDetecting
                                                    : l.passengerLocationUnavailable)),
                                        style: const TextStyle(
                                            color: _C.textSoft, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    onPressed: _locating
                                        ? null
                                        : () => unawaited(_detectB2bLocation()),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _destinationController,
                                  focusNode: _destinationFocus,
                                  decoration: _fd(
                                    _tx('destination'),
                                    icon: Icons.place_outlined,
                                  ).copyWith(
                                    suffixIcon: _destinationController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _destinationController.clear();
                                                _routeKey = null;
                                                _fareQuoteFromMap = null;
                                                _fareQuoteRouteKey = null;
                                              });
                                            },
                                            icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18),
                                          ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: (_busy ||
                                            !isGoogleMapsPlatformSupported)
                                        ? null
                                        : () => unawaited(
                                              _openCorporateReservationMap(),
                                            ),
                                    icon: const Icon(Icons.map_outlined,
                                        size: 18, color: _C.yellowDeep),
                                    label: Text(
                                      _tx('openRouteMap'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: _C.charcoal,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) =>
                                      SizeTransition(
                                    sizeFactor: animation,
                                    axisAlignment: -1,
                                    child: FadeTransition(
                                        opacity: animation, child: child),
                                  ),
                                  child: _destinationFocus.hasFocus
                                      ? Padding(
                                          key: const ValueKey<String>(
                                              'destination-suggestions'),
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                                maxHeight: 250),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white
                                                      .withOpacity(0.96),
                                                  _C.yellowSoft
                                                      .withOpacity(0.72),
                                                  _C.surfaceAlt
                                                      .withOpacity(0.90),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              border: Border.all(
                                                color:
                                                    _C.yellow.withOpacity(0.55),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _C.yellowDeep
                                                      .withOpacity(0.12),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 12),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              child: ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                shrinkWrap: true,
                                                itemCount:
                                                    _destinationSuggestions()
                                                        .length,
                                                separatorBuilder: (_, __) =>
                                                    Divider(
                                                  height: 1,
                                                  indent: 58,
                                                  color: _C.border
                                                      .withOpacity(0.7),
                                                ),
                                                itemBuilder: (context, index) {
                                                  final s =
                                                      _destinationSuggestions()[
                                                          index];
                                                  final route =
                                                      _resolveAnyRouteForDestinationText(
                                                          s);
                                                  final km =
                                                      _routeDistanceKm(route);
                                                  final fare = route == null
                                                      ? null
                                                      : _fareForRouteKey(route);
                                                  final isRestaurant =
                                                      _routeKeyForRestaurantByName(
                                                              s) !=
                                                          null;
                                                  return ListTile(
                                                    dense: true,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 12,
                                                      vertical: 3,
                                                    ),
                                                    leading: Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: isRestaurant
                                                            ? const Color(
                                                                0xFF00695C)
                                                            : _C.yellow,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: _C.yellowDeep
                                                                .withOpacity(
                                                                    0.18),
                                                            blurRadius: 14,
                                                            offset:
                                                                const Offset(
                                                                    0, 6,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        isRestaurant
                                                            ? Icons
                                                                .restaurant_rounded
                                                            : Icons
                                                                .location_on_outlined,
                                                        color: isRestaurant
                                                            ? Colors.white
                                                            : _C.charcoal,
                                                        size: 17,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      _destinationListTitle(
                                                          l, s),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _C.charcoal,
                                                      ),
                                                    ),
                                                    subtitle: (km == null &&
                                                            fare == null)
                                                        ? null
                                                        : Text(
                                                            '${km?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt((fare ?? 0).toStringAsFixed(2))}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  _C.textSoft,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                    trailing: const Icon(
                                                      Icons.north_east_rounded,
                                                      color: _C.yellowDeep,
                                                      size: 16,
                                                    ),
                                                    onTap: () {
                                                      _destinationController
                                                          .text = s;
                                                      final resolved =
                                                          _resolveAnyRouteForDestinationText(
                                                              s);
                                                      setState(() {
                                                        _fareQuoteFromMap =
                                                            null;
                                                        _fareQuoteRouteKey =
                                                            null;
                                                        if (resolved !=
                                                            null) {
                                                          _routeKey = resolved;
                                                        }
                                                      });
                                                      _destinationFocus
                                                          .unfocus();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey<String>(
                                              'no-destination-suggestions'),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                if (_routeKey != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _rowInfoCard(
                                      icon: Icons.route_rounded,
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localizedRouteKeyForDisplay(
                                                l, _routeKey!),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_routeDistanceKm(_routeKey)?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt(((_fareQuoteFromMap != null && _routeKey == _fareQuoteRouteKey) ? _fareQuoteFromMap! : _fareForRouteKey(_routeKey)).toStringAsFixed(2))} ${l.b2bFareAdminPercentSuffix}',
                                            style: const TextStyle(
                                                color: _C.textSoft,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _busy ? null : _pickScheduledPickup,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [_C.surface, _C.yellowSoft]),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: _C.yellow.withOpacity(0.65)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.event_available_rounded,
                                            color: _C.yellowDeep,
                                            size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _tx('scheduledPickup'),
                                                style: const TextStyle(
                                                    color: _C.charcoal,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _scheduledPickupAt == null
                                                    ? _tx(
                                                        'chooseDateBeforeBooking')
                                                    : _formatSchedule(
                                                        _scheduledPickupAt!),
                                                style: const TextStyle(
                                                    color: _C.yellowDeep,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _C.yellowDeep),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _C.yellow,
                                      foregroundColor: _C.charcoal,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                    ),
                                    onPressed: _busy ? null : () => unawaited(_bookGuest()),
                                    child: Text(
                                      l.requestRideButton,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                ] else ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _locationText != null
                                                ? _tx('gpsLine', _locationText)
                                                : (_locationError ??
                                                    (_locating
                                                        ? l.passengerLocationDetecting
                                                        : l.passengerLocationUnavailable)),
                                            style: const TextStyle(
                                                color: _C.textSoft,
                                                fontSize: 11),
                                          ),
                                          if (_nearestZoneDistanceKm != null &&
                                              (_nearestZoneName ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              _tx('nearestZone',
                                                  '${localizedPlaceName(l, _nearestZoneName)} (${_nearestZoneDistanceKm!.toStringAsFixed(1)} km)'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _distanceColor(
                                                    _nearestZoneDistanceKm!),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: (_locating || _busy)
                                          ? null
                                          : () =>
                                              unawaited(_detectB2bLocation()),
                                      icon: const Icon(
                                          Icons.my_location_rounded,
                                          size: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tx('b2bGpsForMapPickupHint'),
                                  style: const TextStyle(
                                      color: _C.textSoft, fontSize: 11),
                                ),
                                if (!_b2bTripConfiguredViaMap) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _C.yellow,
                                        foregroundColor: _C.charcoal,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                      ),
                                      onPressed: (_busy || _locating)
                                          ? null
                                          : () => unawaited(
                                                _continueToB2bCorporateMap(),
                                              ),
                                      child: Text(
                                        _tx('b2bContinueToMap'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  _rowInfoCard(
                                    icon: Icons.place_outlined,
                                    content: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _tx('destination'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: _C.textSoft,
                                          ),
                                        ),
                                        Text(
                                          _destinationController.text.trim(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: _C.charcoal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_routeKey != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _rowInfoCard(
                                        icon: Icons.route_rounded,
                                        content: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              localizedRouteKeyForDisplay(
                                                  l, _routeKey!),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_routeDistanceKm(_routeKey)?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt(((_fareQuoteFromMap != null && _routeKey == _fareQuoteRouteKey) ? _fareQuoteFromMap! : _fareForRouteKey(_routeKey)).toStringAsFixed(2))} ${l.b2bFareAdminPercentSuffix}',
                                              style: const TextStyle(
                                                  color: _C.textSoft,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _rowInfoCard(
                                      icon: Icons.schedule_rounded,
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _tx('scheduledPickup'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                              color: _C.textSoft,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (_b2bScheduleLaterFromMap &&
                                                    _scheduledPickupAt != null)
                                                ? _formatSchedule(
                                                    _scheduledPickupAt!)
                                                : _tx('b2bRideNowSelected'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: _C.charcoal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => unawaited(
                                                _openCorporateReservationMap(),
                                              ),
                                      icon: const Icon(Icons.map_outlined,
                                          size: 18, color: _C.yellowDeep),
                                      label: Text(
                                        _tx('b2bChangeRouteMap'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: _C.charcoal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _C.yellow,
                                        foregroundColor: _C.charcoal,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                      ),
                                      onPressed: _busy ? null : () => unawaited(_bookGuest()),
                                      child: Text(
                                        l.requestRideButton,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionHead(l.myRidesHeading,
                      subtitle: _tx('ridesCount', filteredRides.length)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusFilterChip(
                        label: _uiText(
                          en: 'All',
                          ar: 'الكل',
                          fr: 'Tous',
                          es: 'Todos',
                          de: 'Alle',
                          it: 'Tutti',
                          ru: 'Все',
                          zh: '全部',
                        ),
                        selected: _rideFilter == _B2bRideFilter.all,
                        onTap: () =>
                            setState(() => _rideFilter = _B2bRideFilter.all),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'pending'),
                        selected: _rideFilter == _B2bRideFilter.pending,
                        onTap: () => setState(
                            () => _rideFilter = _B2bRideFilter.pending),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'accepted'),
                        selected: _rideFilter == _B2bRideFilter.accepted,
                        onTap: () => setState(
                            () => _rideFilter = _B2bRideFilter.accepted),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'cancelled'),
                        selected: _rideFilter == _B2bRideFilter.cancelled,
                        onTap: () => setState(
                            () => _rideFilter = _B2bRideFilter.cancelled),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'completed'),
                        selected: _rideFilter == _B2bRideFilter.completed,
                        onTap: () => setState(
                            () => _rideFilter = _B2bRideFilter.completed),
                      ),
                    ],
                  ),
                  _Module(
                    child: filteredRides.isEmpty
                        ? Text(l.noRidesYetApp,
                            style: const TextStyle(color: _C.textSoft))
                        : Column(
                            children: filteredRides
                                .map(
                                  (r) => Container(
                                    key: ValueKey<String>(
                                        'b2b-ride-${r.id}-chat-${_rideUnread(r.id)}'),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _rowInfoCard(
                                          icon: Icons.local_taxi_outlined,
                                          content: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${ridePickupTitle(r, l)} → ${rideDestinationTitle(r, l)}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l.rideStatusFmt(
                                                    localizedRideStatusLabel(
                                                        l, r.status)),
                                                style: const TextStyle(
                                                    color: _C.textSoft,
                                                    fontSize: 11),
                                              ),
                                              if (ridePickupAddressLine(
                                                          r, l) !=
                                                      null ||
                                                  rideDestinationAddressLine(
                                                          r, l) !=
                                                      null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    if (ridePickupAddressLine(
                                                            r, l) !=
                                                        null)
                                                      ridePickupAddressLine(
                                                          r, l)!,
                                                    if (rideDestinationAddressLine(
                                                            r, l) !=
                                                        null)
                                                      rideDestinationAddressLine(
                                                          r, l)!,
                                                  ].join('\n'),
                                                  maxLines: 4,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: _C.textSoft,
                                                      fontSize: 11),
                                                ),
                                              ],
                                              Builder(
                                                builder: (_) {
                                                  final km =
                                                      r.quotedDistanceKm;
                                                  final fare =
                                                      rideLockedFareDt(r);
                                                  final dur =
                                                      rideLockedDurationLabel(
                                                          r);
                                                  final parts = <String>[
                                                    if (km != null)
                                                      '${km.toStringAsFixed(1)} km',
                                                    if (dur != null &&
                                                        dur.isNotEmpty)
                                                      dur,
                                                    if (fare != null)
                                                      l.fareDt(fare
                                                          .toStringAsFixed(2)),
                                                  ];
                                                  return Text(
                                                    parts.isEmpty
                                                        ? '—'
                                                        : parts.join(' • '),
                                                    style: const TextStyle(
                                                        color: _C.textSoft,
                                                        fontSize: 11),
                                                  );
                                                },
                                              ),
                                              if ((r.scheduledPickupAt ?? '')
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                            colors: [
                                                          _C.surface,
                                                          _C.yellowSoft
                                                        ]),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    border: Border.all(
                                                        color: _C.yellow
                                                            .withOpacity(0.65)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .hourglass_top_rounded,
                                                          color: _C.yellowDeep,
                                                          size: 16),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${_reservationStatusText(r)} • ${_scheduleCountdown(r)}',
                                                          style: const TextStyle(
                                                              color:
                                                                  _C.charcoal,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (r.status == 'pending')
                                                Text(
                                                  _tx('driverSearching'),
                                                  style: const TextStyle(
                                                    color: _C.yellowDeep,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              if ((r.driverName ?? '')
                                                      .trim()
                                                      .isNotEmpty ||
                                                  (r.driverPhone ?? '')
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  l.passengerDriverLine(
                                                      (r.driverName ?? '')
                                                              .trim()
                                                              .isEmpty
                                                          ? l.driverNameFallback
                                                          : r.driverName!),
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                if ((r.driverPhone ?? '')
                                                    .trim()
                                                    .isNotEmpty)
                                                  Text(
                                                      l.passengerPhoneLine(
                                                          r.driverPhone!),
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                              ],
                                            ],
                                          ),
                                          trailing: (r.driverPhotoUrl ?? '')
                                                  .trim()
                                                  .isNotEmpty
                                              ? Builder(
                                                  builder: (context) {
                                                    final provider =
                                                        _stableImageProviderFromString(
                                                            r.driverPhotoUrl);
                                                    if (provider == null)
                                                      return const SizedBox
                                                          .shrink();
                                                    return CircleAvatar(
                                                        radius: 16,
                                                        backgroundImage:
                                                            provider);
                                                  },
                                                )
                                              : null,
                                        ),
                                        Wrap(
                                          clipBehavior: Clip.none,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (r.status != 'completed' &&
                                                r.status != 'cancelled')
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: _C.textMid,
                                                  side: const BorderSide(
                                                      color: _C.border),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                ),
                                                onPressed: _busy
                                                    ? null
                                                    : () => _cancelRide(r),
                                                child:
                                                    Text(l.cancelRidePassenger),
                                              ),
                                            Builder(
                                              builder: (ctx) {
                                                final uChat = _rideUnread(r.id);
                                                return Badge(
                                                  label: Text(
                                                    uChat > 99
                                                        ? '99+'
                                                        : '$uChat',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _C.charcoal),
                                                  ),
                                                  padding: EdgeInsets.only(
                                                      left: uChat > 0 ? 5 : 0,
                                                      right: uChat > 0 ? 5 : 0),
                                                  isLabelVisible: uChat > 0,
                                                  offset: const Offset(8, -6),
                                                  backgroundColor: _C.yellow,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: _C.surfaceAlt,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: _C.border),
                                                    ),
                                                    child: TextButton.icon(
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _openChat(r),
                                                      icon: const Icon(
                                                          Icons
                                                              .chat_bubble_rounded,
                                                          color: _C.charcoal,
                                                          size: 16),
                                                      label: Text(
                                                        l.openChatButton,
                                                        style: const TextStyle(
                                                            color: _C.charcoal,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (r.status == 'completed' &&
                                                (_pendingRatingRideId == r.id ||
                                                    !_ratedRideIds
                                                        .contains(r.id)))
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  ...List.generate(5, (i) {
                                                    final star = i + 1;
                                                    final selected =
                                                        (_ratingByRideId[
                                                                    r.id] ??
                                                                0) >=
                                                            star;
                                                    return InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap: _busy
                                                          ? null
                                                          : () => setState(() =>
                                                              _ratingByRideId[
                                                                  r.id] = star),
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: selected
                                                              ? _C.yellowSoft
                                                              : _C.surfaceAlt,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          border: Border.all(
                                                              color: selected
                                                                  ? _C.yellowDeep
                                                                  : _C.border),
                                                        ),
                                                        child: Icon(
                                                          selected
                                                              ? Icons
                                                                  .star_rounded
                                                              : Icons
                                                                  .star_border_rounded,
                                                          color: selected
                                                              ? _C.yellowDeep
                                                              : _C.textSoft,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                  FilledButton(
                                                    style:
                                                        FilledButton.styleFrom(
                                                      backgroundColor:
                                                          _C.yellow,
                                                      foregroundColor:
                                                          _C.charcoal,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50)),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 8),
                                                      minimumSize:
                                                          const Size(0, 30),
                                                    ),
                                                    onPressed: _busy ||
                                                            ((_ratingByRideId[
                                                                        r.id] ??
                                                                    0) <
                                                                1)
                                                        ? null
                                                        : () =>
                                                            _submitRideRating(
                                                                r.id),
                                                    child: Text(l.submitRating,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: _C.danger)),
        ],
      ),
    );
  }
}

class _ZoneCoord {
  const _ZoneCoord(this.lat, this.lng);
  final double lat;
  final double lng;
}

enum _B2bRideFilter { all, pending, accepted, cancelled, completed }
