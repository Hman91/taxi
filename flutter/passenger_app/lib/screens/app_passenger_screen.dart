// ═══════════════════════════════════════════════════════════════
// app_passenger_screen.dart — TUNISIAN TAXI YELLOW THEME
// All original logic preserved — only UI/style changed
// ═══════════════════════════════════════════════════════════════

import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/client.dart';
import '../app_locale.dart';
import '../config.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_address_display.dart';
import '../l10n/ride_status_localization.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/night_fare_breakdown.dart';
import '../utils/chat_unread_poll.dart';
import '../utils/airport_place_heuristics.dart';
import '../utils/int_from_json.dart';
import '../widgets/passenger_google_sign_in_button.dart';
import 'live_trip_map_screen.dart';
import 'passenger_reservation_map_screen.dart';
import 'passenger_forgot_password_screen.dart';
import 'passenger_home_screen.dart';
import 'passenger_signup_screen.dart';
import 'ride_chat_screen.dart';
import '../widgets/ride_address_summary_card.dart';

// ── Design tokens ─────────────────────────────────────────────
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
  static const success = Color(0xFF1A7A4A);
  static const successBg = Color(0xFFD4EDDA);
  static const info = Color(0xFF1E3A8A);
  static const amber = Color(0xFFB45309);
  static const neonBlue = Color(0xFFFFC200);
}

const Map<String, Map<String, String>> _passengerUiTranslations = {
  'at': {
    'en': 'at',
    'fr': 'à',
    'ar': 'على الساعة',
    'de': 'um',
    'es': 'a las',
    'it': 'alle',
    'zh': '于',
    'ru': 'в',
  },
  'phoneRequiredTitle': {
    'en': 'Phone required',
    'fr': 'Téléphone requis',
    'ar': 'رقم الهاتف مطلوب',
    'de': 'Telefonnummer erforderlich',
    'es': 'Teléfono requerido',
    'it': 'Telefono richiesto',
    'zh': '需要电话号码',
    'ru': 'Требуется телефон',
  },
  'phoneNumber': {
    'en': 'Phone number',
    'fr': 'Numéro de téléphone',
    'ar': 'رقم الهاتف',
    'de': 'Telefonnummer',
    'es': 'Número de teléfono',
    'it': 'Numero di telefono',
    'zh': '电话号码',
    'ru': 'Номер телефона',
  },
  'phoneNumberRequired': {
    'en': 'Phone number is required.',
    'fr': 'Le numéro de téléphone est requis.',
    'ar': 'رقم الهاتف مطلوب.',
    'de': 'Die Telefonnummer ist erforderlich.',
    'es': 'El número de teléfono es obligatorio.',
    'it': 'Il numero di telefono è obbligatorio.',
    'zh': '需要填写电话号码。',
    'ru': 'Номер телефона обязателен.',
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
  'fillEmailPassword': {
    'en': 'Please fill in email and password.',
    'fr': 'Veuillez saisir l’adresse e-mail et le mot de passe.',
    'ar': 'يرجى إدخال البريد الإلكتروني وكلمة المرور.',
    'de': 'Bitte E-Mail und Passwort eingeben.',
    'es': 'Introduce el correo electrónico y la contraseña.',
    'it': 'Inserisci email e password.',
    'zh': '请填写邮箱和密码。',
    'ru': 'Введите email и пароль.',
  },
  'passengerAccountRequired': {
    'en': 'Please sign in with a passenger account.',
    'fr': 'Veuillez vous connecter avec un compte passager.',
    'ar': 'يرجى تسجيل الدخول بحساب راكب.',
    'de': 'Bitte mit einem Fahrgastkonto anmelden.',
    'es': 'Inicia sesión con una cuenta de pasajero.',
    'it': 'Accedi con un account passeggero.',
    'zh': '请使用乘客账号登录。',
    'ru': 'Войдите с аккаунтом пассажира.',
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
  'reserveRideTitle': {
    'en': 'Reserve your ride',
    'fr': 'Réservez votre course',
    'ar': 'احجز رحلتك',
    'de': 'Fahrt reservieren',
    'es': 'Reserva tu viaje',
    'it': 'Prenota la corsa',
    'zh': '预约行程',
    'ru': 'Забронируйте поездку',
  },
  'reserveRideBody': {
    'en': 'Lock in a driver ahead of time for airport trips and early pickups.',
    'fr':
        'Réservez un chauffeur à l’avance pour les trajets aéroport et les départs matinaux.',
    'ar': 'ثبّت سائقاً مسبقاً لرحلات المطار والانطلاقات المبكرة.',
    'de':
        'Sichere dir frühzeitig einen Fahrer für Flughafentransfers und frühe Abholungen.',
    'es':
        'Asegura un conductor con antelación para traslados al aeropuerto y recogidas tempranas.',
    'it':
        'Blocca un autista in anticipo per trasferimenti in aeroporto e partenze mattutine.',
    'zh': '提前锁定司机，适合机场行程和清晨接送。',
    'ru': 'Заранее закрепите водителя для аэропорта и ранних подач.',
  },
  'rideNow': {
    'en': 'Ride now',
    'fr': 'Partir maintenant',
    'ar': 'اركب الآن',
    'de': 'Jetzt fahren',
    'es': 'Viajar ahora',
    'it': 'Parti ora',
    'zh': '现在出发',
    'ru': 'Поехать сейчас',
  },
  'scheduleRide': {
    'en': 'Schedule a ride',
    'fr': 'Planifier une course',
    'ar': 'جدولة رحلة',
    'de': 'Fahrt planen',
    'es': 'Programar viaje',
    'it': 'Programma una corsa',
    'zh': '预约行程',
    'ru': 'Запланировать поездку',
  },
  'choosePickupDateTime': {
    'en': 'Choose pickup date and time',
    'fr': 'Choisissez la date et l’heure de prise en charge',
    'ar': 'اختر تاريخ ووقت الانطلاق',
    'de': 'Abholdatum und -zeit wählen',
    'es': 'Elige fecha y hora de recogida',
    'it': 'Scegli data e ora del ritiro',
    'zh': '选择接送日期和时间',
    'ru': 'Выберите дату и время подачи',
  },
  'selectDestination': {
    'en': 'Select destination',
    'fr': 'Sélectionner la destination',
    'ar': 'اختر الوجهة',
    'de': 'Ziel auswählen',
    'es': 'Selecciona destino',
    'it': 'Seleziona destinazione',
    'zh': '选择目的地',
    'ru': 'Выберите пункт назначения',
  },
  'tapDestinationHint': {
    'en': 'Tap destination to choose where you want to go.',
    'fr': 'Touchez la destination pour choisir où aller.',
    'ar': 'اضغط على الوجهة لاختيار مكان الذهاب.',
    'de': 'Tippe auf das Ziel, um deinen Zielort zu wählen.',
    'es': 'Toca destino para elegir a dónde quieres ir.',
    'it': 'Tocca destinazione per scegliere dove andare.',
    'zh': '点击目的地选择你要去的地方。',
    'ru': 'Нажмите на пункт назначения, чтобы выбрать маршрут.',
  },
  'pickupPinHint': {
    'en': 'Pan the map — the centre is your pickup.',
    'fr': 'Déplacez la carte — le centre définit votre prise en charge.',
    'ar': 'حرّك الخريطة — المركز هو نقطة الانطلاق.',
    'de': 'Karte schieben — die Mitte ist deine Abholung.',
    'es': 'Mueve el mapa — el centro es tu recogida.',
    'it': 'Sposta la mappa — il centro è il ritiro.',
    'zh': '拖动地图 — 中心点即为上车位置。',
    'ru': 'Двигайте карту — центр экрана — точка подачи.',
  },
  'openRouteMap': {
    'en': 'Map',
    'fr': 'Carte',
    'ar': 'خريطة',
    'de': 'Karte',
    'es': 'Mapa',
    'it': 'Mappa',
    'zh': '地图',
    'ru': 'Карта',
  },
  'mapTapDestinationHint': {
    'en':
        'Use Airports, Zones, or Restaurants above, then tap a marker — or open Destination below to search.',
    'fr':
        'Choisissez Aéroports, Zones ou Restaurants ci‑dessus, touchez un marqueur — ou ouvrez Destination pour chercher.',
    'ar': 'اختر المطارات أو المناطق أو المطاعم أعلاه واضغط علامة — أو افتح الوجهة للبحث أدناه.',
    'de':
        'Wähle Flughäfen, Zonen oder Restaurants oben, tippe auf eine Markierung — oder öffne Ziel unten.',
    'es':
        'Usa Aeropuertos, Zonas o Restaurantes arriba y toca un marcador — o abre Destino abajo.',
    'it':
        'Scegli Aeroporti, Zone o Ristoranti sopra e tocca un marker — o apri Destinazione sotto.',
    'zh': '在上方选择机场、区域或餐厅并点击标记 — 或在下方打开目的地搜索。',
    'ru':
        'Выберите Аэропорты, Зоны или Рестораны выше и нажмите маркер — или откройте «Куда» ниже.',
  },
  'mapBookingFocusedHint': {
    'en': 'Pickup and destination are set. The map shows only this route — confirm below.',
    'fr':
        'Départ et destination sont définis. La carte n’affiche que ce trajet — confirmez ci‑dessous.',
    'ar': 'تم تحديد الانطلاق والوجهة. الخريطة تعرض هذا المسار فقط — أكّد أدناه.',
    'de': 'Abholung und Ziel sind gesetzt. Die Karte zeigt nur diese Route — unten bestätigen.',
    'es': 'Origen y destino listados. El mapa solo muestra esta ruta — confirma abajo.',
    'it': 'Partenza e destinazione impostate. La mappa mostra solo questo percorso — conferma sotto.',
    'zh': '已设定上下车点，地图仅显示此路线 — 请在下方确认。',
    'ru': 'Точки подачи и назначения заданы. На карте только этот маршрут — подтвердите ниже.',
  },
  'mapFilterAirports': {
    'en': 'Airports',
    'fr': 'Aéroports',
    'ar': 'المطارات',
    'de': 'Flughäfen',
    'es': 'Aeropuertos',
    'it': 'Aeroporti',
    'zh': '机场',
    'ru': 'Аэропорты',
  },
  'mapFilterZones': {
    'en': 'Zones',
    'fr': 'Zones',
    'ar': 'المناطق',
    'de': 'Zonen',
    'es': 'Zonas',
    'it': 'Zone',
    'zh': '区域',
    'ru': 'Зоны',
  },
  'mapFilterRestaurants': {
    'en': 'Restaurants',
    'fr': 'Restaurants',
    'ar': 'مطاعم',
    'de': 'Restaurants',
    'es': 'Restaurantes',
    'it': 'Ristoranti',
    'zh': '餐厅',
    'ru': 'Рестораны',
  },
  'restaurantSuggestionsHeader': {
    'en': 'TOURIST RESTAURANTS',
    'fr': 'RESTAURANTS TOURISTIQUES',
    'ar': 'مطاعم سياحية',
    'de': 'TOURISTENRESTAURANTS',
    'es': 'RESTAURANTES TURÍSTICOS',
    'it': 'RISTORANTI TURISTICI',
    'zh': '旅游餐厅',
    'ru': 'ТУРИСТИЧЕСКИЕ РЕСТОРАНЫ',
  },
  'restaurantMapCardSubtitle': {
    'en': 'Curated pin on the map. Fares use your nearest priced taxi zone.',
    'fr': 'Repère sur la carte. Les tarifs utilisent la zone taxi tarifée la plus proche.',
    'ar': 'علامة على الخريطة. الأسعار تعتمد أقرب منطقة تاكسي مُسعّرة.',
    'de': 'Markierung auf der Karte. Fahrpreise nutzen die nächste tarifierte Taxizone.',
    'es': 'Marcador en el mapa. Las tarifas usan tu zona de taxi tarificada más cercana.',
    'it': 'Segnaposto sulla mappa. Le tariffe usano la zona taxi tariffata più vicina.',
    'zh': '地图上的精选标记；费用按最近计价出租车区域计算。',
    'ru': 'Метка на карте. Тарифы считаются по ближайшей зоне такси с фиксированной ценой.',
  },
  'restaurantUseNearestPricedZone': {
    'en': 'Use nearest priced taxi destination',
    'fr': 'Utiliser la destination taxi tarifée la plus proche',
    'ar': 'استخدام أقرب وجهة تاكسي بسعر ثابت',
    'de': 'Nächstes tarifiertes Taxiziel verwenden',
    'es': 'Usar destino de taxi tarificado más cercano',
    'it': 'Usa destinazione taxi tariffata più vicina',
    'zh': '使用最近的计价出租车目的地',
    'ru': 'Ближайшая зона с фиксированным тарифом',
  },
  'restaurantInfoDismiss': {
    'en': 'Close',
    'fr': 'Fermer',
    'ar': 'إغلاق',
    'de': 'Schließen',
    'es': 'Cerrar',
    'it': 'Chiudi',
    'zh': '关闭',
    'ru': 'Закрыть',
  },
  'mapYouPinLabel': {
    'en': 'YOU',
    'fr': 'VOUS',
    'ar': 'أنت',
    'de': 'DU',
    'es': 'TÚ',
    'it': 'TU',
    'zh': '您',
    'ru': 'ВЫ',
  },
  'mapPickupGpsHint': {
    'en': 'Pickup is your live GPS position and updates as you move.',
    'fr': 'La prise en charge suit votre GPS en direct et se met à jour quand vous bougez.',
    'ar': 'نقطة الانطلاق هي موقعك عبر الـGPS مباشرة وتتحدث مع حركتك.',
    'de': 'Abholung ist dein Live‑GPS und aktualisiert sich beim Bewegen.',
    'es': 'La recogida es tu GPS en vivo y se actualiza al moverte.',
    'it': 'Il ritiro segue il GPS in tempo reale e si aggiorna mentre ti muovi.',
    'zh': '上车点为您实时 GPS，随移动更新。',
    'ru': 'Подача по живому GPS и обновляется при движении.',
  },
  'mapMarkersPickFilterHint': {
    'en': 'One category is always active: switch between Airports, Zones, and Restaurants to change markers.',
    'fr':
        'Une catégorie est toujours active : passez d’Aéroports à Zones ou Restaurants pour changer les marqueurs.',
    'ar': 'تبقى فئة واحدة نشطة: بدّل بين المطارات والمناطق والمطاعم لتغيير العلامات.',
    'de': 'Immer eine Kategorie aktiv: wechsle zwischen Flughäfen, Zonen und Restaurants für andere Marker.',
    'es': 'Siempre hay una categoría activa: cambia entre Aeropuertos, Zonas y Restaurantes para otros marcadores.',
    'it': 'È sempre attiva una categoria: passa tra Aeroporti, Zone e Ristoranti per cambiare i marker.',
    'zh': '始终有一种类别处于活动状态：在机场、区域和餐厅之间切换以更换标记。',
    'ru': 'Всегда активна одна категория: переключайте Аэропорты, Зоны и Рестораны для смены маркеров.',
  },
  'destSearchAutocompleteHint': {
    'en': 'Type a destination…',
    'fr': 'Tapez une destination…',
    'ar': 'اكتب وجهة…',
    'de': 'Ziel eingeben…',
    'es': 'Escribe un destino…',
    'it': 'Digita una destinazione…',
    'zh': '输入目的地…',
    'ru': 'Введите пункт назначения…',
  },
  'placesSuggestionsHeader': {
    'en': 'GOOGLE PLACES',
    'fr': 'GOOGLE PLACES',
    'ar': 'GOOGLE PLACES',
    'de': 'GOOGLE PLACES',
    'es': 'GOOGLE PLACES',
    'it': 'GOOGLE PLACES',
    'zh': 'GOOGLE 地点',
    'ru': 'GOOGLE PLACES',
  },
  'catalogDestinationsHeader': {
    'en': 'SERVICE AREA LIST',
    'fr': 'LISTE DES DESTINATIONS',
    'ar': 'قائمة الوجهات',
    'de': 'GEBIETSLISTE',
    'es': 'LISTA DE DESTINOS',
    'it': 'ELENCO DESTINAZIONI',
    'zh': '服务区域列表',
    'ru': 'СПИСОК НАПРАВЛЕНИЙ',
  },
  'catalogLiveMatchesHeader': {
    'en': 'MATCHING PLACES',
    'fr': 'LIEUX CORRESPONDANTS',
    'ar': 'أماكن مطابقة',
    'de': 'TREFFER',
    'es': 'LUGARES COINCIDENTES',
    'it': 'LUOGHI CORRISPONDENTI',
    'zh': '匹配地点',
    'ru': 'СОВПАДЕНИЯ',
  },
  'destSearchNoMatches': {
    'en': 'No destinations match that text. Try another spelling.',
    'fr': 'Aucune destination ne correspond. Essayez une autre orthographe.',
    'ar': 'لا توجد وجهة مطابقة. جرّب كتابة مختلفة.',
    'de': 'Keine passende Destination. Andere Schreibweise versuchen.',
    'es': 'Ningún destino coincide. Prueba otra forma de escribirlo.',
    'it': 'Nessuna destinazione corrisponde. Prova un’altra grafia.',
    'zh': '没有匹配的目的地，请尝试其他拼写。',
    'ru': 'Нет совпадений. Попробуйте другое написание.',
  },
  'destSearchTypeHint': {
    'en': 'Results update as you type — saved places first, then wider Google results.',
    'fr': 'Résultats en direct : lieux enregistrés d’abord, puis Google.',
    'ar': 'النتائج تتحدث مع الكتابة: الأماكن المحفوظة أولاً ثم نتائج أوسع.',
    'de': 'Live-Ergebnisse: zuerst gespeicherte Orte, dann Google.',
    'es': 'Resultados al instante: lugares guardados primero, luego Google.',
    'it': 'Risultati in tempo reale: prima i luoghi salvati, poi Google.',
    'zh': '输入即更新：先显示已保存地点，再显示 Google 结果。',
    'ru': 'Обновление при вводе: сначала сохранённые места, затем Google.',
  },
  'noRoutesFromYourArea': {
    'en': 'No priced routes from your current area.',
    'fr': 'Aucun tarif disponible depuis votre zone actuelle.',
    'ar': 'لا مسارات مسعّرة من منطقتك الحالية.',
    'de': 'Keine Tarifstrecken aus deiner aktuellen Region.',
    'es': 'No hay rutas con tarifa desde tu zona actual.',
    'it': 'Nessuna tratta tariffata dalla tua zona attuale.',
    'zh': '当前区域没有定价路线。',
    'ru': 'Нет тарифных маршрутов из вашей текущей зоны.',
  },
  'destinationPlaceOutOfCoverage': {
    'en': 'That place is outside the bookable destinations for your area.',
    'fr': 'Ce lieu est hors des destinations réservables depuis votre zone.',
    'ar': 'هذا المكان خارج الوجهات المتاحة لمنطقتك.',
    'de': 'Dieser Ort liegt außerhalb der buchbaren Ziele für deine Region.',
    'es': 'Ese sitio queda fuera de los destinos reservables desde tu zona.',
    'it': 'Questo luogo è fuori dalle destinazioni prenotabili dalla tua zona.',
    'zh': '该地点不在您当前区域的可预约目的地内。',
    'ru': 'Это место вне списка доступных направлений для вашей зоны.',
  },
  'placesApiUnavailable': {
    'en': 'Places search is unavailable (check API key / Places API).',
    'fr': 'Recherche Places indisponible (clé API / API Places).',
    'ar': 'بحث الأماكن غير متاح (تحقق من المفتاح وواجهة Places).',
    'de': 'Places‑Suche nicht verfügbar (API‑Schlüssel / Places API).',
    'es': 'Búsqueda de Places no disponible (clave API / Places API).',
    'it': 'Ricerca Places non disponibile (chiave API / Places API).',
    'zh': '地点搜索不可用（请检查 API 密钥与 Places API）。',
    'ru': 'Поиск Places недоступен (ключ / Places API).',
  },
  'mapRecenterFollow': {
    'en': 'Follow my position',
    'fr': 'Suivre ma position',
    'ar': 'تتبع موقعي',
    'de': 'Position folgen',
    'es': 'Seguir mi posición',
    'it': 'Segui la mia posizione',
    'zh': '跟随我的位置',
    'ru': 'Следовать за мной',
  },
  'locationPermissionReservationNote': {
    'en': 'Location permission denied — pickup zone is approximate until GPS is allowed.',
    'fr':
        'Autorisation de localisation refusée — la zone de prise en charge est approximative tant que le GPS est bloqué.',
    'ar': 'تم رفض إذن الموقع — منطقة الانطلاق تقريبية حتى يُفعّل الـGPS.',
    'de': 'Standort verweigert — Abholzone ist näherungsweise, bis GPS erlaubt ist.',
    'es': 'Ubicación denegada — la zona de recogida es aproximada hasta permitir GPS.',
    'it': 'Posizione negata — la zona di ritiro è approssimativa finché non consenti il GPS.',
    'zh': '未授予定位权限 — 允许 GPS 前上车区域仅为近似。',
    'ru': 'Доступ к геолокации отклонён — зона подачи приблизительна, пока не разрешите GPS.',
  },
  'reserveDriver': {
    'en': 'Reserve driver',
    'fr': 'Réserver un chauffeur',
    'ar': 'احجز سائقاً',
    'de': 'Fahrer reservieren',
    'es': 'Reservar conductor',
    'it': 'Prenota autista',
    'zh': '预约司机',
    'ru': 'Забронировать водителя',
  },
  'signInSection': {
    'en': 'Sign in',
    'fr': 'Connexion',
    'ar': 'تسجيل الدخول',
    'de': 'Anmelden',
    'es': 'Iniciar sesión',
    'it': 'Accedi',
    'zh': '登录',
    'ru': 'Вход',
  },
  'createAccountSection': {
    'en': 'Create account',
    'fr': 'Créer un compte',
    'ar': 'إنشاء حساب',
    'de': 'Konto erstellen',
    'es': 'Crear cuenta',
    'it': 'Crea account',
    'zh': '创建账号',
    'ru': 'Создать аккаунт',
  },
  'newHereSignup': {
    'en': 'New here? Create a passenger account on a dedicated screen.',
    'fr': 'Nouveau ici ? Créez un compte passager sur un écran dédié.',
    'ar': 'جديد هنا؟ أنشئ حساب راكب في شاشة مخصصة.',
    'de': 'Neu hier? Erstelle ein Fahrgastkonto auf einer eigenen Seite.',
    'es': '¿Nuevo aquí? Crea una cuenta de pasajero en una pantalla dedicada.',
    'it': 'Nuovo qui? Crea un account passeggero in una schermata dedicata.',
    'zh': '新用户？请在专用页面创建乘客账号。',
    'ru': 'Вы здесь впервые? Создайте аккаунт пассажира на отдельном экране.',
  },
  'nextGenTransfer': {
    'en': 'NEXT-GEN TRANSFER',
    'fr': 'TRANSFERT NOUVELLE GÉNÉRATION',
    'ar': 'نقل الجيل الجديد',
    'de': 'TRANSFER DER NÄCHSTEN GENERATION',
    'es': 'TRASLADO DE NUEVA GENERACIÓN',
    'it': 'TRANSFER DI NUOVA GENERAZIONE',
    'zh': '新一代接送',
    'ru': 'ТРАНСФЕР НОВОГО ПОКОЛЕНИЯ',
  },
  'premiumRideReady': {
    'en': 'Your premium ride, ready when you are.',
    'fr': 'Votre course premium, prête quand vous l’êtes.',
    'ar': 'رحلتك الفاخرة جاهزة عندما تكون جاهزاً.',
    'de': 'Deine Premiumfahrt ist bereit, sobald du es bist.',
    'es': 'Tu viaje premium, listo cuando tú lo estés.',
    'it': 'La tua corsa premium è pronta quando vuoi.',
    'zh': '你的尊享行程已准备就绪。',
    'ru': 'Ваша премиальная поездка готова, когда готовы вы.',
  },
  'welcomeBack': {
    'en': 'Welcome back, {value}',
    'fr': 'Bon retour, {value}',
    'ar': 'مرحباً بعودتك، {value}',
    'de': 'Willkommen zurück, {value}',
    'es': 'Bienvenido de nuevo, {value}',
    'it': 'Bentornato, {value}',
    'zh': '欢迎回来，{value}',
    'ru': 'С возвращением, {value}',
  },
  'bookingHeroBody': {
    'en': 'Choose an airport transfer or reserve a driver ahead of time.',
    'fr':
        'Choisissez un transfert aéroport ou réservez un chauffeur à l’avance.',
    'ar': 'اختر نقل المطار أو احجز سائقاً مسبقاً.',
    'de':
        'Wähle einen Flughafentransfer oder reserviere frühzeitig einen Fahrer.',
    'es':
        'Elige un traslado al aeropuerto o reserva un conductor con antelación.',
    'it': 'Scegli un transfer aeroportuale o prenota un autista in anticipo.',
    'zh': '选择机场接送或提前预约司机。',
    'ru': 'Выберите трансфер в аэропорт или заранее забронируйте водителя.',
  },
  'pickupLocked': {
    'en': 'Pickup intelligence locked on {value}.',
    'fr': 'Point de prise en charge détecté : {value}.',
    'ar': 'تم تحديد نقطة الانطلاق الذكية: {value}.',
    'de': 'Intelligente Abholung auf {value} fixiert.',
    'es': 'Recogida inteligente fijada en {value}.',
    'it': 'Ritiro intelligente fissato su {value}.',
    'zh': '智能接送已锁定在 {value}。',
    'ru': 'Умная подача закреплена: {value}.',
  },
  'totalRidesShort': {
    'en': '{value} total',
    'fr': '{value} au total',
    'ar': '{value} إجمالي',
    'de': '{value} gesamt',
    'es': '{value} en total',
    'it': '{value} totali',
    'zh': '共 {value}',
    'ru': 'Всего: {value}',
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
  'airportTransferScheduled': {
    'en': 'Airport transfer • instant or scheduled',
    'fr': 'Transfert aéroport • immédiat ou planifié',
    'ar': 'نقل المطار • فوري أو مجدول',
    'de': 'Flughafentransfer • sofort oder geplant',
    'es': 'Traslado al aeropuerto • instantáneo o programado',
    'it': 'Transfer aeroporto • immediato o programmato',
    'zh': '机场接送 • 即时或预约',
    'ru': 'Трансфер в аэропорт • сразу или по расписанию',
  },
  'rideAlreadyActive': {
    'en': 'Ride already active',
    'fr': 'Course déjà active',
    'ar': 'هناك رحلة نشطة بالفعل',
    'de': 'Fahrt bereits aktiv',
    'es': 'Ya hay un viaje activo',
    'it': 'Corsa già attiva',
    'zh': '已有进行中的行程',
    'ru': 'Поездка уже активна',
  },
  'reservePremiumRide': {
    'en': 'Reserve premium ride',
    'fr': 'Réserver une course premium',
    'ar': 'احجز رحلة فاخرة',
    'de': 'Premiumfahrt reservieren',
    'es': 'Reservar viaje premium',
    'it': 'Prenota corsa premium',
    'zh': '预约尊享行程',
    'ru': 'Забронировать премиум-поездку',
  },
  'pickupWindowOpen': {
    'en': 'Pickup window is open',
    'fr': 'La fenêtre de prise en charge est ouverte',
    'ar': 'وقت الانطلاق مفتوح الآن',
    'de': 'Das Abholfenster ist geöffnet',
    'es': 'La ventana de recogida está abierta',
    'it': 'La finestra di ritiro è aperta',
    'zh': '接送时间窗口已开启',
    'ru': 'Окно подачи открыто',
  },
  'untilPickupMinutes': {
    'en': '{value}m until pickup',
    'fr': '{value} min avant la prise en charge',
    'ar': '{value} د حتى الانطلاق',
    'de': '{value} Min. bis zur Abholung',
    'es': '{value} min hasta la recogida',
    'it': '{value} min al ritiro',
    'zh': '距接送 {value} 分钟',
    'ru': '{value} мин до подачи',
  },
  'untilPickup': {
    'en': '{value} until pickup',
    'fr': '{value} avant la prise en charge',
    'ar': '{value} حتى الانطلاق',
    'de': '{value} bis zur Abholung',
    'es': '{value} hasta la recogida',
    'it': '{value} al ritiro',
    'zh': '距接送 {value}',
    'ru': '{value} до подачи',
  },
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
  'pickupInProgress': {
    'en': 'Pickup in progress',
    'fr': 'Prise en charge en cours',
    'ar': 'الانطلاق جارٍ',
    'de': 'Abholung läuft',
    'es': 'Recogida en curso',
    'it': 'Ritiro in corso',
    'zh': '接送进行中',
    'ru': 'Подача выполняется',
  },
  'reservationCompleted': {
    'en': 'Reservation completed',
    'fr': 'Réservation terminée',
    'ar': 'اكتمل الحجز',
    'de': 'Reservierung abgeschlossen',
    'es': 'Reserva completada',
    'it': 'Prenotazione completata',
    'zh': '预约已完成',
    'ru': 'Бронирование завершено',
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
};

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: _C.textSoft, fontSize: 12, fontWeight: FontWeight.w700),
      prefixIcon: icon != null ? Icon(icon, color: _C.info, size: 18) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.82),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.9), width: 1.2)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _C.neonBlue, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );

class _YellowButton extends StatelessWidget {
  const _YellowButton(
      {required this.label,
      required this.onPressed,
      this.icon,
      this.small = false,
      this.fontSize});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: small ? 38 : 50,
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [_C.yellowLight, _C.yellow, _C.yellowDeep]),
            color: disabled ? _C.border : null,
            borderRadius: BorderRadius.circular(50),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                        color: _C.yellowDeep.withOpacity(0.34),
                        blurRadius: 22,
                        offset: const Offset(0, 10))
                  ],
          ),
          child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, color: _C.charcoal, size: small ? 14 : 18),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    color: _C.charcoal,
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize ?? (small ? 12 : 14),
                    letterSpacing: 0.3)),
          ])),
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton(
      {required this.label,
      required this.onPressed,
      this.icon,
      this.small = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.45 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: small ? 38 : 50,
          decoration: BoxDecoration(
            color: _C.yellowSoft,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _C.yellowDeep.withOpacity(0.55)),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                        color: _C.yellowDeep.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, color: _C.charcoal, size: small ? 14 : 18),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    color: _C.charcoal,
                    fontWeight: FontWeight.w800,
                    fontSize: small ? 12 : 14,
                    letterSpacing: 0.3)),
          ])),
        ),
      ),
    );
  }
}

class _TaxiCard extends StatelessWidget {
  const _TaxiCard(
      {required this.child,
      this.padding = 16,
      this.accent = false,
      this.color});
  final Widget child;
  final double padding;
  final bool accent;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: color != null
                ? [color!, color!]
                : accent
                    ? [
                        Colors.white.withOpacity(0.96),
                        _C.yellowSoft.withOpacity(0.86)
                      ]
                    : [
                        Colors.white.withOpacity(0.92),
                        Colors.white.withOpacity(0.72)
                      ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: accent
                  ? _C.yellow.withOpacity(0.72)
                  : Colors.white.withOpacity(0.92),
              width: 1.4),
          boxShadow: [
            BoxShadow(
                color: _C.info.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 14)),
            BoxShadow(
                color: Colors.white.withOpacity(0.65),
                blurRadius: 0,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      );
}

class _ScheduleModeChip extends StatelessWidget {
  const _ScheduleModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            color: selected ? _C.yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _C.charcoal : _C.textMid,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = _C.charcoal});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: _C.yellow, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
      ]);
}

enum _TripOptionType {
  airportToTourist,
  currentToTourist,
  currentToAirport,
}

// ─────────────────────────────────────────────────────────────
class AppPassengerScreen extends StatefulWidget {
  const AppPassengerScreen({super.key, this.initialSession});
  final AppLoginResponse? initialSession;

  @override
  State<AppPassengerScreen> createState() => _AppPassengerScreenState();
}

class _AppPassengerScreenState extends State<AppPassengerScreen> {
  // ALL ORIGINAL FIELDS (unchanged)
  final _api = TaxiAppService();
  final _socket = ChatSocketService();
  final _imagePicker = ImagePicker();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPhoneCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  String _signupPhotoData = '';
  Map<String, double> _fares = {};
  String? _locationPlaceName;
  double? _mapLat;
  double? _mapLng;
  String? _locationError;
  bool _locating = false;
  String? _token;
  int? _userId;
  String? _passengerDisplayName;
  String? _passengerPhotoUrl;
  String? _passengerEmail;
  String? _passengerPhone;
  String? _preferredLanguageStored;
  String? _cachedPassengerPhotoKey;
  ImageProvider<Object>? _cachedPassengerPhotoProvider;
  List<Ride> _rides = [];
  final List<AppNotification> _notifications = [];
  final Set<int> _acceptedNotifiedRideIds = <int>{};
  final Set<int> _ratedRideIds = <int>{};
  final Map<int, int> _unreadChatByRideId = <int, int>{};
  final Map<int, int> _rideIdByConversationId = <int, int>{};
  final Map<int, int> _conversationIdByRideId = <int, int>{};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  int? _activeChatRideId;
  String? _message;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureSignupPassword = true;
  bool _backendLoginInFlight = false;
  StreamSubscription<GoogleSignInAccount?>? _googleUserSub;
  Timer? _ridesPollingTimer;

  /// `null` means show every ride; otherwise filter by API status string.
  String? _rideStatusFilter;

  List<Ride> get _ridesFiltered {
    final f = _rideStatusFilter;
    if (f == null) return _rides;
    return _rides.where((r) => r.status == f).toList();
  }

  String _formatScheduledDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${_tx('at')} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _tx(String key, [Object? value]) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    final table = _passengerUiTranslations[key];
    return (table?[code] ?? table?['en'] ?? key)
        .replaceAll('{value}', '${value ?? ''}');
  }

  String _scheduledCountdownLabel(Ride ride) {
    final raw = ride.scheduledPickupAt;
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return _tx('pickupWindowOpen');
    if (diff.inDays > 0) {
      return _tx('untilPickup', '${diff.inDays}d ${diff.inHours % 24}h');
    }
    if (diff.inHours > 0) {
      return _tx('untilPickup', '${diff.inHours}h ${diff.inMinutes % 60}m');
    }
    return _tx('untilPickupMinutes', diff.inMinutes.clamp(0, 59));
  }

  String _reservationStatusLabel(Ride ride) {
    final value = (ride.reservationStatus ?? '').trim();
    if (value == 'reserved') return _tx('driverReserved');
    if (value == 'in_progress') return _tx('pickupInProgress');
    if (value == 'completed') return _tx('reservationCompleted');
    if (value == 'cancelled') return _tx('reservationCancelled');
    return ride.driverId == null ? _tx('searching') : _tx('upcomingRide');
  }

  String _rideFilterAllLabel() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return switch (code) {
      'ar' => 'الكل',
      'fr' => 'Tous',
      'de' => 'Alle',
      'es' => 'Todos',
      'it' => 'Tutti',
      'ru' => 'Все',
      'zh' => '全部',
      _ => 'All',
    };
  }

  String _emptyFilterMessage() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return switch (code) {
      'ar' => 'لا توجد رحلات في هذه الفئة.',
      'fr' => 'Aucune course dans cette catégorie.',
      'de' => 'Keine Fahrten in dieser Kategorie.',
      'es' => 'No hay viajes en esta categoría.',
      'it' => 'Nessuna corsa in questa categoria.',
      'ru' => 'Нет поездок в этой категории.',
      'zh' => '此类别中没有行程。',
      _ => 'No rides in this category.',
    };
  }

  String _driverAwaitingAssignmentLabel() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return switch (code) {
      'ar' => 'في انتظار تعيين سائق…',
      'fr' => 'En attente d’un chauffeur…',
      'de' => 'Warten auf einen Fahrer…',
      'es' => 'Esperando conductor…',
      'it' => 'In attesa di un autista…',
      'ru' => 'Ожидание водителя…',
      'zh' => '正在等待指派司机…',
      _ => 'Waiting for a driver…',
    };
  }

  String _driverAssignedGenericLabel() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return switch (code) {
      'ar' => 'سائق معيّن',
      'fr' => 'Chauffeur assigné',
      'de' => 'Fahrer zugewiesen',
      'es' => 'Conductor asignado',
      'it' => 'Autista assegnato',
      'ru' => 'Водитель назначен',
      'zh' => '已指派司机',
      _ => 'Driver assigned',
    };
  }

  String _vehicleSummary(Ride r) {
    final v = (r.driverVehicle ?? '').trim();
    if (v.isNotEmpty) return v;
    final m = (r.driverCarModel ?? '').trim();
    final c = (r.driverCarColor ?? '').trim();
    if (m.isEmpty && c.isEmpty) return '';
    if (m.isEmpty) return c;
    if (c.isEmpty) return m;
    return '$m · $c';
  }

  Widget _rideTripCompact({
    required String label,
    required String value,
    String? subtitle,
    bool isLast = false,
  }) {
    final sub = (subtitle ?? '').trim();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.charcoal.withOpacity(0.45),
                  height: 1.35),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _C.charcoal,
                      height: 1.35),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.charcoal.withOpacity(0.62),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Matches stored ride pickup/destination to `/fares/airport` route keys.
  String? _matchFareRouteKey(String pickup, String dest) {
    if (_fares.isEmpty) return null;
    final pu = pickup.trim();
    final de = dest.trim();
    for (final key in _fares.keys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.length < 2) continue;
      if (parts.first.trim() == pu && parts[1].trim() == de) return key;
    }
    return null;
  }

  Future<({double? km, double? fare})> _resolveRideKmFare(Ride r) async {
    final pv = r.b2bFare ?? r.quotedFareDt;
    if (r.quotedDistanceKm != null && pv != null) {
      return (km: r.quotedDistanceKm, fare: pv);
    }
    var km = r.quotedDistanceKm;
    var fare = pv;
    final routeKey = _matchFareRouteKey(r.pickup, r.destination);
    if (routeKey != null) {
      try {
        final raw = r.scheduledPickupAt ?? r.createdAt;
        final pt = DateTime.tryParse(raw ?? '')?.toUtc() ??
            DateTime.now().toUtc();
        final q = await _api.quoteAirport(routeKey, pricingTime: pt);
        km ??= (q['distance_km'] as num?)?.toDouble();
        if (fare == null) {
          fare = (q['final_fare'] as num?)?.toDouble() ??
              (q['base_fare'] as num?)?.toDouble();
        }
      } catch (_) {}
    }
    return (km: km, fare: fare);
  }

  Widget _rideMetricsStrip({
    required bool kmLoading,
    required bool fareLoading,
    required double? kmVal,
    required double? fareVal,
  }) {
    Widget metricSide(
        {required bool loading,
        required String? text,
        required IconData icon}) {
      if (loading) {
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.charcoal),
        );
      }
      final t = (text == null || text.isEmpty) ? '—' : text;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _C.textSoft),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              t,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.charcoal,
                  letterSpacing: -0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.yellowSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.yellowDeep.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: metricSide(
                loading: kmLoading,
                text: kmVal != null ? '${kmVal.toStringAsFixed(1)} km' : null,
                icon: Icons.straighten_rounded,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
                width: 1, height: 18, color: _C.border.withOpacity(0.55)),
          ),
          Expanded(
            child: Center(
              child: metricSide(
                loading: fareLoading,
                text:
                    fareVal != null ? '${fareVal.toStringAsFixed(2)} DT' : null,
                icon: Icons.payments_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, _ZoneCoord> _zoneCoords = {
    'مطار قرطاج': _ZoneCoord(36.8508, 10.2272),
    'مطار النفيضة': _ZoneCoord(36.0758, 10.4386),
    'مطار المنستير': _ZoneCoord(35.7581, 10.7547),
    'وسط سوسة': _ZoneCoord(35.8256, 10.63699),
    'الحمامات': _ZoneCoord(36.4000, 10.6167),
    'نابل': _ZoneCoord(36.4561, 10.7376),
    'القنطاوي': _ZoneCoord(35.8920, 10.5950),
  };

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: kIsWeb ? null : googleOAuthWebClientId,
  );

  // ALL ORIGINAL LOGIC — identical to previous version, only style references removed
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.passenger);
      final s = widget.initialSession;
      if (s != null && _token == null) _bootstrapFromSession(s);
    });
    if (kIsWeb) {
      _googleUserSub = _googleSignIn.onCurrentUserChanged.listen((account) {
        if (account != null && _token == null && mounted)
          unawaited(_completeLoginWithGoogleAccount(account));
      });
    }
  }

  Future<void> _bootstrapFromSession(AppLoginResponse r) async {
    if (r.role != 'user') {
      await SessionStore.clear();
      if (mounted) {
        setState(() => _message = _tx('passengerAccountRequired'));
      }
      return;
    }
    await SessionStore.saveAppPassenger(r);
    if (!userChoseLocaleThisSession.value)
      applyPreferredLanguageToApp(r.preferredLanguage);
    else {
      try {
        await _api.patchPreferredLanguage(
            token: r.accessToken,
            preferredLanguage: appLocale.value.languageCode);
      } catch (_) {}
    }
    rememberCurrentLocaleForRole(AppUiRole.passenger);
    _token = r.accessToken;
    _userId = r.userId;
    _passengerDisplayName = r.displayName;
    _passengerPhotoUrl = r.photoUrl;
    _passengerEmail = r.email ?? _passengerEmail;
    _passengerPhone = r.phone ?? _passengerPhone;
    _preferredLanguageStored = r.preferredLanguage ?? _preferredLanguageStored;
    _bustPassengerPhotoCache();
    _connectRealtime();
    _startRidesPolling();
    _fares = await _api.getAirportFares();
    await _detectPassengerLocation();
    await _refreshRides();
    await _hydratePassengerProfile();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _ridesPollingTimer?.cancel();
    _socket.disconnect();
    _googleUserSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPhoneCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  void _startRidesPolling() {
    _ridesPollingTimer?.cancel();
    Future<void> tick() async {
      if (!mounted || _token == null) return;
      if (!_busy) {
        await _refreshRides(silent: true);
      } else {
        await _pollChatUnreadFallback();
      }
    }

    unawaited(tick());
    _ridesPollingTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => unawaited(tick()));
  }

  Future<void> _detectPassengerLocation() async {
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
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = l10n.passengerLocationPermissionDenied);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      final nearest = _nearestZoneFor(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _mapLat = position.latitude;
        _mapLng = position.longitude;
        _locationPlaceName = nearest.zone;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

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

  Ride? _firstActiveAppRide() {
    const active = {'pending', 'accepted', 'ongoing'};
    for (final r in _rides) {
      if (active.contains(r.status)) return r;
    }
    return null;
  }

  void _openRideRouteMap(Ride ride) {
    if (!isGoogleMapsPlatformSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carte : lancez l’app avec --dart-define=GOOGLE_MAPS_API_KEY=votre_clé '
            '(Android/iOS). Voir aussi android/local.properties.',
          ),
        ),
      );
      return;
    }
    final gps = (_mapLat != null && _mapLng != null)
        ? LatLng(_mapLat!, _mapLng!)
        : null;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveTripMapScreen(
          role: LiveTripMapRole.passenger,
          myGps: gps,
          focusRide: ride,
        ),
      ),
    );
  }

  void _openPreviewRouteMap({
    required String pickup,
    required String destination,
  }) {
    if (!isGoogleMapsPlatformSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carte : lancez l’app avec --dart-define=GOOGLE_MAPS_API_KEY=votre_clé '
            '(Android/iOS). Voir aussi android/local.properties.',
          ),
        ),
      );
      return;
    }
    final gps = (_mapLat != null && _mapLng != null)
        ? LatLng(_mapLat!, _mapLng!)
        : null;
    final preview = Ride(
      id: 0,
      userId: 0,
      driverId: null,
      status: 'pending',
      pickup: pickup.trim(),
      destination: destination.trim(),
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveTripMapScreen(
          role: LiveTripMapRole.passenger,
          myGps: gps,
          focusRide: preview,
        ),
      ),
    );
  }

  void _openPassengerLiveMap() {
    if (!isGoogleMapsPlatformSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carte : lancez l’app avec --dart-define=GOOGLE_MAPS_API_KEY=votre_clé '
            '(Android/iOS). Voir aussi android/local.properties.',
          ),
        ),
      );
      return;
    }
    final gps = (_mapLat != null && _mapLng != null)
        ? LatLng(_mapLat!, _mapLng!)
        : null;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveTripMapScreen(
          role: LiveTripMapRole.passenger,
          myGps: gps,
          focusRide: _firstActiveAppRide(),
        ),
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  String _editProfileTitle() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return 'تعديل الملف الشخصي';
    if (code.startsWith('fr')) return 'Modifier le profil';
    if (code.startsWith('es')) return 'Editar perfil';
    if (code.startsWith('de')) return 'Profil bearbeiten';
    if (code.startsWith('it')) return 'Modifica profilo';
    if (code.startsWith('ru')) return 'Редактировать профиль';
    if (code.startsWith('zh')) return '编辑资料';
    return 'Edit profile';
  }

  Future<void> _goBack() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PassengerHomeScreen()),
    );
  }

  void _bustPassengerPhotoCache() {
    _cachedPassengerPhotoKey = null;
    _cachedPassengerPhotoProvider = null;
  }

  ImageProvider<Object>? _passengerPhotoProvider() {
    final raw = (_passengerPhotoUrl ?? '').trim();
    if (raw.isEmpty) {
      _cachedPassengerPhotoKey = '';
      _cachedPassengerPhotoProvider = null;
      return null;
    }
    if (raw == _cachedPassengerPhotoKey) return _cachedPassengerPhotoProvider;
    _cachedPassengerPhotoKey = raw;
    _cachedPassengerPhotoProvider = _imageProviderFromString(raw);
    return _cachedPassengerPhotoProvider;
  }

  Future<void> _persistSessionSnapshot() async {
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    await SessionStore.saveAppPassenger(
      AppLoginResponse(
        accessToken: t,
        role: 'user',
        userId: uid,
        preferredLanguage: _preferredLanguageStored,
        displayName: _passengerDisplayName,
        photoUrl: _passengerPhotoUrl,
        email: _passengerEmail,
        phone: _passengerPhone,
      ),
    );
  }

  Future<void> _hydratePassengerProfile() async {
    final t = _token;
    if (t == null) return;
    try {
      final res = await _api.getPassengerMe(token: t);
      final u = res['user'];
      if (u is! Map) return;
      final m = Map<String, dynamic>.from(u);
      if (!mounted) return;
      setState(() {
        _passengerDisplayName =
            (m['display_name'] ?? _passengerDisplayName)?.toString();
        _passengerPhone = (m['phone'] ?? _passengerPhone)?.toString();
        _passengerEmail = (m['email'] ?? _passengerEmail)?.toString();
        final pu = (m['photo_url'] ?? '').toString().trim();
        if (pu.isNotEmpty) _passengerPhotoUrl = pu;
        _preferredLanguageStored =
            (m['preferred_language'] ?? _preferredLanguageStored)?.toString();
        _bustPassengerPhotoCache();
      });
      await _persistSessionSnapshot();
    } catch (_) {}
  }

  Widget _passengerAvatarTile({double size = 56}) {
    final p = _passengerPhotoProvider();
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.yellowDeep),
        color: _C.yellowSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: p == null
          ? Icon(
              Icons.person_rounded,
              color: _C.charcoal.withOpacity(0.55),
              size: size * 0.48,
            )
          : Image(image: p, fit: BoxFit.cover),
    );
  }

  Future<void> _showEditPassengerProfileDialog() async {
    final t = _token;
    if (t == null) return;
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl =
        TextEditingController(text: (_passengerDisplayName ?? '').trim());
    final phoneCtrl =
        TextEditingController(text: (_passengerPhone ?? '').trim());
    final emailCtrl =
        TextEditingController(text: (_passengerEmail ?? '').trim());
    final passwordCtrl = TextEditingController();
    var photoData = (_passengerPhotoUrl ?? '').trim();
    var saving = false;
    String? localErr;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _C.surface,
          surfaceTintColor: _C.surface,
          title: Text(
            _editProfileTitle(),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _C.charcoal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final picked = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1600,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          final name = picked.name.toLowerCase();
                          final ext = name.contains('.')
                              ? name.split('.').last
                              : 'jpeg';
                          final mime = ext == 'png'
                              ? 'image/png'
                              : ext == 'webp'
                                  ? 'image/webp'
                                  : 'image/jpeg';
                          setLocal(() {
                            photoData =
                                'data:$mime;base64,${base64Encode(bytes)}';
                          });
                        },
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.operatorPickFromGallery),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: _fd(l10n.operatorDriverNameLabel,
                      icon: Icons.badge_outlined),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _fd(l10n.operatorPhoneLabel, icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _fd(l10n.emailLabel, icon: Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: _fd('${l10n.passwordLabel} (optional)',
                      icon: Icons.lock_outline_rounded),
                ),
                if (localErr != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(localErr!,
                        style: const TextStyle(color: _C.danger, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(l10n.genericCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() {
                        saving = true;
                        localErr = null;
                      });
                      try {
                        Map<String, dynamic> onlyIfFilled(
                            String k, String raw) {
                          final s = raw.trim();
                          if (s.isEmpty) return {};
                          return {k: s};
                        }

                        final payload = <String, dynamic>{
                          ...onlyIfFilled('display_name', nameCtrl.text),
                          ...onlyIfFilled('phone', phoneCtrl.text),
                          ...onlyIfFilled('email', emailCtrl.text),
                        };
                        if (passwordCtrl.text.trim().isNotEmpty) {
                          payload['password'] = passwordCtrl.text;
                        }
                        final initialPhoto = (_passengerPhotoUrl ?? '').trim();
                        if (photoData.trim().startsWith('data:image/') &&
                            photoData.trim() != initialPhoto) {
                          payload['photo_url'] = photoData.trim();
                        }
                        if (payload.isEmpty) {
                          setLocal(() => saving = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                          return;
                        }

                        final result = await _api.patchPassengerMe(
                            token: t, body: payload);
                        final u = result['user'];
                        if (u is Map && mounted) {
                          final m = Map<String, dynamic>.from(u);
                          setState(() {
                            _passengerDisplayName =
                                (m['display_name'] ?? '').toString().trim();
                            _passengerPhone =
                                (m['phone'] ?? '').toString().trim();
                            _passengerEmail =
                                (m['email'] ?? '').toString().trim();
                            final pu = (m['photo_url'] ?? '').toString().trim();
                            if (pu.isNotEmpty) _passengerPhotoUrl = pu;
                            _preferredLanguageStored =
                                (m['preferred_language'] ??
                                        _preferredLanguageStored)
                                    ?.toString();
                            _bustPassengerPhotoCache();
                          });
                          await _persistSessionSnapshot();
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          saving = false;
                          localErr = e.toString();
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _C.charcoal),
                    )
                  : Text(l10n.dialogOk),
            ),
          ],
        ),
      ),
    );
  }

  void _pushNotification(
      {required String title,
      required String body,
      String? event,
      int? rideId}) {
    final now = DateTime.now();
    final dup = _notifications.isNotEmpty ? _notifications.first : null;
    if (dup != null &&
        dup.event == event &&
        dup.rideId == rideId &&
        now.difference(dup.createdAt).inMilliseconds < 1200) return;
    setState(() {
      _notifications.insert(
          0,
          AppNotification(
              id: '${now.microsecondsSinceEpoch}-${event ?? 'manual'}-${rideId ?? 0}',
              title: title,
              body: body,
              event: event,
              rideId: rideId,
              createdAt: now));
      if (_notifications.length > 60)
        _notifications.removeRange(60, _notifications.length);
    });
  }

  void _showNotifications() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _notifications.isEmpty
              ? Center(
                  child: Text(l10n.notificationsEmpty,
                      style: const TextStyle(color: _C.textMid)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(color: _C.border),
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: n.isRead ? _C.surfaceAlt : _C.yellowSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: n.isRead ? _C.border : _C.yellowDeep)),
                        child: Icon(
                            n.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: n.isRead ? _C.textSoft : _C.charcoal,
                            size: 18),
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w700,
                              fontSize: 13)),
                      subtitle: Text(n.body,
                          style:
                              const TextStyle(color: _C.textMid, fontSize: 12)),
                      trailing: n.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: _C.yellow, shape: BoxShape.circle)),
                      onTap: () {
                        setState(() => n.isRead = true);
                        Navigator.of(ctx).pop();
                        final ride = n.rideId == null
                            ? null
                            : _rides
                                .where((r) => r.id == n.rideId)
                                .cast<Ride?>()
                                .firstWhere((r) => r != null,
                                    orElse: () => null);
                        if (ride != null)
                          _showRideNotificationDetails(ride);
                        else
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(n.body)));
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showRideNotificationDetails(Ride ride) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
        context: context,
        builder: (dCtx) => AlertDialog(
              backgroundColor: _C.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.passengerRideNotificationTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.passengerRideNumberLine(ride.id),
                      style: const TextStyle(
                        color: _C.textMid,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.rideStatusFmt(localizedRideStatusLabel(l10n, ride.status)),
                      style: const TextStyle(color: _C.textMid, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    RideAddressSummaryCard(ride: ride, l: l10n, compact: true),
                  ],
                ),
              ),
              actions: [
                if (isGoogleMapsPlatformSupported)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop();
                      _openRideRouteMap(ride);
                    },
                    child: Text(_tx('openRouteMap')),
                  ),
                TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(),
                    child: Text(l10n.dialogOk))
              ],
            ));
  }

  void _connectRealtime() {
    final t = _token;
    if (t == null) return;
    final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
    final isWebLocal = kIsWeb &&
        (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
    // Local Flutter Web + socket_io_client polling can crash with parser RangeError.
    // Keep ride/chat updates via HTTP polling fallback in this environment.
    if (isWebLocal) return;
    _socket.connect(t, onReceiveMessage: _onChatMessage, onRideStatus: (data) {
      if (!mounted) return;
      final rideMap = data['ride'];
      if (rideMap is Map) {
        final incoming = Ride.fromJson(Map<String, dynamic>.from(rideMap));
        final idx = _rides.indexWhere((r) => r.id == incoming.id);
        final Ride merged =
            idx >= 0 ? incoming.preservingQuotesFrom(_rides[idx]) : incoming;
        setState(() {
          if (idx >= 0) {
            _rides[idx] = merged;
          } else {
            _rides.insert(0, merged);
          }
        });
        final event = (data['event'] ?? '').toString();
        final message = (data['message'] ?? '').toString();
        if (event.isNotEmpty || message.isNotEmpty) {
          if (!mounted) return;
          final pl = AppLocalizations.of(context)!;
          _pushNotification(
            title: pl.notificationRideUpdateTitle,
            body: message.isNotEmpty
                ? message
                : pl.notificationRideUpdatedBody(merged.id),
            event: event,
            rideId: merged.id,
          );
        }
      }
    }, onConnectError: (_) {});
  }

  Future<int?> _resolveRideIdFromChatPayload(Map<String, dynamic> data) async {
    final directRideId = intFromDynamic(data['ride_id']);
    if (directRideId != null) return directRideId;
    final conversationId = intFromDynamic(data['conversation_id']);
    if (conversationId == null) return null;
    final cached = _rideIdByConversationId[conversationId];
    if (cached != null) return cached;
    final t = _token;
    if (t == null) return null;
    for (final ride in _rides.where((r) => rideMayHaveConversation(r.status))) {
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

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token;
    if (t == null) return;
    for (final ride in rides.where((r) => rideMayHaveConversation(r.status))) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
      } catch (_) {}
    }
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    for (final ride in _rides.where(
      (r) => rideMayHaveConversation(r.status) && r.userId == uid,
    )) {
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
            token: t, conversationId: conversationId, limit: 20);
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
              rideId: rid);
          LocalNotificationService.instance
              .show(title: title, body: body, isChat: true);
        }
      } catch (_) {}
    }
  }

  void _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted) return;
    final ChatMessage msg;
    try {
      msg = ChatMessage.fromJson(data);
    } catch (_) {
      return;
    }
    final uid = _userId;
    if (uid == null || msg.senderUserId == uid) return;
    var rideId = await _resolveRideIdFromChatPayload(data);
    if (rideId == null && intFromDynamic(data['conversation_id']) != null) {
      await _refreshRides(silent: true);
      if (!mounted) return;
      rideId = await _resolveRideIdFromChatPayload(data);
    }
    if (!mounted || rideId == null) return;
    final conversationId = intFromDynamic(data['conversation_id']);
    final int rid = rideId;
    if (conversationId != null) {
      final prev = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
      if (msg.id > prev)
        _lastSeenMessageIdByConversationId[conversationId] = msg.id;
      _conversationIdByRideId[rid] = conversationId;
      _rideIdByConversationId[conversationId] = rid;
    }
    if (_activeChatRideId == rid) return;
    final l = AppLocalizations.of(context)!;
    final body =
        msg.displayText.trim().isEmpty ? l.openChatButton : msg.displayText;
    setState(() {
      _unreadChatByRideId[rid] = (_unreadChatByRideId[rid] ?? 0) + 1;
    });
    final sn = (msg.senderName ?? '').trim();
    final title = sn.isEmpty ? l.openChatButton : '${l.openChatButton} • $sn';
    _pushNotification(
        title: title, body: body, event: 'chat_message', rideId: rid);
    LocalNotificationService.instance
        .show(title: title, body: body, isChat: true);
  }

  Future<void> _loginWithGoogle() async {
    if (kIsWeb) return;
    setState(() => _message = null);
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      await _completeLoginWithGoogleAccount(account);
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      setState(() =>
          _message = AppLocalizations.of(context)!.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    }
  }

  Future<void> _completeLoginWithGoogleAccount(
      GoogleSignInAccount account) async {
    if (_backendLoginInFlight || _token != null) return;
    _backendLoginInFlight = true;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      final hasIdToken = idToken != null && idToken.isNotEmpty;
      final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
      if (!hasIdToken && !hasAccessToken) {
        if (!mounted) return;
        setState(() => _message =
            AppLocalizations.of(context)!.errorGoogleSignInMissingToken);
        return;
      }
      AppLoginResponse r;
      try {
        r = await _api.loginGoogle(
            idToken: hasIdToken ? idToken : null,
            accessToken: hasAccessToken ? accessToken : null);
      } on TaxiApiException catch (e) {
        if (e.message == 'phone_required') {
          final phone = await _askPhone();
          if (phone == null || phone.trim().isEmpty) {
            if (!mounted) return;
            setState(() => _message = _tx('phoneNumberRequired'));
            return;
          }
          r = await _api.loginGoogle(
              idToken: hasIdToken ? idToken : null,
              accessToken: hasAccessToken ? accessToken : null,
              phone: phone.trim());
        } else {
          rethrow;
        }
      }
      if (!userChoseLocaleThisSession.value)
        applyPreferredLanguageToApp(r.preferredLanguage);
      else {
        try {
          await _api.patchPreferredLanguage(
              token: r.accessToken,
              preferredLanguage: appLocale.value.languageCode);
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken;
      _userId = r.userId;
      _passengerDisplayName = r.displayName;
      _passengerPhotoUrl = r.photoUrl;
      _passengerEmail = r.email ?? _passengerEmail;
      _passengerPhone = r.phone ?? _passengerPhone;
      _preferredLanguageStored =
          r.preferredLanguage ?? _preferredLanguageStored;
      _bustPassengerPhotoCache();
      await SessionStore.saveAppPassenger(r);
      _connectRealtime();
      _startRidesPolling();
      _fares = await _api.getAirportFares();
      await _detectPassengerLocation();
      await _refreshRides();
      await _hydratePassengerProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.signedInWithGoogle)));
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      setState(() =>
          _message = AppLocalizations.of(context)!.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      _backendLoginInFlight = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPhone() async {
    var phone = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_tx('phoneRequiredTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onChanged: (v) => phone = v,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            decoration: _fd(_tx('phoneNumber'), icon: Icons.phone_outlined)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.genericCancel)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _C.yellow,
                  foregroundColor: _C.charcoal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50))),
              onPressed: () => Navigator.of(ctx).pop(phone.trim()),
              child: Text(_tx('save'),
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _loginWithEmailPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = _tx('fillEmailPassword'));
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginApp(email: email, password: password);
      if (r.role != 'user') {
        await SessionStore.clear();
        if (!mounted) return;
        setState(() => _message = _tx('passengerAccountRequired'));
        return;
      }
      if (!userChoseLocaleThisSession.value)
        applyPreferredLanguageToApp(r.preferredLanguage);
      else {
        try {
          await _api.patchPreferredLanguage(
              token: r.accessToken,
              preferredLanguage: appLocale.value.languageCode);
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken;
      _userId = r.userId;
      _passengerDisplayName = r.displayName;
      _passengerPhotoUrl = r.photoUrl;
      _passengerEmail = r.email ??
          (_emailCtrl.text.trim().isNotEmpty
              ? _emailCtrl.text.trim()
              : _passengerEmail);
      _passengerPhone = r.phone ?? _passengerPhone;
      _preferredLanguageStored =
          r.preferredLanguage ?? _preferredLanguageStored;
      _bustPassengerPhotoCache();
      await SessionStore.saveAppPassenger(r);
      _connectRealtime();
      _startRidesPolling();
      _fares = await _api.getAirportFares();
      await _detectPassengerLocation();
      await _refreshRides();
      await _hydratePassengerProfile();
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      setState(() => _message = l.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerPassengerAccount() async {
    final name = _signupNameCtrl.text.trim();
    final email = _signupEmailCtrl.text.trim();
    final phone = _signupPhoneCtrl.text.trim();
    final password = _signupPasswordCtrl.text;
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _message = _tx('fillRequiredFields'));
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.registerAppUser(
          email: email,
          password: password,
          role: 'user',
          displayName: name,
          phone: phone,
          photoUrl: _signupPhotoData.trim());
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
      await _loginWithEmailPassword();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPassengerSignupImage() async {
    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    if (!mounted) return;
    setState(() {
      _signupPhotoData = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _refreshRides({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) setState(() => _busy = true);
    try {
      final previousById = {for (final r in _rides) r.id: r};
      final list = await _api.listRides(t);
      setState(() {
        _rides = list;
        _message = null;
      });
      await _syncConversationRideMap(list);
      await _pollChatUnreadFallback();
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      for (final ride in list) {
        final prev = previousById[ride.id];
        if (prev == null &&
            ride.status == 'accepted' &&
            !_acceptedNotifiedRideIds.contains(ride.id)) {
          final driver = ride.driverName ?? loc.driverNameFallback;
          final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(
              title: loc.notificationDriverAcceptedTitle,
              body: loc.notificationDriverAcceptedBody(driver, ps),
              event: 'ride_accepted',
              rideId: ride.id);
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (prev == null || prev.status == ride.status) continue;
        if (prev.status == 'pending' && ride.status == 'accepted') {
          final driver = ride.driverName ?? loc.driverNameFallback;
          final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(
              title: loc.notificationDriverAcceptedTitle,
              body: loc.notificationDriverAcceptedBody(driver, ps),
              event: 'ride_accepted',
              rideId: ride.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(loc.notificationDriverAcceptedSnack(driver, ps))));
          LocalNotificationService.instance.show(
              title: loc.notificationDriverAcceptedTitle,
              body: loc.notificationDriverAcceptedBody(driver, ps));
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (ride.status == 'accepted' &&
            (ride.driverCurrentZone ?? '').trim().isNotEmpty &&
            ride.driverCurrentZone!.trim() == ride.pickup.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.passengerDriverNearPickupSnack)));
          LocalNotificationService.instance.show(
              title: loc.notificationDriverNearPickupTitle,
              body: loc.notificationDriverNearPickupBody(ride.pickup));
        }
      }
    } catch (e) {
      if (!silent) setState(() => _message = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestRide() async {
    final l = AppLocalizations.of(context)!;
    if (_fares.isEmpty) {
      setState(() => _message = l.adminNoRidesLoaded);
      return;
    }
    final allRouteKeys = _fares.keys.toList()
      ..sort((a, b) => localizedRouteKeyForDisplay(l, a)
          .compareTo(localizedRouteKeyForDisplay(l, b)));
    if (allRouteKeys.isEmpty) {
      setState(() => _message = l.noRidesYetApp);
      return;
    }

    final allOrigins = allRouteKeys
        .map((k) => k.split(airportRouteKeySeparator).first.trim())
        .toSet()
        .toList();
    String? selectedFrom = (_locationPlaceName ?? '').trim();
    if (!allOrigins.contains(selectedFrom)) {
      selectedFrom = allOrigins.isNotEmpty ? allOrigins.first : null;
    }
    if ((selectedFrom ?? '').isEmpty) {
      setState(() => _message = l.passengerLocationUnavailable);
      return;
    }

    final t0 = _token;
    if (t0 == null) return;

    if (isGoogleMapsPlatformSupported) {
      if (!mounted) return;
      final mapResult = await Navigator.of(context)
          .push<PassengerReservationMapResult?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PassengerReservationMapScreen(
            api: _api,
            l: l,
            allRouteKeys: allRouteKeys,
            fares: _fares,
            initialPickupZone: selectedFrom!,
            passengerGps: (_mapLat != null && _mapLng != null)
                ? LatLng(_mapLat!, _mapLng!)
                : null,
            tx: _tx,
            formatScheduledDateTime: _formatScheduledDateTime,
          ),
        ),
      );
      if (mapResult == null || !mounted) return;
      final routeKey = mapResult.routeKey;
      final parts = routeKey.split(airportRouteKeySeparator);
      final pu = parts.first.trim();
      final de = parts.length > 1 ? parts[1].trim() : '';
      setState(() => _busy = true);
      try {
        await _api.createRide(
          token: t0,
          pickup: pu,
          destination: de,
          scheduledPickupAt:
              mapResult.scheduleLater ? mapResult.scheduledPickupAt : null,
          pickupAddress: mapResult.pickupAddress,
          pickupDisplayName: mapResult.pickupDisplayName,
          destinationAddress: mapResult.destinationAddress,
          destinationDisplayName: mapResult.destinationDisplayName,
          pickupLat: mapResult.pickupLat,
          pickupLng: mapResult.pickupLng,
          destinationLat: mapResult.destinationLat,
          destinationLng: mapResult.destinationLng,
        );
        await _refreshRides();
        if (!mounted) return;
        final promoCode = mapResult.promoCode;
        final title = mapResult.scheduleLater
            ? 'Scheduled ride requested'
            : l.notificationRequestSentTitle;
        final body = mapResult.scheduleLater
            ? 'We are matching your reservation with available drivers.'
            : l.notificationRequestSentBody;
        _pushNotification(
            title: title,
            body: body,
            event: mapResult.scheduleLater
                ? 'scheduled_ride_searching'
                : 'ride_request_sent');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.requestSentSnackLine(
                l.fareDt(mapResult.finalFare.toStringAsFixed(3)),
                promoCode.isEmpty ? '' : ' | $promoCode'))));
        LocalNotificationService.instance.show(title: title, body: body);
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    final promoCtrl = TextEditingController();
    String? selectedTo;
    String? selectedRouteKey;
    String promoCode = '';
    Map<String, dynamic>? quote;
    bool scheduleLater = false;
    DateTime? scheduledPickupAt;
    bool? ok;

    List<String> destinationsFor(String? origin) {
      if ((origin ?? '').trim().isEmpty) return const <String>[];
      return allRouteKeys
          .where((k) {
            final parts = k.split(airportRouteKeySeparator);
            if (parts.length < 2) return false;
            return parts.first.trim() == origin!.trim();
          })
          .map((k) => k.split(airportRouteKeySeparator)[1].trim())
          .toSet()
          .toList()
        ..sort((a, b) =>
            localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
    }

    String? findRouteKey(String? from, String? to) {
      if ((from ?? '').isEmpty || (to ?? '').isEmpty) return null;
      for (final key in allRouteKeys) {
        final parts = key.split(airportRouteKeySeparator);
        if (parts.length < 2) continue;
        if (parts.first.trim() == from!.trim() &&
            parts[1].trim() == to!.trim()) {
          return key;
        }
      }
      return null;
    }

    Future<void> recalcQuote(StateSetter ss) async {
      final key = selectedRouteKey;
      if (key == null) {
        ss(() => quote = null);
        return;
      }
      try {
        final DateTime pricingTime = scheduleLater && scheduledPickupAt != null
            ? scheduledPickupAt!.toUtc()
            : DateTime.now().toUtc();
        final q = await _api.quoteAirport(key, pricingTime: pricingTime);
        final merged = Map<String, dynamic>.from(q);
        var finalFare = (merged['final_fare'] as num?)?.toDouble() ??
            (merged['base_fare'] as num?)?.toDouble() ??
            (_fares[key] ?? 0);
        if (promoCtrl.text.trim() == 'WELCOME26') {
          finalFare *= 0.8;
        }
        merged['final_fare'] = double.parse(finalFare.toStringAsFixed(3));
        merged['route_key'] = key;
        ss(() => quote = merged);
      } catch (_) {
        ss(() => quote = null);
      }
    }

    Future<String?> pickDestination() async {
      final base = destinationsFor(selectedFrom);
      if (base.isEmpty) return null;
      String query = '';
      List<String> filtered() {
        final q = query.trim().toLowerCase();
        final out = base.where((d) {
          if (q.isEmpty) return true;
          return d.toLowerCase().contains(q) ||
              localizedPlaceName(l, d).toLowerCase().contains(q);
        }).toList();
        out.sort((a, b) =>
            localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
        return out.take(12).toList();
      }

      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _C.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, ss) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _C.border,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration:
                      _fd('Search destination', icon: Icons.search_rounded),
                  onChanged: (v) => ss(() => query = v),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: filtered()
                        .map((d) {
                          final ap = AirportPlaceHeuristics.zoneKeyLooksLikeAirport(d);
                          return ListTile(
                            leading: Icon(
                              ap ? Icons.flight_takeoff_rounded : Icons.place_outlined,
                              color: ap ? const Color(0xFF0D47A1) : _C.textMid,
                            ),
                            tileColor: ap
                                ? const Color(0xFFE3F2FD).withValues(alpha: 0.75)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              localizedPlaceName(l, d),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ap ? const Color(0xFF0D47A1) : _C.charcoal,
                              ),
                            ),
                            onTap: () => Navigator.pop(ctx, d),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> pickScheduledPickup(StateSetter ss) async {
      final now = DateTime.now();
      final initial = scheduledPickupAt ?? now.add(const Duration(hours: 12));
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: now,
        lastDate: now.add(const Duration(days: 30)),
      );
      if (date == null) return;
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return;
      final picked =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      ss(() => scheduledPickupAt = picked);
    }

    ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            14,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                              color: _C.border,
                              borderRadius: BorderRadius.circular(999)))),
                  const SizedBox(height: 18),
                  _SectionLabel(_tx('reserveRideTitle')),
                  const SizedBox(height: 8),
                  Text(
                    _tx('reserveRideBody'),
                    style: const TextStyle(color: _C.textSoft, fontSize: 12),
                  ),
                  if (isGoogleMapsPlatformSupported) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: (selectedTo ?? '').trim().isEmpty
                            ? null
                            : () {
                                final key =
                                    findRouteKey(selectedFrom, selectedTo);
                                if (key == null) return;
                                final parts =
                                    key.split(airportRouteKeySeparator);
                                final pu = parts.first.trim();
                                final de = parts.length > 1
                                    ? parts[1].trim()
                                    : '';
                                if (pu.isEmpty || de.isEmpty) return;
                                _openPreviewRouteMap(
                                    pickup: pu, destination: de);
                              },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: Text(_tx('openRouteMap')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _C.border)),
                    child: Row(children: [
                      Expanded(
                          child: _ScheduleModeChip(
                              label: _tx('rideNow'),
                              selected: !scheduleLater,
                              onTap: () => ss(() => scheduleLater = false))),
                      Expanded(
                          child: _ScheduleModeChip(
                              label: _tx('scheduleRide'),
                              selected: scheduleLater,
                              onTap: () => ss(() => scheduleLater = true))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  if (scheduleLater)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => pickScheduledPickup(ss),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_C.surface, _C.yellowSoft]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _C.yellowDeep),
                        ),
                        child: Row(children: [
                          const Icon(Icons.event_available_rounded,
                              color: _C.yellowDeep, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              scheduledPickupAt == null
                                  ? _tx('choosePickupDateTime')
                                  : _formatScheduledDateTime(
                                      scheduledPickupAt!),
                              style: const TextStyle(
                                  color: _C.charcoal,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: _C.yellowDeep),
                        ]),
                      ),
                    ),
                  if (scheduleLater) const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded,
                            color: _C.charcoal, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l.ridePickupLabel}: ${localizedPlaceName(l, selectedFrom!)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await pickDestination();
                      if (picked == null) return;
                      selectedTo = picked;
                      selectedRouteKey = findRouteKey(selectedFrom, selectedTo);
                      await recalcQuote(ss);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              color: _C.charcoal, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedTo == null
                                  ? _tx('selectDestination')
                                  : localizedPlaceName(l, selectedTo!),
                              style: TextStyle(
                                fontWeight: selectedTo == null
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 13,
                                color: selectedTo == null
                                    ? _C.textSoft
                                    : _C.charcoal,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: _C.textSoft),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((selectedTo ?? '').isNotEmpty && quote != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.border),
                      ),
                      child: Text(
                        '${localizedPlaceName(l, selectedTo!)} • ${((quote!['distance_km'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km • ${((quote!['final_fare'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} DT',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if ((selectedTo ?? '').isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _tx('tapDestinationHint'),
                      style: const TextStyle(color: _C.textSoft, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                      controller: promoCtrl,
                      decoration: _fd(l.promoCodeOptionalLabel,
                          icon: Icons.discount_outlined),
                      onChanged: (_) async {
                        promoCode = promoCtrl.text.trim();
                        await recalcQuote(ss);
                      }),
                  const SizedBox(height: 16),
                  if (quote != null) ...[
                    NightFareBreakdown(
                      quote: quote!,
                      promoLabel: promoCtrl.text.trim() == 'WELCOME26'
                          ? 'WELCOME26 −20%'
                          : null,
                      nightRateLabel: l.nightFare50,
                      baseLabel: l.fareAmount.split('(').first.trim(),
                      surchargeLabel: 'Night surcharge',
                      totalLabel: 'Total',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.nightFareScheduleHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _C.textSoft, fontSize: 11, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(children: [
                    Expanded(
                        child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                    color: _C.surfaceAlt,
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: _C.border)),
                                child: Center(
                                    child: Text(l.genericCancel,
                                        style: const TextStyle(
                                            color: _C.textMid,
                                            fontWeight: FontWeight.w700)))))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _YellowButton(
                            label: scheduleLater
                                ? _tx('reserveDriver')
                                : l.requestRideButton,
                            fontSize: 11,
                            onPressed: quote == null ||
                                    (selectedTo ?? '').isEmpty ||
                                    (scheduleLater && scheduledPickupAt == null)
                                ? null
                                : () {
                                    promoCode = promoCtrl.text.trim();
                                    Navigator.pop(ctx, true);
                                  })),
                  ]),
                ]),
          ),
        ),
      ),
    );
    promoCtrl.dispose();
    if (ok != true || !mounted) return;
    final t = _token;
    final q = quote;
    if (t == null || q == null) return;
    final routeKey = q['route_key'] as String?;
    if (routeKey == null) return;
    final parts = routeKey.split(airportRouteKeySeparator);
    final pu = parts.first.trim();
    final de = parts.length > 1 ? parts[1].trim() : '';
    setState(() => _busy = true);
    try {
      await _api.createRide(
        token: t,
        pickup: pu,
        destination: de,
        scheduledPickupAt: scheduleLater ? scheduledPickupAt : null,
      );
      await _refreshRides();
      if (!mounted) return;
      final title = scheduleLater
          ? 'Scheduled ride requested'
          : l.notificationRequestSentTitle;
      final body = scheduleLater
          ? 'We are matching your reservation with available drivers.'
          : l.notificationRequestSentBody;
      _pushNotification(
          title: title,
          body: body,
          event:
              scheduleLater ? 'scheduled_ride_searching' : 'ride_request_sent');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.requestSentSnackLine(
              l.fareDt((q['final_fare'] as num).toStringAsFixed(3)),
              promoCode.isEmpty ? '' : ' | $promoCode'))));
      LocalNotificationService.instance.show(title: title, body: body);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.cancelRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rateCompletedRide(Ride ride) async {
    final t = _token;
    if (t == null || ride.status != 'completed') return;
    int stars = 5;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _C.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.rateYourLastRide,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final s = i + 1;
                return IconButton(
                    icon: Icon(
                        stars >= s
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _C.yellow,
                        size: 32),
                    onPressed: () => ss(() => stars = s));
              })),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.genericCancel)),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _C.yellow,
                    foregroundColor: _C.charcoal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50))),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.submitRating,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.submitRating(token: t, rideId: ride.id, stars: stars);
      if (!mounted) return;
      setState(() => _ratedRideIds.add(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.thankYouFeedback)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
    final l = AppLocalizations.of(context)!;
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    setState(() => _busy = true);
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.chatUnavailable)));
        return;
      }
      final cid = info.conversationId;
      setState(() {
        _activeChatRideId = ride.id;
        _unreadChatByRideId.remove(ride.id);
      });
      _rideIdByConversationId[cid] = ride.id;
      _conversationIdByRideId[ride.id] = cid;
      await Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
                token: t,
                myUserId: uid,
                rideId: ride.id,
                conversationId: cid,
                minimalTripHeader: true,
              )));
      if (mounted && _activeChatRideId == ride.id)
        setState(() => _activeChatRideId = null);
      await _primeReadWatermarkAfterChat(
          token: t, conversationId: cid, rideId: ride.id);
      await _refreshRides();
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      if (e.message == 'forbidden' || e.message == 'chat_not_open') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.chatUnavailable)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted && _activeChatRideId == ride.id)
        setState(() => _activeChatRideId = null);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    if (kIsWeb) unawaited(_googleSignIn.signOut());
    unawaited(SessionStore.clear());
    _ridesPollingTimer?.cancel();
    _socket.disconnect();
    setState(() {
      _token = null;
      _userId = null;
      _rides = [];
      _notifications.clear();
      _unreadChatByRideId.clear();
      _rideIdByConversationId.clear();
      _conversationIdByRideId.clear();
      _lastSeenMessageIdByConversationId.clear();
      _activeChatRideId = null;
      _message = null;
      _passengerDisplayName = null;
      _passengerPhotoUrl = null;
      _passengerEmail = null;
      _passengerPhone = null;
      _preferredLanguageStored = null;
      _bustPassengerPhotoCache();
    });
  }

  Widget _chatActionButton(Ride ride) {
    final l = AppLocalizations.of(context)!;
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return Badge(
      label: Text(unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      padding:
          EdgeInsets.only(left: unread > 0 ? 5 : 0, right: unread > 0 ? 5 : 0),
      isLabelVisible: unread > 0,
      offset: const Offset(10, -6),
      backgroundColor: _C.danger,
      child: GestureDetector(
        onTap: _busy ? null : () => _openChat(ride),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _C.yellowSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.yellowDeep.withOpacity(0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_rounded,
                  color: _C.charcoal, size: 14),
              const SizedBox(width: 5),
              Text(l.openChatButton,
                  style: const TextStyle(
                      color: _C.charcoal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'accepted' => _C.success,
        'ongoing' => _C.info,
        'completed' => _C.textMid,
        'cancelled' => _C.danger,
        _ => _C.amber,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const activeStatuses = {'pending', 'accepted', 'ongoing'};
    final hasActiveRide = _rides.any((r) => activeStatuses.contains(r.status));
    final activeCount =
        _rides.where((r) => activeStatuses.contains(r.status)).length;

    final filteredRides = _ridesFiltered;
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.yellow,
        foregroundColor: _C.charcoal,
        centerTitle: true,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, color: _C.charcoal),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: const Text(
          'Voom',
          style: TextStyle(
              color: _C.charcoal, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.passenger,
            foregroundColor: _C.charcoal,
          ),
          if (_token != null) ...[
            IconButton(
              onPressed: _showNotifications,
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_rounded, color: _C.charcoal),
                if (_unreadCount > 0)
                  Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            color: _C.danger,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(_unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      )),
              ]),
            ),
            IconButton(
                onPressed: _busy ? null : _refreshRides,
                icon: const Icon(Icons.refresh_rounded, color: _C.charcoal)),
            IconButton(
              onPressed: _openPassengerLiveMap,
              tooltip: 'Carte',
              icon: const Icon(Icons.map_rounded, color: _C.charcoal),
            ),
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _C.yellow.withOpacity(0.65))),
                child: Text(l.logoutApp,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          if (_token == null) ...[
            // Sign-in
            _TaxiCard(
                accent: true,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(_tx('signInSection')),
                      const SizedBox(height: 14),
                      TextField(
                          controller: _emailCtrl,
                          decoration: _fd(l.emailLabel,
                              icon: Icons.alternate_email_rounded)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _fd(l.passwordLabel,
                                icon: Icons.lock_outline_rounded)
                            .copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _C.charcoal,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const PassengerForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          child: Text('${l.passengerForgotPasswordAppBar}?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _YellowButton(
                          label: l.signInApp,
                          icon: Icons.login_rounded,
                          onPressed: _busy ? null : _loginWithEmailPassword),
                    ])),
            // Google
            if (kIsWeb)
              const PassengerGoogleGsiButton()
            else
              GestureDetector(
                onTap: _busy ? null : _loginWithGoogle,
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _C.border)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.g_mobiledata_rounded,
                            color: _C.charcoal, size: 22),
                        const SizedBox(width: 8),
                        Text(l.continueWithGoogle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _C.textStrong)),
                      ]),
                ),
              ),
            _TaxiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(_tx('createAccountSection')),
                  const SizedBox(height: 10),
                  Text(
                    _tx('newHereSignup'),
                    style: const TextStyle(color: _C.textSoft, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _YellowButton(
                    label: l.registerAppAccount,
                    icon: Icons.person_add_rounded,
                    onPressed: _busy
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PassengerSignupScreen(),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ] else ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFF8E0),
                    Color(0xFFFFD84D)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _C.yellowDeep.withOpacity(0.20),
                      blurRadius: 38,
                      offset: const Offset(0, 18)),
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
                          border:
                              Border.all(color: _C.yellow.withOpacity(0.65)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: _C.yellowDeep, size: 14),
                            const SizedBox(width: 6),
                            Text(_tx('nextGenTransfer'),
                                style: const TextStyle(
                                    color: _C.charcoal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.3)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _passengerAvatarTile(size: 42),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    (_passengerDisplayName ?? '').trim().isEmpty
                        ? _tx('premiumRideReady')
                        : _tx('welcomeBack', _passengerDisplayName!.trim()),
                    style: const TextStyle(
                        color: _C.charcoal,
                        fontSize: 25,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_locationPlaceName ?? '').trim().isEmpty
                        ? _tx('bookingHeroBody')
                        : _tx('pickupLocked',
                            localizedPlaceName(l, _locationPlaceName)),
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
                          child: _statBadge(
                              l.passengerActiveRidesChip(activeCount),
                              _C.neonBlue)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statBadge(
                              _tx('totalRidesShort', _rides.length),
                              _C.yellow)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TaxiCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _passengerAvatarTile(size: 56),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_passengerDisplayName ?? '').trim().isEmpty
                              ? l.passengerTitle
                              : _passengerDisplayName!.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _C.charcoal,
                          ),
                        ),
                        if ((_passengerPhone ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _passengerPhone!.trim(),
                              style: const TextStyle(
                                  fontSize: 13, color: _C.textMid),
                            ),
                          ),
                        if ((_passengerEmail ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _passengerEmail!.trim(),
                              style: const TextStyle(
                                  fontSize: 12, color: _C.textSoft),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : _showEditPassengerProfileDialog,
                    tooltip: _editProfileTitle(),
                    icon: const Icon(Icons.edit_outlined, color: _C.charcoal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Book
            _TaxiCard(
                accent: true,
                padding: 18,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_C.yellowLight, _C.yellowDeep]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: _C.yellowDeep.withOpacity(0.28),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10))
                                ]),
                            child: const Icon(Icons.flight_takeoff_rounded,
                                color: _C.charcoal, size: 25)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(l.passengerBookingSectionTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: -0.2)),
                              const SizedBox(height: 3),
                              Text(_tx('airportTransferScheduled'),
                                  style: const TextStyle(
                                      color: _C.textSoft,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ])),
                      ]),
                      const SizedBox(height: 16),
                      _YellowButton(
                          label: hasActiveRide
                              ? _tx('rideAlreadyActive')
                              : _tx('reservePremiumRide'),
                          icon: Icons.bolt_rounded,
                          onPressed:
                              _busy || hasActiveRide ? null : _requestRide),
                    ])),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                      color: _C.yellow,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Text(l.myRidesHeading,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_rideFilterAllLabel()),
                      selected: _rideStatusFilter == null,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() => _rideStatusFilter = null);
                      },
                      selectedColor: _C.yellowSoft,
                      checkmarkColor: _C.charcoal,
                      labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.charcoal),
                    ),
                  ),
                  ...[
                    ('pending', l.rideStatusPending),
                    ('accepted', l.rideStatusAccepted),
                    ('ongoing', l.rideStatusOngoing),
                    ('completed', l.rideStatusCompleted),
                    ('cancelled', l.rideStatusCancelled),
                  ].map((e) {
                    final code = e.$1;
                    final label = e.$2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(label),
                        selected: _rideStatusFilter == code,
                        onSelected: (v) {
                          setState(() => _rideStatusFilter = v ? code : null);
                        },
                        selectedColor: _C.yellowSoft,
                        checkmarkColor: _C.charcoal,
                        labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _C.charcoal),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_rides.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text(l.noRidesYetApp,
                          style: const TextStyle(color: _C.textSoft))))
            else if (filteredRides.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text(_emptyFilterMessage(),
                          style: const TextStyle(color: _C.textSoft))))
            else
              ...filteredRides.map((r) => _rideCard(r, l)),
          ],
          if (_message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: _C.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.danger.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: _C.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_message!,
                        style: const TextStyle(color: _C.danger, fontSize: 13)))
              ]),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(
                child: CircularProgressIndicator(
                    color: _C.yellow, strokeWidth: 2.5))
          ],
        ],
      ),
    );
  }

  Widget _statBadge(String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: bg.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: bg, fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _rideCard(Ride r, AppLocalizations l) {
    final sc = _statusColor(r.status);
    final provider = _imageProviderFromString(r.driverPhotoUrl);
    final vehicle = _vehicleSummary(r);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: _C.charcoal.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: _C.yellow),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<({double? km, double? fare})>(
                              key: ValueKey(
                                'rf-${r.id}-${r.pickup}-${r.destination}-${r.quotedDistanceKm}-${r.b2bFare}-${r.quotedFareDt}-${r.updatedAt}',
                              ),
                              future: _resolveRideKmFare(r),
                              builder: (context, snap) {
                                final resolved = snap.data;
                                final kmVal =
                                    resolved?.km ?? r.quotedDistanceKm;
                                final fareVal = resolved?.fare ??
                                    (r.b2bFare ?? r.quotedFareDt);
                                final pending = snap.connectionState !=
                                    ConnectionState.done;
                                return _rideMetricsStrip(
                                  kmLoading: pending && kmVal == null,
                                  fareLoading: pending && fareVal == null,
                                  kmVal: kmVal,
                                  fareVal: fareVal,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sc.withOpacity(0.11),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sc.withOpacity(0.28)),
                            ),
                            child: Text(
                              localizedRideStatusLabel(l, r.status),
                              style: TextStyle(
                                  color: sc,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _rideTripCompact(
                          label: l.ridePickupLabel,
                          value: ridePickupTitle(r, l),
                          subtitle: ridePickupAddressLine(r, l)),
                      _rideTripCompact(
                        label: l.rideDestinationLabel,
                        value: rideDestinationTitle(r, l),
                        subtitle: rideDestinationAddressLine(r, l),
                        isLast: true,
                      ),
                      if ((r.scheduledPickupAt ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_C.surface, _C.yellowSoft]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _C.yellowDeep.withOpacity(0.85)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _C.yellow.withOpacity(0.28),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: _C.yellowDeep, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reservationStatusLabel(r),
                                      style: const TextStyle(
                                          color: _C.charcoal,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _scheduledCountdownLabel(r),
                                      style: const TextStyle(
                                          color: _C.yellowDeep,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.timeline_rounded,
                                  color: _C.yellowDeep, size: 20),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: _C.border.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _C.yellowSoft,
                            backgroundImage: provider,
                            child: provider == null
                                ? Icon(Icons.person_rounded,
                                    color: _C.charcoal.withOpacity(0.7),
                                    size: 20)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.driverTitle,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: _C.charcoal.withOpacity(0.45)),
                                ),
                                const SizedBox(height: 2),
                                if ((r.driverName ?? '').trim().isNotEmpty)
                                  Text(
                                    r.driverName!.trim(),
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: _C.charcoal,
                                        height: 1.25),
                                  )
                                else if (r.driverId != null && r.driverId! > 0)
                                  Text(_driverAssignedGenericLabel(),
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: _C.textMid))
                                else
                                  Text(
                                    _driverAwaitingAssignmentLabel(),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _C.textSoft,
                                        fontStyle: FontStyle.italic,
                                        height: 1.25),
                                  ),
                                if (vehicle.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      vehicle,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: _C.textMid,
                                          height: 1.25),
                                    ),
                                  ),
                                if ((r.driverPhone ?? '').trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      l.passengerPhoneLine(
                                          r.driverPhone!.trim()),
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: _C.textMid),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (isGoogleMapsPlatformSupported)
                            GestureDetector(
                              onTap: _busy
                                  ? null
                                  : () => _openRideRouteMap(r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _C.yellowSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: _C.yellowDeep.withOpacity(0.45)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.map_rounded,
                                        color: _C.charcoal, size: 14),
                                    const SizedBox(width: 5),
                                    Text(_tx('openRouteMap'),
                                        style: const TextStyle(
                                            color: _C.charcoal,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ),
                          if (r.status != 'completed' &&
                              r.status != 'cancelled')
                            GestureDetector(
                              onTap: _busy ? null : () => _cancelRide(r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _C.dangerBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: _C.danger.withOpacity(0.32)),
                                ),
                                child: Text(l.cancelRidePassenger,
                                    style: const TextStyle(
                                        color: _C.danger,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          _chatActionButton(r),
                          if (r.status == 'completed' &&
                              !_ratedRideIds.contains(r.id))
                            GestureDetector(
                              onTap: _busy ? null : () => _rateCompletedRide(r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _C.yellowSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: _C.yellowDeep.withOpacity(0.55)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: _C.charcoal, size: 14),
                                    const SizedBox(width: 4),
                                    Text(l.submitRating,
                                        style: const TextStyle(
                                            color: _C.charcoal,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _phoneSuffix(String? phone) {
    final p = (phone ?? '').trim();
    return p.isEmpty ? '' : ' ($p)';
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
}

class _ZoneCoord {
  const _ZoneCoord(this.lat, this.lng);
  final double lat;
  final double lng;
}
