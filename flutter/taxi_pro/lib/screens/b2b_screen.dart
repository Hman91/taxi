import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import '../app_locale.dart'
    show
        AppUiRole,
        rememberCurrentLocaleForRole,
        restoreUiRoleLocale,
        userChoseLocaleThisSession,
        appLocale;
import '../config.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
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
import 'ride_chat_screen.dart';
import 'unified_login_screen.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const bgWarm = Color(0xFFFAF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF111111);
  static const textMid = Color(0xFF3F3F3F);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE4E4);
}

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  prefixIcon: icon == null ? null : Icon(icon, color: _C.charcoal, size: 18),
  filled: true,
  fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.border, width: 1.4),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.yellow, width: 2),
  ),
);

class _Module extends StatelessWidget {
  const _Module({required this.child, this.accent = false});
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
          boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
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
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.border),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
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
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
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
  final Map<String, ImageProvider<Object>?> _photoProviderCache = <String, ImageProvider<Object>?>{};
  final Set<int> _ratedRideIds = <int>{};
  final Map<int, int> _ratingByRideId = <int, int>{};
  int? _activeChatRideId;
  int? _pendingRatingRideId;
  Timer? _pollingTimer;
  String? _message;
  bool _busy = false;
  bool _obscureSecret = true;
  bool _ok = false;
  bool _requestFormExpanded = true;
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
    final name = (claims['display_name'] ?? claims['name'] ?? '').toString().trim();
    final phone = (claims['phone'] ?? '').toString().trim();
    final code = (claims['source_code'] ?? claims['code'] ?? '').toString().trim();
    if (!mounted) return;
    setState(() {
      if (name.isNotEmpty) _b2bDisplayName = name;
      if (email.isNotEmpty) _b2bEmail = email;
      if (phone.isNotEmpty) _b2bPhone = phone;
      if (code.isNotEmpty) _b2bCode = code;
      if (_b2bDisplayName.trim().isEmpty) {
        _b2bDisplayName = _b2bEmail.isNotEmpty ? _b2bEmail : 'B2B #${_userId ?? ''}';
      }
    });
  }

  Future<void> _hydrateB2bProfileFromApi(String token) async {
    try {
      final data = await _api.getB2bMe(token);
      if (!mounted) return;
      final user = Map<String, dynamic>.from((data['user'] as Map?) ?? const {});
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

  ({String? zone, double? distanceMeters}) _nearestZoneFor(double lat, double lng) {
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
        if ((nearest.zone ?? '').trim().isNotEmpty) {
          final starts = _fares.keys
              .map((k) => k.split(airportRouteKeySeparator).first.trim())
              .toSet();
          if (starts.contains(nearest.zone!.trim())) {
            final keys = _filteredRouteKeys()
                .where((k) => k.split(airportRouteKeySeparator).first.trim() == nearest.zone!.trim())
                .toList();
            if (keys.isNotEmpty) _routeKey = keys.first;
          }
        }
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

  void _syncRouteSelectionForCurrentOption() {
    final keys = _filteredRouteKeys();
    if (keys.isEmpty) {
      _routeKey = null;
      _destinationController.clear();
      return;
    }
    if (_routeKey == null || !keys.contains(_routeKey)) {
      _routeKey = keys.first;
    }
    final parts = (_routeKey ?? '').split(airportRouteKeySeparator);
    if (parts.length >= 2) {
      _destinationController.text = parts[1].trim();
    }
  }

  List<String> _destinationChoices() {
    final keys = _filteredRouteKeys();
    final set = <String>{};
    for (final key in keys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.length < 2) continue;
      final dest = parts[1].trim();
      if (dest.isNotEmpty) set.add(dest);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _destinationSuggestions() {
    final query = _destinationController.text.trim().toLowerCase();
    final base = _destinationChoices();
    if (query.isEmpty) return base.take(10).toList();
    return base
        .where((d) => d.toLowerCase().contains(query))
        .take(10)
        .toList();
  }

  String? _resolveRouteFromDestination(String destination) {
    final target = destination.trim().toLowerCase();
    if (target.isEmpty) return null;
    final keys = _filteredRouteKeys();
    if (keys.isEmpty) return null;
    final exact = keys.where((k) {
      final parts = k.split(airportRouteKeySeparator);
      return parts.length >= 2 && parts[1].trim().toLowerCase() == target;
    }).toList();
    if (exact.isNotEmpty) return exact.first;
    final fuzzy = keys.where((k) {
      final parts = k.split(airportRouteKeySeparator);
      return parts.length >= 2 && parts[1].trim().toLowerCase().contains(target);
    }).toList();
    if (fuzzy.isNotEmpty) return fuzzy.first;
    return null;
  }

  String? _routeForSuggestion(String suggestion) {
    final dest = suggestion.trim();
    if (dest.isEmpty) return null;
    return _resolveRouteFromDestination(dest);
  }

  double? _routeDistanceKm(String? routeKey) {
    if ((routeKey ?? '').trim().isEmpty) return null;
    final parts = routeKey!.split(airportRouteKeySeparator);
    if (parts.length < 2) return null;
    final start = _zoneCoords[parts.first.trim()];
    final dest = _zoneCoords[parts[1].trim()];
    if (start == null || dest == null) return null;
    final m = Geolocator.distanceBetween(start.lat, start.lng, dest.lat, dest.lng);
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
          title: const Text('Edit B2B Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd('E-mail', icon: Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: obscureNext,
                  decoration: _fd('New password (optional)', icon: Icons.password_rounded).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setLocal(() => obscureNext = !obscureNext),
                      icon: Icon(obscureNext ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: displayNameCtrl,
                  decoration: _fd('Name', icon: Icons.person_outline_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fd('Phone', icon: Icons.phone_outlined),
                ),
                if ((error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: _C.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: localBusy ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
                          final dn = (user['display_name'] ?? '').toString().trim();
                          if (dn.isNotEmpty) _b2bDisplayName = dn;
                          final sc = (user['source_code'] ?? '').toString().trim();
                          if (sc.isNotEmpty) _b2bCode = sc;
                          _b2bLabel = (tenant['label'] ?? _b2bLabel).toString();
                          _b2bContactName =
                              (tenant['contact_name'] ?? _b2bContactName).toString();
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
              child: const Text('Save'),
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
        const SnackBar(content: Text('Account updated successfully.')),
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
        if (_b2bDisplayName.trim().isEmpty || _b2bDisplayName == 'B2B account') {
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
        _syncRouteSelectionForCurrentOption();
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

  void _bookGuest() {
    final l = AppLocalizations.of(context)!;
    final guest = _guestController.text.trim();
    final destination = _destinationController.text.trim();
    final route = _resolveRouteFromDestination(destination) ?? _routeKey;
    final token = _token;
    if (guest.isEmpty || destination.isEmpty || route == null || token == null) {
      setState(() => _message = l.loginFirst);
      return;
    }
    final room = _roomController.text.trim();
    final guestPhone = _guestPhoneController.text.trim();
    final hotel = _hotelController.text.trim();
    final flightEta = _flightEtaController.text.trim();
    final fare = _fareForRouteKey(route);
    _api
        .createB2bBooking(
      token: token,
      route: route,
      guestName: guest,
      guestPhone: guestPhone,
      hotelName: hotel,
      flightEta: flightEta,
      roomNumber: room,
      fare: fare,
      sourceCode: (_b2bCode.isNotEmpty ? _b2bCode : _secretController.text.trim()),
    )
        .then((booking) {
      if (!mounted) return;
      _refreshRides();
      setState(() {
        _message = l.b2bBookingSuccessMessage(
          l.requestRideButton,
          booking['id'] as Object,
          guest,
          localizedRouteKeyForDisplay(l, route),
        );
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    });
  }

  void _connectRealtime(String token) {
    final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
    final isWebLocal =
        kIsWeb && (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
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
      rideId =
          _rideIdByConversationId[convId] ?? await _resolveB2bRideIdForConversation(convId);
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
          _lastSeenMessageIdByConversationId.putIfAbsent(info.conversationId, () => 0);
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(tick()));
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
        final delta = computeUnreadChatDelta(msgs: msgs, myUserId: uid, storedWatermark: stored);
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
          LocalNotificationService.instance.show(title: title, body: body, isChat: true);
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
            ? SizedBox(height: 180, child: Center(child: Text(l.notificationsEmpty)))
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
          SnackBar(content: Text(AppLocalizations.of(context)!.chatUnavailable)),
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
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _activeChatRideId = null;
        _unreadChatByRideId.remove(ride.id);
      });
      await _primeReadWatermarkAfterChat(token: t, conversationId: cid, rideId: ride.id);
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
      final resolved = _resolveRouteFromDestination(_destinationController.text);
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
      _syncRouteSelectionForCurrentOption();
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
    final activeCount = _rides.where((r) => activeStatuses.contains(r.status)).length;
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
      _routeKey = routeKeys.isNotEmpty ? routeKeys.first : null;
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
          style: const TextStyle(color: _C.yellow, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: _C.charcoal,
        foregroundColor: Colors.white,
        actions: [
          LocalePopupMenuButton(authToken: _appToken ?? _token, uiRole: AppUiRole.b2b),
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _C.yellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(color: Color(0xFF111111), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        children: [
          if (!_ok)
            _Module(
            accent: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHead(l.b2bPortalHeading, subtitle: 'Corporate access'),
                  TextField(
                    controller: _secretController,
                    obscureText: _obscureSecret,
                    decoration: _fd(l.companyCode, icon: Icons.business_rounded).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                        icon: Icon(
                          _obscureSecret ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      onPressed: _busy ? null : _login,
                      child: Text(l.verifyCompanyCode, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  _Module(
                    accent: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHead('Portal Status', subtitle: '${l.passengerActiveRidesChip(activeCount)} • ${l.passengerTotalRidesChip(_rides.length)}'),
                        InkWell(
                          onTap: _busy ? null : () => unawaited(_showB2bAccountDialog()),
                          borderRadius: BorderRadius.circular(12),
                          child: _rowInfoCard(
                            icon: Icons.account_circle_outlined,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _b2bDisplayName,
                                  style: const TextStyle(
                                    color: _C.textStrong,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (_b2bEmail.isNotEmpty ? _b2bEmail : 'Tap to open account details') +
                                      (_b2bPhone.isNotEmpty ? ' · $_b2bPhone' : ''),
                                  style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _b2bCode.trim().isEmpty
                                      ? 'Code unavailable'
                                      : 'Code: ${_b2bCode.trim()}',
                                  style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                ),
                                if (_b2bContactName.trim().isNotEmpty || _b2bPin.trim().isNotEmpty)
                                  Text(
                                    'Name: ${_b2bContactName.trim().isEmpty ? '-' : _b2bContactName} | PIN: ${_b2bPin.trim().isEmpty ? '-' : _b2bPin}',
                                    style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                  ),
                                if (_b2bTenantPhone.trim().isNotEmpty || _b2bHotel.trim().isNotEmpty)
                                  Text(
                                    'Phone: ${_b2bTenantPhone.trim().isEmpty ? '-' : _b2bTenantPhone} | Hotel: ${_b2bHotel.trim().isEmpty ? '-' : _b2bHotel}',
                                    style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.edit_outlined, size: 18, color: _C.textMid),
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
                            subtitle: _uiText(
                              en: 'Light request flow',
                              ar: 'نموذج طلب خفيف',
                              fr: 'Formulaire de demande leger',
                              es: 'Formulario de solicitud ligero',
                              de: 'Leichtes Anfrageformular',
                              it: 'Modulo richiesta leggero',
                              ru: 'Легкая форма запроса',
                              zh: '轻量请求表单',
                            ),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _requestFormExpanded,
                              onExpansionChanged: (v) => setState(() => _requestFormExpanded = v),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: _C.surfaceAlt,
                              collapsedBackgroundColor: _C.surfaceAlt,
                              title: Text(
                                _uiText(
                                  en: 'New ride request',
                                  ar: 'طلب رحلة جديد',
                                  fr: 'Nouvelle demande',
                                  es: 'Nueva solicitud',
                                  de: 'Neue Anfrage',
                                  it: 'Nuova richiesta',
                                  ru: 'Новый запрос',
                                  zh: '新行程请求',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              subtitle: Text(
                                _uiText(
                                  en: 'Tap to open/close form',
                                  ar: 'اضغط لفتح/إغلاق النموذج',
                                  fr: 'Touchez pour ouvrir/fermer',
                                  es: 'Toca para abrir/cerrar',
                                  de: 'Tippen zum Öffnen/Schließen',
                                  it: 'Tocca per aprire/chiudere',
                                  ru: 'Нажмите, чтобы открыть/закрыть',
                                  zh: '点击展开/收起表单',
                                ),
                                style: const TextStyle(fontSize: 11, color: _C.textSoft),
                              ),
                              children: [
                                const SizedBox(height: 10),
                                TextField(
                            controller: _guestController,
                            decoration: _fd(
                              _uiText(
                                en: 'Guest name',
                                ar: 'اسم الضيف',
                                fr: 'Nom du client',
                                es: 'Nombre del cliente',
                                de: 'Name des Gastes',
                                it: 'Nome ospite',
                                ru: 'Имя гостя',
                                zh: '客人姓名',
                              ),
                            ),
                          ),
                          TextField(
                            controller: _guestPhoneController,
                            decoration: _fd(
                              _uiText(
                                en: 'Guest phone',
                                ar: 'هاتف الضيف',
                                fr: 'Telephone du client',
                                es: 'Telefono del cliente',
                                de: 'Telefon des Gastes',
                                it: 'Telefono ospite',
                                ru: 'Телефон гостя',
                                zh: '客人电话',
                              ),
                            ),
                          ),
                          TextField(
                            controller: _hotelController,
                            decoration: _fd(
                              _uiText(
                                en: 'Hotel',
                                ar: 'الفندق',
                                fr: 'Hotel',
                                es: 'Hotel',
                                de: 'Hotel',
                                it: 'Hotel',
                                ru: 'Отель',
                                zh: '酒店',
                              ),
                            ),
                          ),
                          TextField(
                            controller: _flightEtaController,
                            decoration: _fd(
                              _uiText(
                                en: 'Flight ETA / Stopover',
                                ar: 'موعد الرحلة / التوقف',
                                fr: 'ETA vol / Escale',
                                es: 'ETA vuelo / Escala',
                                de: 'Flug ETA / Zwischenstopp',
                                it: 'ETA volo / Scalo',
                                ru: 'ETA рейса / пересадка',
                                zh: '航班到达时间/经停',
                              ),
                            ),
                          ),
                          TextField(
                            controller: _roomController,
                            decoration: _fd(
                              _uiText(
                                en: 'Room number',
                                ar: 'رقم الغرفة',
                                fr: 'Numero de chambre',
                                es: 'Numero de habitacion',
                                de: 'Zimmernummer',
                                it: 'Numero camera',
                                ru: 'Номер комнаты',
                                zh: '房间号',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _locationText != null
                                          ? 'GPS: $_locationText'
                                          : (_locationError ??
                                              (_locating
                                                  ? l.passengerLocationDetecting
                                                  : l.passengerLocationUnavailable)),
                                      style: const TextStyle(
                                          color: _C.textSoft, fontSize: 11),
                                    ),
                                    if (_nearestZoneDistanceKm != null &&
                                        (_nearestZoneName ?? '').trim().isNotEmpty)
                                      Text(
                                        'Nearest zone: ${localizedPlaceName(l, _nearestZoneName)} (${_nearestZoneDistanceKm!.toStringAsFixed(1)} km)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _distanceColor(_nearestZoneDistanceKm!),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _locating ? null : () => unawaited(_detectB2bLocation()),
                                icon: const Icon(Icons.my_location_rounded, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _rowInfoCard(
                            icon: Icons.my_location_rounded,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Departure: ${_nearestZoneName != null ? localizedPlaceName(l, _nearestZoneName) : l.passengerLocationCurrent}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _locationText != null
                                      ? 'GPS: $_locationText'
                                      : (_locationError ??
                                          (_locating ? l.passengerLocationDetecting : l.passengerLocationUnavailable)),
                                  style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: _locating ? null : () => unawaited(_detectB2bLocation()),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _destinationController,
                            focusNode: _destinationFocus,
                            decoration: _fd(
                              _uiText(
                                en: 'Destination',
                                ar: 'الوجهة',
                                fr: 'Destination',
                                es: 'Destino',
                                de: 'Ziel',
                                it: 'Destinazione',
                                ru: 'Пункт назначения',
                                zh: '目的地',
                              ),
                              icon: Icons.place_outlined,
                            ).copyWith(
                              suffixIcon: _destinationController.text.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _destinationController.clear();
                                          _routeKey = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_destinationFocus.hasFocus) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              decoration: BoxDecoration(
                                color: _C.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.border),
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _destinationSuggestions().map((s) {
                                  final route = _routeForSuggestion(s);
                                  final km = _routeDistanceKm(route);
                                  final fare = route == null ? null : _fareForRouteKey(route);
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on_outlined, size: 16),
                                    title: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    subtitle: (km == null && fare == null)
                                        ? null
                                        : Text(
                                            '${km?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt((fare ?? 0).toStringAsFixed(2))}',
                                            style: const TextStyle(fontSize: 11, color: _C.textSoft),
                                          ),
                                    onTap: () {
                                      _destinationController.text = s;
                                      final resolved = route ?? _resolveRouteFromDestination(s);
                                      if (resolved != null) {
                                        setState(() => _routeKey = resolved);
                                      }
                                      _destinationFocus.unfocus();
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (_routeKey != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _rowInfoCard(
                                icon: Icons.route_rounded,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizedRouteKeyForDisplay(l, _routeKey!),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_routeDistanceKm(_routeKey)?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt(_fareForRouteKey(_routeKey).toStringAsFixed(2))} ${l.b2bFareAdminPercentSuffix}',
                                      style: const TextStyle(
                                          color: _C.textSoft, fontSize: 11),
                                    ),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              onPressed: _busy ? null : _bookGuest,
                              child: Text(
                                l.requestRideButton,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionHead(l.myRidesHeading, subtitle: '${filteredRides.length} rides'),
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
                        onTap: () => setState(() => _rideFilter = _B2bRideFilter.all),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'pending'),
                        selected: _rideFilter == _B2bRideFilter.pending,
                        onTap: () => setState(() => _rideFilter = _B2bRideFilter.pending),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'accepted'),
                        selected: _rideFilter == _B2bRideFilter.accepted,
                        onTap: () => setState(() => _rideFilter = _B2bRideFilter.accepted),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'cancelled'),
                        selected: _rideFilter == _B2bRideFilter.cancelled,
                        onTap: () => setState(() => _rideFilter = _B2bRideFilter.cancelled),
                      ),
                      _statusFilterChip(
                        label: localizedRideStatusLabel(l, 'completed'),
                        selected: _rideFilter == _B2bRideFilter.completed,
                        onTap: () => setState(() => _rideFilter = _B2bRideFilter.completed),
                      ),
                    ],
                  ),
                  _Module(
                    child: filteredRides.isEmpty
                        ? Text(l.noRidesYetApp, style: const TextStyle(color: _C.textSoft))
                        : Column(
                            children: filteredRides
                                .map(
                                  (r) => Container(
                                    key: ValueKey<String>('b2b-ride-${r.id}-chat-${_rideUnread(r.id)}'),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _rowInfoCard(
                                          icon: Icons.local_taxi_outlined,
                                          content: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(localizedRideRouteRow(l, r.pickup, r.destination), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Text(
                                                l.rideStatusFmt(localizedRideStatusLabel(l, r.status)),
                                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Depart: ${localizedPlaceName(l, r.pickup)} • Destination: ${localizedPlaceName(l, r.destination)}',
                                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                              ),
                                              Builder(
                                                builder: (_) {
                                                  final route = '${r.pickup}$airportRouteKeySeparator${r.destination}';
                                                  final fare = _fareForRouteKey(route);
                                                  final km = _routeDistanceKm(route);
                                                  return Text(
                                                    '${km?.toStringAsFixed(1) ?? '-'} km • ${l.fareDt(fare.toStringAsFixed(2))}',
                                                    style: const TextStyle(color: _C.textSoft, fontSize: 11),
                                                  );
                                                },
                                              ),
                                              if (r.status == 'pending')
                                                Text(
                                                  'Chauffeur en cours...',
                                                  style: const TextStyle(
                                                    color: _C.yellowDeep,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              if ((r.driverName ?? '').trim().isNotEmpty ||
                                                  (r.driverPhone ?? '').trim().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  l.passengerDriverLine((r.driverName ?? '').trim().isEmpty ? l.driverNameFallback : r.driverName!),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                                if ((r.driverPhone ?? '').trim().isNotEmpty)
                                                  Text(l.passengerPhoneLine(r.driverPhone!), style: const TextStyle(fontSize: 11)),
                                              ],
                                            ],
                                          ),
                                          trailing: (r.driverPhotoUrl ?? '').trim().isNotEmpty
                                              ? Builder(
                                                  builder: (context) {
                                                    final provider = _stableImageProviderFromString(r.driverPhotoUrl);
                                                    if (provider == null) return const SizedBox.shrink();
                                                    return CircleAvatar(radius: 16, backgroundImage: provider);
                                                  },
                                                )
                                              : null,
                                        ),
                                        Wrap(
                                          clipBehavior: Clip.none,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (r.status != 'completed' && r.status != 'cancelled')
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: _C.textMid,
                                                  side: const BorderSide(color: _C.border),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                                ),
                                                onPressed: _busy ? null : () => _cancelRide(r),
                                                child: Text(l.cancelRidePassenger),
                                              ),
                                            Builder(
                                              builder: (ctx) {
                                                final uChat = _rideUnread(r.id);
                                                return Badge(
                                                  label: Text(
                                                    uChat > 99 ? '99+' : '$uChat',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _C.charcoal),
                                                  ),
                                                  padding: EdgeInsets.only(left: uChat > 0 ? 5 : 0, right: uChat > 0 ? 5 : 0),
                                                  isLabelVisible: uChat > 0,
                                                  offset: const Offset(8, -6),
                                                  backgroundColor: _C.yellow,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: _C.surfaceAlt,
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: _C.border),
                                                    ),
                                                    child: TextButton.icon(
                                                      onPressed: _busy ? null : () => _openChat(r),
                                                      icon: const Icon(Icons.chat_bubble_rounded, color: _C.charcoal, size: 16),
                                                      label: Text(
                                                        l.openChatButton,
                                                        style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w700),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (r.status == 'completed' &&
                                                (_pendingRatingRideId == r.id || !_ratedRideIds.contains(r.id)))
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  ...List.generate(5, (i) {
                                                    final star = i + 1;
                                                    final selected = (_ratingByRideId[r.id] ?? 0) >= star;
                                                    return InkWell(
                                                      borderRadius: BorderRadius.circular(20),
                                                      onTap: _busy ? null : () => setState(() => _ratingByRideId[r.id] = star),
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          color: selected ? _C.yellowSoft : _C.surfaceAlt,
                                                          borderRadius: BorderRadius.circular(20),
                                                          border: Border.all(color: selected ? _C.yellowDeep : _C.border),
                                                        ),
                                                        child: Icon(
                                                          selected ? Icons.star_rounded : Icons.star_border_rounded,
                                                          color: selected ? _C.yellowDeep : _C.textSoft,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                  FilledButton(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: _C.yellow,
                                                      foregroundColor: _C.charcoal,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      minimumSize: const Size(0, 30),
                                                    ),
                                                    onPressed: _busy || ((_ratingByRideId[r.id] ?? 0) < 1) ? null : () => _submitRideRating(r.id),
                                                    child: Text(l.submitRating, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
