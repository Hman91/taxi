import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app_locale.dart' show
    AppUiRole,
    applyPreferredLanguageToApp,
    appLocale,
    rememberCurrentLocaleForRole,
    restoreUiRoleLocale,
    userChoseLocaleThisSession;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../config.dart';
import '../services/local_notification_service.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/driver_ride_offer_card.dart';
import 'ride_chat_screen.dart';
import 'unified_login_screen.dart';

// ── Design tokens (mirrors owner_screen._C) ──────────────────
class _C {
  static const yellow      = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft  = Color(0xFFFFF8E0);
  static const yellowDeep  = Color(0xFFE6A800);
  static const charcoal    = Color(0xFF1A1A1A);
  static const charcoalMid = Color(0xFF2C2C2C);
  static const bgWarm      = Color(0xFFFAF8F2);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF5F1E8);
  static const border      = Color(0xFFDDD8C8);
  static const textStrong  = Color(0xFF111111);
  static const textMid     = Color(0xFF3F3F3F);
  static const textSoft    = Color(0xFF5C5C5C);
  static const danger      = Color(0xFFB91C1C);
  static const dangerBg    = Color(0xFFFFE4E4);
  static const success     = Color(0xFF1A7A4A);
  static const successBg   = Color(0xFFD4EDDA);
  static const info        = Color(0xFF1E3A8A);
  static const infoBg      = Color(0xFFDEEBFF);
}

// ── Shared UI helpers (mirrors owner_screen) ─────────────────

InputDecoration _fd(String label, {IconData? icon, String? suffix}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
  prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
  suffixText: suffix,
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, required this.onPressed, this.icon, this.small = false, this.fullWidth = true});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small; final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 38 : 48,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? _C.yellowSoft : _C.yellow,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled ? [] : [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: _C.charcoal, size: small ? 14 : 18), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: _C.charcoal, fontWeight: FontWeight.w900, fontSize: small ? 12 : 14, letterSpacing: 0.2)),
        ])),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed, this.icon, this.small = false, this.fullWidth = true});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small; final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 38 : 48,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFCCCCCC) : _C.charcoal,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled ? [] : [BoxShadow(color: _C.charcoal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: small ? 14 : 18), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 12 : 14, letterSpacing: 0.2)),
        ])),
      ),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({required this.child, this.padding = 16.0, this.accent = false});
  final Widget child; final double padding; final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
      boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title; final String? subtitle; final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
        if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
      ])),
      if (trailing != null) trailing!,
    ]),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, this.color = _C.charcoal});
  final String label; final String value; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
    ]),
  );
}

Widget _rowInfoCard({
  required IconData icon,
  required Widget content,
  Widget? trailing,
  Color iconBg = _C.surfaceAlt,
  Color iconColor = _C.charcoal,
}) => Container(
  margin: const EdgeInsets.only(bottom: 8),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: _C.surfaceAlt,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _C.border),
  ),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.border)),
      child: Center(child: Icon(icon, color: iconColor, size: 16)),
    ),
    const SizedBox(width: 10),
    Expanded(child: content),
    if (trailing != null) ...[const SizedBox(width: 8), trailing],
  ]),
);

// ─────────────────────────────────────────────────────────────
// DRIVER SCREEN
// ─────────────────────────────────────────────────────────────
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key, this.initialSession});
  final DriverPinLoginResponse? initialSession;

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _socket = ChatSocketService();
  final _phoneController = TextEditingController(text: '98123456');
  final _pinController = TextEditingController(text: '1234');
  List<String> _locations = [];
  String _location = '';
  String? _token;
  int? _userId;
  int? _driverId;
  String? _driverName;
  double _walletBalance = 0.0;
  Map<String, dynamic>? _gains;
  bool _isAvailable = true;
  String _historyFilter = 'all';
  String? _carModel;
  String? _carColor;
  String? _photoUrl;
  String? _message;
  List<Ride> _rides = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  final List<AppNotification> _notifications = [];
  final Set<int> _seenPendingRideIds = <int>{};
  final Set<int> _notifiedClosedRideIds = <int>{};
  Set<int> _lastPendingRideIds = <int>{};
  final Set<int> _selfAcceptedRideIds = <int>{};
  final Set<int> _dismissedPendingRideIds = <int>{};
  final Map<int, int> _unreadChatByRideId = <int, int>{};
  final Map<int, int> _rideIdByConversationId = <int, int>{};
  final Map<int, int> _conversationIdByRideId = <int, int>{};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  int? _activeChatRideId;
  bool _busy = false;
  Timer? _ridesPollingTimer;
  TabController? _tabController;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Widget _appBarHomeLogo() => GestureDetector(
    onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UnifiedLoginScreen())),
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(9)),
      child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 18),
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.driver);
      final s = widget.initialSession;
      if (s != null && _token == null) _bootstrapFromSession(s);
    });
  }

  Future<void> _bootstrapFromSession(DriverPinLoginResponse r) async {
    final l = AppLocalizations.of(context)!;
    if (!userChoseLocaleThisSession.value) applyPreferredLanguageToApp(r.preferredLanguage);
    rememberCurrentLocaleForRole(AppUiRole.driver);
    setState(() {
      _token = r.accessToken; _userId = r.userId; _driverId = r.driverId;
      _driverName = r.driverName; _walletBalance = r.walletBalance; _isAvailable = true;
      _carModel = r.carModel; _carColor = r.carColor; _photoUrl = r.photoUrl;
      _unreadChatByRideId.clear(); _rideIdByConversationId.clear();
      _conversationIdByRideId.clear(); _lastSeenMessageIdByConversationId.clear();
      _activeChatRideId = null; _message = l.loggedInAs(r.role);
    });
    final fares = await _api.getAirportFares();
    final locations = _startsFromRouteKeys(fares.keys, l);
    setState(() {
      _locations = locations;
      if (_location.isEmpty || !_locations.contains(_location)) {
        _location = _locations.isNotEmpty ? _locations.first : '';
      }
    });
    await _refreshRides();
    await _refreshGains();
    await _refreshArrivals(silent: true);
    _socket.connect(r.accessToken, onReceiveMessage: _onChatMessage, onRideStatus: _onRideStatusEvent, onDriverWallet: _onDriverWallet, transports: const ['polling']);
    _startRidesPolling();
    await _pushDriverLocation();
  }

  void _pushNotification({required String title, required String body, String? event, int? rideId}) {
    final now = DateTime.now();
    setState(() {
      _notifications.insert(0, AppNotification(id: '${now.microsecondsSinceEpoch}-${event ?? 'manual'}-${rideId ?? 0}', title: title, body: body, createdAt: now, event: event, rideId: rideId));
      if (_notifications.length > 60) _notifications.removeRange(60, _notifications.length);
    });
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: _C.charcoal,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.notifications_none_rounded, size: 40, color: _C.textSoft),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.notificationsEmpty, style: const TextStyle(color: _C.textSoft)),
                    ]))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: n.isRead ? _C.surfaceAlt : _C.yellowSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: n.isRead ? _C.border : _C.yellowDeep),
                          ),
                          child: ListTile(
                            leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: n.isRead ? _C.surfaceAlt : _C.yellow, borderRadius: BorderRadius.circular(9)), child: Icon(n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: n.isRead ? _C.textSoft : _C.charcoal, size: 16)),
                            title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13, color: _C.textStrong)),
                            subtitle: Text(n.body, style: const TextStyle(fontSize: 11, color: _C.textSoft)),
                            onTap: () { setState(() => n.isRead = true); Navigator.of(context).pop(); },
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l = AppLocalizations.of(context)!;
    setState(() { _busy = true; _message = null; });
    try {
      final r = await _api.loginDriverPin(phone: _phoneController.text.trim(), pin: _pinController.text.trim());
      if (!userChoseLocaleThisSession.value) { applyPreferredLanguageToApp(r.preferredLanguage); }
      else { try { await _api.patchPreferredLanguage(token: r.accessToken, preferredLanguage: appLocale.value.languageCode); } catch (_) {} }
      rememberCurrentLocaleForRole(AppUiRole.driver);
      setState(() {
        _token = r.accessToken; _userId = r.userId; _driverId = r.driverId;
        _driverName = r.driverName; _walletBalance = r.walletBalance; _isAvailable = true;
        _carModel = r.carModel; _carColor = r.carColor; _photoUrl = r.photoUrl;
        _unreadChatByRideId.clear(); _rideIdByConversationId.clear();
        _conversationIdByRideId.clear(); _lastSeenMessageIdByConversationId.clear();
        _activeChatRideId = null; _message = l.loggedInAs(r.role);
      });
      final fares = await _api.getAirportFares();
      final locations = _startsFromRouteKeys(fares.keys, l);
      setState(() {
        _locations = locations;
        if (_location.isEmpty || !_locations.contains(_location)) _location = _locations.isNotEmpty ? _locations.first : '';
      });
      await _refreshRides();
      await _refreshGains();
      await _refreshArrivals(silent: true);
      final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
      final isWebLocal = kIsWeb && (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
      if (!isWebLocal) _socket.connect(r.accessToken, onReceiveMessage: _onChatMessage, onRideStatus: _onRideStatusEvent, onDriverWallet: _onDriverWallet, transports: const ['polling']);
      _startRidesPolling();
      await _pushDriverLocation();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshRides({bool silent = false}) async {
    final t = _token; if (t == null) return;
    if (!silent) setState(() { _busy = true; _message = null; });
    try {
      final previousById = {for (final r in _rides) r.id: r};
      final rides = await _api.listRides(t);
      if (_driverId == null) { for (final r in rides) { if (r.driverId != null) { _driverId = r.driverId; break; } } }
      setState(() => _rides = rides);
      await _syncConversationRideMap(rides);
      await _pollChatUnreadFallback();
      if (mounted) _processRideTransitions(previousById, rides);
    } catch (e) { if (!silent) setState(() => _message = e.toString()); }
    finally { if (!silent && mounted) setState(() => _busy = false); }
  }

  Future<void> _refreshGains() async {
    final t = _token; if (t == null) return;
    try {
      final g = await _api.driverGains(t);
      if (!mounted) return;
      setState(() { _gains = g; _isAvailable = (g['is_available'] == true); });
    } catch (_) {}
  }

  Future<void> _refreshArrivals({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) {
      setState(() {
        _busy = true;
        _message = null;
      });
    }
    try {
      final flights = await _api.listAdminTunisiaFlightArrivals(t);
      if (!mounted) return;
      setState(() => _flightArrivals = flights);
    } catch (e) {
      if (!silent && mounted) setState(() => _message = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  String _arrivalAirportLabel(Map<String, dynamic> row) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') {
      return row['arrival_airport_ar']?.toString() ??
          row['arrival_airport_en']?.toString() ??
          '';
    }
    return row['arrival_airport_en']?.toString() ??
        row['arrival_airport_ar']?.toString() ??
        '';
  }

  String _departureAirportLabel(Map<String, dynamic> row) {
    final city = (row['departure_city'] ?? '').toString().trim();
    final country = (row['departure_country'] ?? '').toString().trim();
    final iata = (row['departure_iata'] ?? '').toString().trim().toUpperCase();
    if (city.isNotEmpty && country.isNotEmpty && iata.isNotEmpty) {
      return '$city, $country ($iata)';
    }
    return (row['departure_airport'] ?? '').toString();
  }

  String _prettyDateTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    final normalized = s.replaceFirst(' - ', 'T').replaceFirst(' ', 'T');
    final dt = DateTime.tryParse(normalized) ?? DateTime.tryParse(s);
    if (dt == null) return s;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final mon = months[local.month - 1];
    final year = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day $mon $year – $hh:$mm';
  }

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token; if (t == null) return;
    final candidates = rides.where((r) => r.status == 'accepted' || r.status == 'ongoing').toList();
    for (final ride in candidates) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
      } catch (_) {}
    }
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _token; final uid = _userId; if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    final pairs = _conversationIdByRideId.entries.toList();
    for (final entry in pairs) {
      final rideId = entry.key; final conversationId = entry.value;
      if (_activeChatRideId == rideId) continue;
      try {
        final msgs = await _api.listConversationMessages(token: t, conversationId: conversationId, limit: 20);
        if (msgs.isEmpty) continue;
        final prevSeen = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
        int maxId = prevSeen; int incomingCount = 0; ChatMessage? latestIncoming;
        for (final m in msgs) {
          if (m.id > maxId) maxId = m.id;
          if (prevSeen > 0 && m.id > prevSeen && m.senderUserId != uid) {
            incomingCount++;
            if (latestIncoming == null || m.id > latestIncoming.id) latestIncoming = m;
          }
        }
        if (prevSeen == 0) { _lastSeenMessageIdByConversationId[conversationId] = maxId; continue; }
        if (incomingCount > 0) {
          if (!mounted) return;
          setState(() { _unreadChatByRideId[rideId] = (_unreadChatByRideId[rideId] ?? 0) + incomingCount; });
          final body = (latestIncoming?.displayText.trim().isNotEmpty ?? false) ? latestIncoming!.displayText : l.openChatButton;
          final senderName = (latestIncoming?.senderName ?? '').trim();
          final title = senderName.isEmpty ? l.openChatButton : '${l.openChatButton} • $senderName';
          _pushNotification(title: title, body: body, event: 'chat_message_fallback', rideId: rideId);
          LocalNotificationService.instance.show(title: title, body: body);
        }
        _lastSeenMessageIdByConversationId[conversationId] = maxId;
      } catch (_) {}
    }
  }

  void _processRideTransitions(Map<int, Ride> previousById, List<Ride> rides) {
    if (_socket.isConnected) { _lastPendingRideIds = rides.where((r) => r.status == 'pending').map((r) => r.id).toSet(); return; }
    final loc = AppLocalizations.of(context)!;
    final currentById = {for (final r in rides) r.id: r};
    final currentPendingRideIds = rides.where((r) => r.status == 'pending').map((r) => r.id).toSet();
    final removedPending = _lastPendingRideIds.difference(currentPendingRideIds);
    for (final rideId in removedPending) {
      if (_selfAcceptedRideIds.contains(rideId)) { _selfAcceptedRideIds.remove(rideId); continue; }
      final stillVisible = currentById[rideId];
      if (stillVisible != null && _driverId != null && stillVisible.driverId == _driverId) continue;
      if (_notifiedClosedRideIds.contains(rideId)) continue;
      _notifiedClosedRideIds.add(rideId);
      _pushNotification(title: loc.driverNotificationRequestClosedTitle, body: loc.driverNotificationRequestClosedBodyOther, event: 'ride_no_longer_visible', rideId: rideId);
    }
    _lastPendingRideIds = currentPendingRideIds;
    for (final ride in rides) {
      final prev = previousById[ride.id];
      if (prev == null && ride.status == 'pending') {
        _seenPendingRideIds.add(ride.id);
        _pushNotification(title: loc.driverNotificationNewRideTitle, body: loc.driverNotificationNewRideBodyDefault, event: 'ride_request_sent', rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.snackDriverNewNearbyRide)));
        LocalNotificationService.instance.show(title: loc.driverNotificationNewRideTitle, body: loc.driverNotificationNewRideBodyDefault);
      } else if (prev != null && prev.status == 'pending' && ride.status == 'accepted') {
        if (_selfAcceptedRideIds.contains(ride.id) || (_driverId != null && ride.driverId == _driverId)) { _selfAcceptedRideIds.remove(ride.id); continue; }
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(title: loc.driverNotificationRequestClosedTitle, body: loc.driverNotificationRequestClosedBodyTaken, event: 'ride_taken_by_other_driver', rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.snackDriverRideTakenOther)));
        LocalNotificationService.instance.show(title: loc.driverNotificationRequestClosedTitle, body: loc.driverNotificationRequestClosedBodyTaken);
      } else if (prev != null && prev.status != 'cancelled' && ride.status == 'cancelled') {
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(title: loc.driverNotificationCancelledTitle, body: loc.driverNotificationCancelledBodyDefault, event: 'ride_cancelled_by_passenger', rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.snackDriverPassengerCancelled)));
        LocalNotificationService.instance.show(title: loc.driverNotificationCancelledTitle, body: loc.driverNotificationCancelledBodyDefault);
      }
      if (ride.status != 'pending') _seenPendingRideIds.remove(ride.id);
    }
    for (final prev in previousById.values) {
      if (prev.status == 'pending' && !currentById.containsKey(prev.id) && _seenPendingRideIds.contains(prev.id) && !_notifiedClosedRideIds.contains(prev.id)) {
        _notifiedClosedRideIds.add(prev.id);
        _pushNotification(title: loc.driverNotificationRequestClosedTitle, body: loc.driverNotificationRequestClosedBodyOther, event: 'ride_no_longer_visible', rideId: prev.id);
        _seenPendingRideIds.remove(prev.id);
      }
    }
  }

  void _startRidesPolling() {
    _ridesPollingTimer?.cancel();
    _ridesPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) { if (!mounted || _token == null || _busy) return; _refreshRides(silent: true); });
  }

  Future<void> _pushDriverLocation() async {
    final t = _token; if (t == null || _location.isEmpty) return;
    try { await _api.updateDriverLocation(token: t, currentZone: _location, isAvailable: _isAvailable); } catch (_) {}
  }

  Future<void> _setAvailability(bool v) async {
    final t = _token; if (t == null) return;
    setState(() => _isAvailable = v);
    try {
      await _api.updateDriverLocation(token: t, currentZone: _location, isAvailable: v);
      await _refreshGains();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.statusLinePrefix}${localizedRideStatusLabel(l, v ? 'active' : 'cancelled')}')));
      }
    } catch (e) { if (!mounted) return; setState(() { _isAvailable = !v; _message = e.toString(); }); }
  }

  void _onDriverWallet(Map<String, dynamic> data) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final wb = data['wallet_balance'];
    if (wb is num) setState(() => _walletBalance = wb.toDouble());
    final event = (data['event'] ?? '').toString();
    if (event != 'wallet_depleted') return;
    final amount = (data['required_topup_dt'] as num?)?.round() ?? 100;
    final body = ((data['message'] ?? '').toString().trim().isNotEmpty) ? (data['message'] as String).trim() : loc.driverWalletDepletedBody(amount);
    _pushNotification(title: loc.driverWalletDepletedTitle, body: body, event: 'wallet_depleted');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
    LocalNotificationService.instance.show(title: loc.driverWalletDepletedTitle, body: body);
  }

  void _onRideStatusEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final event = (payload['event'] ?? '').toString();
    final serverMessage = (payload['message'] ?? '').toString().trim();
    if (event == 'ride_taken_by_other_driver') {
      final accepterUserId = (payload['accepted_driver_user_id'] as num?)?.toInt() ?? (payload['driver_id'] as num?)?.toInt();
      if (accepterUserId != null && _userId != null && accepterUserId == _userId) return;
      _pushNotification(title: loc.driverNotificationRequestClosedTitle, body: serverMessage.isNotEmpty ? serverMessage : loc.driverNotificationRequestClosedBodyTaken, event: event);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMessage.isNotEmpty ? serverMessage : loc.snackDriverRideTakenOther)));
      LocalNotificationService.instance.show(title: loc.driverNotificationRequestClosedTitle, body: serverMessage.isNotEmpty ? serverMessage : loc.driverNotificationRequestClosedBodyTaken);
      _refreshRides(); return;
    }
    if (event == 'ride_request_sent') {
      _pushNotification(title: loc.driverNotificationNewRideTitle, body: serverMessage.isNotEmpty ? serverMessage : loc.driverNotificationNewRideBodyDefault, event: event);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMessage.isNotEmpty ? serverMessage : loc.snackDriverNewNearbyRide)));
      LocalNotificationService.instance.show(title: loc.driverNotificationNewRideTitle, body: serverMessage.isNotEmpty ? serverMessage : loc.driverNotificationNewRideBodyDefault);
      _refreshRides(); return;
    }
    if (serverMessage.isNotEmpty) {
      _pushNotification(title: loc.notificationRideUpdateTitle, body: serverMessage, event: event.isEmpty ? 'ride_status_changed' : event);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMessage)));
      LocalNotificationService.instance.show(title: loc.notificationRideUpdateTitle, body: serverMessage);
      _refreshRides();
    }
  }

  Future<int?> _resolveRideIdFromChatPayload(Map<String, dynamic> data) async {
    final directRideId = (data['ride_id'] as num?)?.toInt();
    if (directRideId != null) return directRideId;
    final conversationId = (data['conversation_id'] as num?)?.toInt();
    if (conversationId == null) return null;
    final cached = _rideIdByConversationId[conversationId];
    if (cached != null) return cached;
    final t = _token; if (t == null) return null;
    final candidates = _rides.where((r) => r.status == 'accepted' || r.status == 'ongoing').toList();
    for (final ride in candidates) {
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

  void _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted) return;
    final msg = ChatMessage.fromJson(data);
    if (msg.senderUserId == _userId) return;
    final rideId = await _resolveRideIdFromChatPayload(data);
    if (!mounted) return; if (rideId == null) return; if (_activeChatRideId == rideId) return;
    final conversationId = (data['conversation_id'] as num?)?.toInt();
    if (conversationId != null) {
      _lastSeenMessageIdByConversationId[conversationId] = msg.id;
      _conversationIdByRideId[rideId] = conversationId;
      _rideIdByConversationId[conversationId] = rideId;
    }
    final l = AppLocalizations.of(context)!;
    final body = msg.displayText.trim().isEmpty ? l.openChatButton : msg.displayText;
    setState(() { _unreadChatByRideId[rideId] = (_unreadChatByRideId[rideId] ?? 0) + 1; });
    final senderName = (msg.senderName ?? '').trim();
    final title = senderName.isEmpty ? l.openChatButton : '${l.openChatButton} • $senderName';
    _pushNotification(title: title, body: body, event: 'chat_message', rideId: rideId);
    LocalNotificationService.instance.show(title: title, body: body);
  }

  Future<void> _acceptRide(Ride ride) async {
    final t = _token; if (t == null) return;
    _selfAcceptedRideIds.add(ride.id);
    setState(() => _busy = true);
    try { await _api.acceptRide(token: t, rideId: ride.id); await _refreshRides(); }
    catch (e) { _selfAcceptedRideIds.remove(ride.id); setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _declineOffer(Ride ride) { setState(() => _dismissedPendingRideIds.add(ride.id)); }

  Future<void> _releaseRide(Ride ride) async {
    final t = _token; if (t == null) return;
    setState(() => _busy = true);
    try { await _api.rejectRide(token: t, rideId: ride.id); await _refreshRides(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _startRide(Ride ride) async {
    final t = _token; if (t == null) return;
    setState(() => _busy = true);
    try { await _api.startRide(token: t, rideId: ride.id); await _refreshRides(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _completeRide(Ride ride) async {
    final t = _token; if (t == null) return;
    setState(() => _busy = true);
    try { await _api.completeRide(token: t, rideId: ride.id); await _refreshRides(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _openChat(Ride ride) async {
    final t = _token; final uid = _userId; if (t == null || uid == null || uid <= 0) return;
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackDriverChatAfterAcceptance))); return; }
      setState(() { _activeChatRideId = ride.id; _unreadChatByRideId.remove(ride.id); });
      _rideIdByConversationId[info.conversationId] = ride.id;
      _conversationIdByRideId[ride.id] = info.conversationId;
      await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => RideChatScreen(token: t, myUserId: uid, rideId: ride.id, conversationId: info.conversationId)));
      if (mounted && _activeChatRideId == ride.id) setState(() => _activeChatRideId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted && _activeChatRideId == ride.id) setState(() => _activeChatRideId = null); }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _ridesPollingTimer?.cancel();
    _socket.disconnect();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _chatActionButton(Ride ride) {
    final l = AppLocalizations.of(context)!;
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return GestureDetector(
      onTap: _busy ? null : () => _openChat(ride),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _C.charcoal,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(l.openChatButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          if (unread > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(10)),
              child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(color: _C.charcoal, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    );
  }

  // ══ PENDING OFFERS TAB ═════════════════════════════════════
  Widget _buildPendingTab(AppLocalizations l, List<Ride> pendingOffers) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshRides,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('Dispatch', subtitle: '${pendingOffers.length} open offers'),
              // Zone selector
              Container(
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _location.isEmpty ? null : _location,
                    isExpanded: true,
                    icon: const Icon(Icons.place_outlined, color: _C.charcoal, size: 18),
                    items: _locations.map((e) => DropdownMenuItem(value: e, child: Text(localizedPlaceName(l, e), style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) async { if (v == null) return; setState(() => _location = v); await _pushDriverLocation(); },
                    hint: Text(l.ridePickupLabel, style: const TextStyle(color: _C.textSoft, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DarkButton(label: l.adminLoadRidesBtn, icon: Icons.refresh_rounded, onPressed: _busy ? null : _refreshRides, small: true)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _StatChip(label: l.driverPendingRides, value: '${pendingOffers.length}', icon: Icons.hourglass_top_rounded, color: _C.yellowDeep),
                _StatChip(label: 'Alerts', value: '$_unreadCount', icon: Icons.notifications_active_rounded, color: _C.info),
              ]),
            ]),
          ),
          if (pendingOffers.isEmpty)
            _Module(
              child: Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)), child: const Icon(Icons.local_taxi_outlined, size: 28, color: _C.textSoft)),
                  const SizedBox(height: 10),
                  Text(l.driverPendingRides, style: const TextStyle(color: _C.textSoft, fontSize: 13)),
                ]),
              )),
            )
          else
            ...pendingOffers.where((r) => !_dismissedPendingRideIds.contains(r.id)).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DriverRideOfferCard(ride: r, api: _api, busy: _busy, onAccept: () => _acceptRide(r), onReject: () => _declineOffer(r)),
            )),
        ],
      ),
    );
  }

  // ══ HISTORY TAB ════════════════════════════════════════════
  Widget _buildHistoryTab(AppLocalizations l, List<Ride> historyRides) {
    final visibleRides = historyRides.where((r) => _historyFilter == 'all' || r.status == _historyFilter).toList();
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshRides,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(l.operatorTabTripHistory, subtitle: '${visibleRides.length} rides'),
              Container(
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _historyFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.filter_list_rounded, color: _C.charcoal, size: 18),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(l.adminRidesHeading, style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'completed', child: Text(localizedRideStatusLabel(l, 'completed'), style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'cancelled', child: Text(localizedRideStatusLabel(l, 'cancelled'), style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'accepted', child: Text(localizedRideStatusLabel(l, 'accepted'), style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'ongoing', child: Text(localizedRideStatusLabel(l, 'ongoing'), style: const TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _historyFilter = v ?? 'all'),
                  ),
                ),
              ),
            ]),
          ),
          if (visibleRides.isEmpty)
            _Module(child: Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Icon(Icons.receipt_long_rounded, size: 36, color: _C.textSoft),
                const SizedBox(height: 8),
                Text(l.noTripsYet, style: const TextStyle(color: _C.textSoft)),
              ]),
            )))
          else
            ...visibleRides.map((r) {
              final statusColor = r.status == 'completed' ? _C.success : r.status == 'cancelled' ? _C.danger : r.status == 'ongoing' ? _C.info : _C.yellowDeep;
              final statusBg = r.status == 'completed' ? _C.successBg : r.status == 'cancelled' ? _C.dangerBg : r.status == 'ongoing' ? _C.infoBg : _C.yellowSoft;
              return _Module(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _rowInfoCard(
                    icon: Icons.local_taxi_outlined,
                    content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(localizedRideRouteRow(l, r.pickup, r.destination), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(50)),
                        child: Text(localizedRideStatusLabel(l, r.status), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                      if (r.isB2b == true) ...[const SizedBox(height: 4), Text('${l.roleB2b} • ${r.b2bGuestName ?? '-'} • ${((r.b2bFare ?? 0)).toStringAsFixed(3)} DT', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))],
                      if ((r.passengerName ?? '').trim().isNotEmpty || (r.passengerPhone ?? '').trim().isNotEmpty)
                        Text('${l.rolePassenger}: ${(r.passengerName ?? '').trim().isEmpty ? '-' : r.passengerName} • ${(r.passengerPhone ?? '').trim().isEmpty ? '-' : r.passengerPhone}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                    ]),
                  ),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (r.status == 'accepted')
                      _DarkButton(label: l.startRide, icon: Icons.play_arrow_rounded, onPressed: _busy ? null : () => _startRide(r), small: true, fullWidth: false),
                    if (r.status == 'accepted' || r.status == 'ongoing')
                      GestureDetector(
                        onTap: _busy ? null : () => _releaseRide(r),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(50), border: Border.all(color: _C.danger.withOpacity(0.3))),
                          child: Center(child: Text(l.cancelRidePassenger, style: const TextStyle(color: _C.danger, fontWeight: FontWeight.w700, fontSize: 12))),
                        ),
                      ),
                    if (r.status == 'ongoing')
                      _YellowButton(label: l.completeRide, icon: Icons.check_rounded, onPressed: _busy ? null : () => _completeRide(r), small: true, fullWidth: false),
                    if (r.status == 'accepted' || r.status == 'ongoing') _chatActionButton(r),
                  ]),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshArrivals,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _DarkButton(
            label: l.adminLoadRidesBtn,
            icon: Icons.refresh_rounded,
            onPressed: _busy ? null : _refreshArrivals,
          ),
          const SizedBox(height: 16),
          _SectionHead(l.operatorTabTodaysArrivals),
          if (_flightArrivals.isEmpty)
            _Module(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flight_land_rounded,
                        size: 40,
                        color: _C.textSoft,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.operatorNoFlightArrivals,
                        style: const TextStyle(color: _C.textSoft),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _Module(
              padding: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_C.charcoal),
                  headingTextStyle: const TextStyle(
                    color: _C.yellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? _C.yellowSoft : null,
                  ),
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _C.border),
                  ),
                  columns: [
                    DataColumn(label: Text(l.operatorColFlightNumber)),
                    const DataColumn(label: Text('Airline')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Aircraft')),
                    DataColumn(label: Text(l.operatorColDepartureAirport)),
                    DataColumn(label: Text(l.operatorColTakeoffTime)),
                    DataColumn(label: Text(l.operatorColExpectedArrival)),
                    const DataColumn(label: Text('Last update')),
                    const DataColumn(label: Text('Speed')),
                    const DataColumn(label: Text('Altitude')),
                    DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                  ],
                  rows: _flightArrivals.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r['flight_number']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['airline'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['status'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['aircraft'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _departureAirportLabel(r),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            r['takeoff_time']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (() {
                              final raw = _prettyDateTime(
                                r['expected_arrival']?.toString() ?? '',
                              );
                              return raw.trim().isEmpty ? '-' : raw;
                            })(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _prettyDateTime(r['last_update']?.toString() ?? ''),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['speed_kmh'] == null) ? '-' : '${r['speed_kmh']} km/h',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['altitude_m'] == null) ? '-' : '${r['altitude_m']} m',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _arrivalAirportLabel(r),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pendingOffers = _rides.where((r) => r.status == 'pending').toList();
    final historyRides = _rides.where((r) => _driverId != null && r.driverId == _driverId).toList();

    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.charcoal,
        centerTitle: true,
        title: _appBarHomeLogo(),
        actions: [
          LocalePopupMenuButton(authToken: _token, uiRole: AppUiRole.driver),
          if (_token != null)
            IconButton(
              onPressed: _showNotifications,
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_rounded, color: _C.yellow),
                if (_unreadCount > 0)
                  Positioned(
                    right: -6, top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 14),
                      child: Text(_unreadCount > 99 ? '99+' : '$_unreadCount', style: const TextStyle(color: _C.charcoal, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                  ),
              ]),
            ),
        ],
      ),
      body: _token == null
          // ── Login ─────────────────────────────────────────
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.45), blurRadius: 20)]),
                    child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Driver Portal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _C.textStrong)),
                  const SizedBox(height: 4),
                  const Text('Sign in with your phone & PIN', style: TextStyle(color: _C.textSoft, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border), boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))]),
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _fd(l.emailLabel, icon: Icons.phone_rounded)),
                      const SizedBox(height: 12),
                      TextField(controller: _pinController, obscureText: true, decoration: _fd(l.passwordLabel, icon: Icons.lock_outline_rounded)),
                      const SizedBox(height: 16),
                      _YellowButton(label: l.login, icon: Icons.login_rounded, onPressed: _busy ? null : _login),
                    ]),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))),
                      child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13)))]),
                    ),
                  ],
                  if (_busy) ...[const SizedBox(height: 16), const CircularProgressIndicator(color: _C.yellow, strokeWidth: 2.5)],
                ]),
              ),
            )
          // ── Dashboard ─────────────────────────────────────
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Welcome / status banner
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFC200), Color(0xFFFFD84D)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  // Availability toggle embedded in banner
                  GestureDetector(
                    onTap: _busy ? null : () => _setAvailability(!_isAvailable),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isAvailable ? _C.success : _C.charcoal,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(_isAvailable ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _driverName != null ? '${l.sessionActive} · $_driverName' : l.sessionActive,
                    style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w700, fontSize: 13),
                  )),
                  // Wallet
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _C.charcoal.withOpacity(0.15), borderRadius: BorderRadius.circular(50)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: _C.charcoal, size: 14),
                      const SizedBox(width: 4),
                      Text('${_walletBalance.toStringAsFixed(2)} DT', style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w800, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
              // Gains snapshot (collapsible)
              if (_gains != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    _StatChip(label: 'Net Gains', value: '${((_gains!['net_gains'] ?? 0) as num).toStringAsFixed(2)} DT', icon: Icons.payments_outlined, color: _C.success),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Trips', value: '${_gains!['completed_rides_count'] ?? 0}', icon: Icons.route_outlined),
                  ]),
                ),
              // Driver photo strip (if available)
              if ((_photoUrl?.isNotEmpty ?? false))
                _buildPhotoStrip(l),
              const SizedBox(height: 6),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _C.yellow,
                  indicatorWeight: 3,
                  labelColor: _C.yellow,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.3),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  tabs: [
                    Tab(text: '🚖 ${l.driverPendingRides}'),
                    Tab(text: '📋 ${l.operatorTabTripHistory}'),
                    Tab(text: '✈️ ${l.operatorTabTodaysArrivals}'),
                  ],
                ),
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(l, pendingOffers),
                  _buildHistoryTab(l, historyRides),
                  _buildArrivalsTab(l),
                ],
              )),
              if (_message != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))),
                  child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13)))]),
                ),
            ]),
    );
  }

  Widget _buildPhotoStrip(AppLocalizations l) {
    final provider = _imageProviderFromString(_photoUrl);
    if (provider == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.yellowDeep, width: 2), image: DecorationImage(image: provider, fit: BoxFit.cover)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_driverName ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _C.textStrong)),
          if (_carModel != null || _carColor != null)
            Text('${_carModel ?? '—'} · ${_carColor ?? '—'}', style: const TextStyle(color: _C.textSoft, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(50), border: Border.all(color: _C.yellowDeep)),
          child: Text(l.driverVehicleIdentityTitle, style: const TextStyle(color: _C.charcoal, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  List<String> _startsFromRouteKeys(Iterable<String> routeKeys, AppLocalizations l) {
    final starts = <String>{};
    for (final key in routeKeys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.isNotEmpty) starts.add(parts.first.trim());
    }
    return starts.toList()..sort((a, b) => localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
  }

  ImageProvider<Object>? _imageProviderFromString(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:image/')) {
      final commaIdx = raw.indexOf(',');
      if (commaIdx <= 0 || commaIdx + 1 >= raw.length) return null;
      try { return MemoryImage(base64Decode(raw.substring(commaIdx + 1))); } catch (_) { return null; }
    }
    return NetworkImage(raw);
  }
}