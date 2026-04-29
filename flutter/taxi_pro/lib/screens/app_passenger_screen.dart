// ═══════════════════════════════════════════════════════════════
// app_passenger_screen.dart — TUNISIAN TAXI YELLOW THEME
// All original logic preserved — only UI/style changed
// ═══════════════════════════════════════════════════════════════

import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/client.dart';
import '../app_locale.dart';
import '../config.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/passenger_google_sign_in_button.dart';
import 'ride_chat_screen.dart';
import 'unified_login_screen.dart';

// ── Design tokens ─────────────────────────────────────────────
class _C {
  static const yellow      = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft  = Color(0xFFFFF8E0);
  static const yellowDeep  = Color(0xFFE6A800);
  static const charcoal    = Color(0xFF1A1A1A);
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
  static const amber       = Color(0xFFB45309);
}

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
  labelText: label, labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
  prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
  filled: true, fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border, width: 1.5)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.yellow, width: 2)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, required this.onPressed, this.icon, this.small = false});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1, duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: small ? 38 : 50,
          decoration: BoxDecoration(
            color: _C.yellow, borderRadius: BorderRadius.circular(50),
            boxShadow: disabled ? [] : [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: _C.charcoal, size: small ? 14 : 18), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: _C.charcoal, fontWeight: FontWeight.w900, fontSize: small ? 12 : 14, letterSpacing: 0.3)),
          ])),
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed, this.icon, this.small = false});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.45 : 1, duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: small ? 38 : 50,
          decoration: BoxDecoration(
            color: _C.charcoal, borderRadius: BorderRadius.circular(50),
            boxShadow: disabled ? [] : [BoxShadow(color: _C.charcoal.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: small ? 14 : 18), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 12 : 14, letterSpacing: 0.3)),
          ])),
        ),
      ),
    );
  }
}

class _TaxiCard extends StatelessWidget {
  const _TaxiCard({required this.child, this.padding = 16, this.accent = false, this.color});
  final Widget child; final double padding; final bool accent; final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: color ?? _C.surface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
      boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = _C.charcoal});
  final String text; final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  ]);
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
  String? _locationText;
  String? _locationPlaceName;
  String? _locationError;
  bool _locating = false;
  String? _token;
  int? _userId;
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
  bool _backendLoginInFlight = false;
  StreamSubscription<GoogleSignInAccount?>? _googleUserSub;
  Timer? _ridesPollingTimer;
  Widget _appBarHomeLogo() => GestureDetector(
    onTap: () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      );
    },
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(9)),
      child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 18),
    ),
  );
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
        if (account != null && _token == null && mounted) unawaited(_completeLoginWithGoogleAccount(account));
      });
    }
  }

  Future<void> _bootstrapFromSession(AppLoginResponse r) async {
    if (!userChoseLocaleThisSession.value) applyPreferredLanguageToApp(r.preferredLanguage);
    else { try { await _api.patchPreferredLanguage(token: r.accessToken, preferredLanguage: appLocale.value.languageCode); } catch (_) {} }
    rememberCurrentLocaleForRole(AppUiRole.passenger);
    _token = r.accessToken; _userId = r.userId;
    _connectRealtime(); _startRidesPolling();
    _fares = await _api.getAirportFares();
    await _detectPassengerLocation(); await _refreshRides();
    if (!mounted) return; setState(() {});
  }

  @override
  void dispose() {
    _ridesPollingTimer?.cancel(); _socket.disconnect(); _googleUserSub?.cancel();
    _emailCtrl.dispose(); _passwordCtrl.dispose(); _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose(); _signupPhoneCtrl.dispose(); _signupPasswordCtrl.dispose();
    super.dispose();
  }

  void _startRidesPolling() {
    _ridesPollingTimer?.cancel();
    _ridesPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _token == null || _busy) return;
      _refreshRides(silent: true);
    });
  }

  Future<void> _detectPassengerLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() { _locating = true; _locationError = null; });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locationError = l10n.passengerLocationServiceDisabled); return; }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { setState(() => _locationError = l10n.passengerLocationPermissionDenied); return; }
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final nearestZone = _nearestZoneFor(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() { _locationText = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'; _locationPlaceName = nearestZone; });
    } catch (e) { if (!mounted) return; setState(() => _locationError = e.toString()); }
    finally { if (mounted) setState(() => _locating = false); }
  }

  String? _nearestZoneFor(double lat, double lng) {
    String? bestZone; double? bestDist;
    for (final e in _zoneCoords.entries) {
      final d = Geolocator.distanceBetween(lat, lng, e.value.lat, e.value.lng);
      if (bestDist == null || d < bestDist) { bestDist = d; bestZone = e.key; }
    }
    return bestZone;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _pushNotification({required String title, required String body, String? event, int? rideId}) {
    final now = DateTime.now();
    final dup = _notifications.isNotEmpty ? _notifications.first : null;
    if (dup != null && dup.event == event && dup.rideId == rideId && now.difference(dup.createdAt).inMilliseconds < 1200) return;
    setState(() {
      _notifications.insert(0, AppNotification(id: '${now.microsecondsSinceEpoch}-${event ?? 'manual'}-${rideId ?? 0}', title: title, body: body, event: event, rideId: rideId, createdAt: now));
      if (_notifications.length > 60) _notifications.removeRange(60, _notifications.length);
    });
  }

  void _showNotifications() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _notifications.isEmpty
              ? Center(child: Text(l10n.notificationsEmpty, style: const TextStyle(color: _C.textMid)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(color: _C.border),
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i];
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: n.isRead ? _C.surfaceAlt : _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: n.isRead ? _C.border : _C.yellowDeep)),
                        child: Icon(n.isRead ? Icons.notifications_none : Icons.notifications_active, color: n.isRead ? _C.textSoft : _C.charcoal, size: 18),
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w700, fontSize: 13)),
                      subtitle: Text(n.body, style: const TextStyle(color: _C.textMid, fontSize: 12)),
                      trailing: n.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: _C.yellow, shape: BoxShape.circle)),
                      onTap: () {
                        setState(() => n.isRead = true); Navigator.of(ctx).pop();
                        final ride = n.rideId == null ? null : _rides.where((r) => r.id == n.rideId).cast<Ride?>().firstWhere((r) => r != null, orElse: () => null);
                        if (ride != null) _showRideNotificationDetails(ride);
                        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(n.body)));
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
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.passengerRideNotificationTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text('${l10n.passengerRideNumberLine(ride.id)}\n${l10n.rideStatusFmt(localizedRideStatusLabel(l10n, ride.status))}\n${l10n.ridePickupLabel}: ${localizedPlaceName(l10n, ride.pickup)}\n${l10n.rideDestinationLabel}: ${localizedPlaceName(l10n, ride.destination)}', style: const TextStyle(color: _C.textMid, height: 1.6)),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.dialogOk))],
    ));
  }

  void _connectRealtime() {
    final t = _token; if (t == null) return;
    final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
    final isWebLocal =
        kIsWeb && (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
    // Local Flutter Web + socket_io_client polling can crash with parser RangeError.
    // Keep ride/chat updates via HTTP polling fallback in this environment.
    if (isWebLocal) return;
    _socket.connect(t, transports: const ['polling'], onReceiveMessage: _onChatMessage, onRideStatus: (data) {
      if (!mounted) return;
      final rideMap = data['ride'];
      if (rideMap is Map) {
        final ride = Ride.fromJson(Map<String, dynamic>.from(rideMap));
        setState(() { final idx = _rides.indexWhere((r) => r.id == ride.id); if (idx >= 0) _rides[idx] = ride; else _rides.insert(0, ride); });
        final event = (data['event'] ?? '').toString(); final message = (data['message'] ?? '').toString();
        if (event.isNotEmpty || message.isNotEmpty) {
          if (!mounted) return;
          final pl = AppLocalizations.of(context)!;
          _pushNotification(title: pl.notificationRideUpdateTitle, body: message.isNotEmpty ? message : pl.notificationRideUpdatedBody(ride.id), event: event, rideId: ride.id);
        }
      }
    }, onConnectError: (_) {});
  }

  Future<int?> _resolveRideIdFromChatPayload(Map<String, dynamic> data) async {
    final directRideId = (data['ride_id'] as num?)?.toInt(); if (directRideId != null) return directRideId;
    final conversationId = (data['conversation_id'] as num?)?.toInt(); if (conversationId == null) return null;
    final cached = _rideIdByConversationId[conversationId]; if (cached != null) return cached;
    final t = _token; if (t == null) return null;
    for (final ride in _rides.where((r) => r.status == 'accepted' || r.status == 'ongoing')) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id; _conversationIdByRideId[ride.id] = info.conversationId;
        if (info.conversationId == conversationId) return ride.id;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token; if (t == null) return;
    for (final ride in rides.where((r) => r.status == 'accepted' || r.status == 'ongoing')) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id; _conversationIdByRideId[ride.id] = info.conversationId;
      } catch (_) {}
    }
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _token; final uid = _userId; if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    for (final entry in _conversationIdByRideId.entries.toList()) {
      final rideId = entry.key; final conversationId = entry.value;
      if (_activeChatRideId == rideId) continue;
      try {
        final msgs = await _api.listConversationMessages(token: t, conversationId: conversationId, limit: 20);
        if (msgs.isEmpty) continue;
        final prevSeen = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
        int maxId = prevSeen; int incomingCount = 0; ChatMessage? latestIncoming;
        for (final m in msgs) {
          if (m.id > maxId) maxId = m.id;
          if (prevSeen > 0 && m.id > prevSeen && m.senderUserId != uid) { incomingCount++; if (latestIncoming == null || m.id > latestIncoming.id) latestIncoming = m; }
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

  void _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted) return;
    final msg = ChatMessage.fromJson(data); if (msg.senderUserId == _userId) return;
    final rideId = await _resolveRideIdFromChatPayload(data); if (!mounted) return; if (rideId == null) return;
    if (_activeChatRideId == rideId) return;
    final conversationId = (data['conversation_id'] as num?)?.toInt();
    if (conversationId != null) { _lastSeenMessageIdByConversationId[conversationId] = msg.id; _conversationIdByRideId[rideId] = conversationId; _rideIdByConversationId[conversationId] = rideId; }
    final l = AppLocalizations.of(context)!;
    final body = msg.displayText.trim().isEmpty ? l.openChatButton : msg.displayText;
    setState(() { _unreadChatByRideId[rideId] = (_unreadChatByRideId[rideId] ?? 0) + 1; });
    final sn = (msg.senderName ?? '').trim();
    final title = sn.isEmpty ? l.openChatButton : '${l.openChatButton} • $sn';
    _pushNotification(title: title, body: body, event: 'chat_message', rideId: rideId);
    LocalNotificationService.instance.show(title: title, body: body);
  }

  Future<void> _loginWithGoogle() async {
    if (kIsWeb) return;
    setState(() => _message = null);
    try { await _googleSignIn.signOut(); final account = await _googleSignIn.signIn(); if (account == null) return; await _completeLoginWithGoogleAccount(account); }
    on TaxiAccountDisabledException { if (!mounted) return; setState(() => _message = AppLocalizations.of(context)!.accountDisabledContactAdmin); }
    catch (e) { setState(() => _message = e.toString()); }
  }

  Future<void> _completeLoginWithGoogleAccount(GoogleSignInAccount account) async {
    if (_backendLoginInFlight || _token != null) return;
    _backendLoginInFlight = true;
    setState(() { _busy = true; _message = null; });
    try {
      final auth = await account.authentication;
      final idToken = auth.idToken; final accessToken = auth.accessToken;
      final hasIdToken = idToken != null && idToken.isNotEmpty; final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
      if (!hasIdToken && !hasAccessToken) { if (!mounted) return; setState(() => _message = AppLocalizations.of(context)!.errorGoogleSignInMissingToken); return; }
      AppLoginResponse r;
      try { r = await _api.loginGoogle(idToken: hasIdToken ? idToken : null, accessToken: hasAccessToken ? accessToken : null); }
      on TaxiApiException catch (e) {
        if (e.message == 'phone_required') {
          final phone = await _askPhone();
          if (phone == null || phone.trim().isEmpty) { if (!mounted) return; setState(() => _message = 'Phone number is required.'); return; }
          r = await _api.loginGoogle(idToken: hasIdToken ? idToken : null, accessToken: hasAccessToken ? accessToken : null, phone: phone.trim());
        } else { rethrow; }
      }
      if (!userChoseLocaleThisSession.value) applyPreferredLanguageToApp(r.preferredLanguage);
      else { try { await _api.patchPreferredLanguage(token: r.accessToken, preferredLanguage: appLocale.value.languageCode); } catch (_) {} }
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken; _userId = r.userId;
      _connectRealtime(); _startRidesPolling();
      _fares = await _api.getAirportFares(); await _detectPassengerLocation(); await _refreshRides();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.signedInWithGoogle)));
    } on TaxiAccountDisabledException { if (!mounted) return; setState(() => _message = AppLocalizations.of(context)!.accountDisabledContactAdmin); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { _backendLoginInFlight = false; if (mounted) setState(() => _busy = false); }
  }

  Future<String?> _askPhone() async {
    var phone = '';
    return showDialog<String>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Phone required', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(autofocus: true, keyboardType: TextInputType.phone, textInputAction: TextInputAction.done, onChanged: (v) => phone = v, onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()), decoration: _fd('Phone number', icon: Icons.phone_outlined)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))), onPressed: () => Navigator.of(ctx).pop(phone.trim()), child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _loginWithEmailPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim(); final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) { setState(() => _message = 'Please fill in email and password.'); return; }
    setState(() { _busy = true; _message = null; });
    try {
      final r = await _api.loginApp(email: email, password: password);
      if (!userChoseLocaleThisSession.value) applyPreferredLanguageToApp(r.preferredLanguage);
      else { try { await _api.patchPreferredLanguage(token: r.accessToken, preferredLanguage: appLocale.value.languageCode); } catch (_) {} }
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken; _userId = r.userId;
      _connectRealtime(); _startRidesPolling();
      _fares = await _api.getAirportFares(); await _detectPassengerLocation(); await _refreshRides();
    } on TaxiAccountDisabledException { if (!mounted) return; setState(() => _message = l.accountDisabledContactAdmin); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _registerPassengerAccount() async {
    final name = _signupNameCtrl.text.trim(); final email = _signupEmailCtrl.text.trim();
    final phone = _signupPhoneCtrl.text.trim(); final password = _signupPasswordCtrl.text;
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) { setState(() => _message = 'Please fill all required fields.'); return; }
    setState(() { _busy = true; _message = null; });
    try {
      await _api.registerAppUser(email: email, password: password, role: 'user', displayName: name, phone: phone, photoUrl: _signupPhotoData.trim());
      _emailCtrl.text = email; _passwordCtrl.text = password; await _loginWithEmailPassword();
    } catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _pickPassengerSignupImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase(); final ext = name.contains('.') ? name.split('.').last : 'jpeg';
    final mime = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
    if (!mounted) return;
    setState(() { _signupPhotoData = 'data:$mime;base64,${base64Encode(bytes)}'; });
  }

  Future<void> _refreshRides({bool silent = false}) async {
    final t = _token; if (t == null) return;
    if (!silent) setState(() => _busy = true);
    try {
      final previousById = {for (final r in _rides) r.id: r};
      final list = await _api.listRides(t);
      setState(() { _rides = list; _message = null; });
      await _syncConversationRideMap(list); await _pollChatUnreadFallback();
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      for (final ride in list) {
        final prev = previousById[ride.id];
        if (prev == null && ride.status == 'accepted' && !_acceptedNotifiedRideIds.contains(ride.id)) {
          final driver = ride.driverName ?? loc.driverNameFallback; final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(title: loc.notificationDriverAcceptedTitle, body: loc.notificationDriverAcceptedBody(driver, ps), event: 'ride_accepted', rideId: ride.id);
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (prev == null || prev.status == ride.status) continue;
        if (prev.status == 'pending' && ride.status == 'accepted') {
          final driver = ride.driverName ?? loc.driverNameFallback; final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(title: loc.notificationDriverAcceptedTitle, body: loc.notificationDriverAcceptedBody(driver, ps), event: 'ride_accepted', rideId: ride.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.notificationDriverAcceptedSnack(driver, ps))));
          LocalNotificationService.instance.show(title: loc.notificationDriverAcceptedTitle, body: loc.notificationDriverAcceptedBody(driver, ps));
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (ride.status == 'accepted' && (ride.driverCurrentZone ?? '').trim().isNotEmpty && ride.driverCurrentZone!.trim() == ride.pickup.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.passengerDriverNearPickupSnack)));
          LocalNotificationService.instance.show(title: loc.notificationDriverNearPickupTitle, body: loc.notificationDriverNearPickupBody(ride.pickup));
        }
      }
    } catch (e) { if (!silent) setState(() => _message = e.toString()); }
    finally { if (!silent && mounted) setState(() => _busy = false); }
  }

  Future<void> _requestRide() async {
    final l = AppLocalizations.of(context)!;
    if (_fares.isEmpty) { setState(() => _message = l.adminNoRidesLoaded); return; }
    final routeKeys = _fares.keys.toList()..sort((a, b) => localizedRouteKeyForDisplay(l, a).compareTo(localizedRouteKeyForDisplay(l, b)));
    if (routeKeys.isEmpty) { setState(() => _message = l.noRidesYetApp); return; }
    String selectedRouteKey = routeKeys.first;
    if ((_locationPlaceName ?? '').trim().isNotEmpty) {
      for (final key in routeKeys) { final parts = key.split(airportRouteKeySeparator); if (parts.isNotEmpty && parts.first.trim() == _locationPlaceName!.trim()) { selectedRouteKey = key; break; } }
    }
    String promoCode = ''; Map<String, dynamic>? quote; bool? ok;
    final promoCtrl = TextEditingController();
    Future<void> recalcQuote(StateSetter ss) async {
      try {
        final q = await _api.quoteAirport(selectedRouteKey);
        var fare = (q['base_fare'] as num?)?.toDouble() ?? (_fares[selectedRouteKey] ?? 0);
        if (promoCtrl.text.trim() == 'WELCOME26') fare *= 0.8;
        final h = DateTime.now().hour; if (h >= 21 || h < 5) fare *= 1.5;
        q['final_fare'] = double.parse(fare.toStringAsFixed(3)); q['route_key'] = selectedRouteKey;
        ss(() => quote = q);
      } catch (_) { ss(() => quote = null); }
    }
    ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const _SectionLabel('Book a Ride'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                child: DropdownButton<String>(
                  value: selectedRouteKey, isExpanded: true, underline: const SizedBox.shrink(),
                  items: routeKeys.map((k) => DropdownMenuItem(value: k, child: Text(localizedRouteKeyForDisplay(l, k), style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) async { if (v == null) return; selectedRouteKey = v; await recalcQuote(ss); },
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: promoCtrl, decoration: _fd(l.promoCodeOptionalLabel, icon: Icons.discount_outlined), onChanged: (_) async { promoCode = promoCtrl.text.trim(); await recalcQuote(ss); }),
              const SizedBox(height: 16),
              if (quote != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.yellowDeep)),
                  child: Column(children: [
                    Text('${(quote!['final_fare'] as num).toStringAsFixed(2)} DT', textAlign: TextAlign.center, style: const TextStyle(color: _C.charcoal, fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(l.passengerFareFinalEstimate, textAlign: TextAlign.center, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx, false), child: Container(height: 46, decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(50), border: Border.all(color: _C.border)), child: Center(child: Text(l.genericCancel, style: const TextStyle(color: _C.textMid, fontWeight: FontWeight.w700)))))),
                const SizedBox(width: 10),
                Expanded(child: _YellowButton(label: l.requestRideButton, onPressed: quote == null ? null : () { promoCode = promoCtrl.text.trim(); Navigator.pop(ctx, true); })),
              ]),
            ]),
          ),
        ),
      ),
    );
    promoCtrl.dispose();
    if (ok != true || !mounted) return;
    final t = _token; final q = quote; if (t == null || q == null) return;
    final routeKey = q['route_key'] as String?; if (routeKey == null) return;
    final parts = routeKey.split(airportRouteKeySeparator);
    final pu = parts.first.trim(); final de = parts.length > 1 ? parts[1].trim() : '';
    setState(() => _busy = true);
    try {
      await _api.createRide(token: t, pickup: pu, destination: de); await _refreshRides();
      if (!mounted) return;
      _pushNotification(title: l.notificationRequestSentTitle, body: l.notificationRequestSentBody, event: 'ride_request_sent');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.requestSentSnackLine(l.fareDt((q['final_fare'] as num).toStringAsFixed(3)), promoCode.isEmpty ? '' : ' | $promoCode'))));
      LocalNotificationService.instance.show(title: l.notificationRequestSentTitle, body: l.notificationRequestSentBody);
    } catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _cancelRide(Ride ride) async {
    final t = _token; if (t == null) return;
    setState(() => _busy = true);
    try { await _api.cancelRide(token: t, rideId: ride.id); await _refreshRides(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _rateCompletedRide(Ride ride) async {
    final t = _token; if (t == null || ride.status != 'completed') return;
    int stars = 5; final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.rateYourLastRide, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
            final s = i + 1;
            return IconButton(icon: Icon(stars >= s ? Icons.star_rounded : Icons.star_border_rounded, color: _C.yellow, size: 32), onPressed: () => ss(() => stars = s));
          })),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.genericCancel)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))), onPressed: () => Navigator.of(ctx).pop(true), child: Text(l.submitRating, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.submitRating(token: t, rideId: ride.id, stars: stars);
      if (!mounted) return;
      setState(() => _ratedRideIds.add(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.thankYouFeedback)));
    } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Future<void> _openChat(Ride ride) async {
    final l = AppLocalizations.of(context)!; final t = _token; final uid = _userId;
    if (t == null || uid == null) return;
    setState(() => _busy = true);
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatUnavailable))); return; }
      setState(() { _activeChatRideId = ride.id; _unreadChatByRideId.remove(ride.id); });
      _rideIdByConversationId[info.conversationId] = ride.id; _conversationIdByRideId[ride.id] = info.conversationId;
      await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => RideChatScreen(token: t, myUserId: uid, rideId: ride.id, conversationId: info.conversationId)));
      if (mounted && _activeChatRideId == ride.id) setState(() => _activeChatRideId = null);
      await _refreshRides();
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      if (e.message == 'forbidden' || e.message == 'chat_not_open') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatUnavailable)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted && _activeChatRideId == ride.id) setState(() => _activeChatRideId = null); if (mounted) setState(() => _busy = false); }
  }

  void _logout() {
    if (kIsWeb) unawaited(_googleSignIn.signOut());
    _ridesPollingTimer?.cancel(); _socket.disconnect();
    setState(() { _token = null; _userId = null; _rides = []; _notifications.clear(); _unreadChatByRideId.clear(); _rideIdByConversationId.clear(); _conversationIdByRideId.clear(); _lastSeenMessageIdByConversationId.clear(); _activeChatRideId = null; _message = null; });
  }

  Widget _chatActionButton(Ride ride) {
    final l = AppLocalizations.of(context)!;
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return GestureDetector(
      onTap: _busy ? null : () => _openChat(ride),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(l.openChatButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          if (unread > 0) ...[
            const SizedBox(width: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: _C.danger, borderRadius: BorderRadius.circular(10)), child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ]),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'accepted' => _C.success,
    'ongoing'  => _C.info,
    'completed'=> _C.textMid,
    'cancelled'=> _C.danger,
    _          => _C.amber,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const activeStatuses = {'pending', 'accepted', 'ongoing'};
    final hasActiveRide = _rides.any((r) => activeStatuses.contains(r.status));
    final activeCount = _rides.where((r) => activeStatuses.contains(r.status)).length;

    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.charcoal,
        centerTitle: true,
        title: _appBarHomeLogo(),
        actions: [
          const LocalePopupMenuButton(authToken: null, uiRole: AppUiRole.passenger),
          if (_token != null) ...[
            IconButton(
              onPressed: _showNotifications,
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_rounded, color: _C.yellow),
                if (_unreadCount > 0) Positioned(right: -4, top: -4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: _C.danger, borderRadius: BorderRadius.circular(10)),
                  child: Text(_unreadCount > 99 ? '99+' : '$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9)),
                )),
              ]),
            ),
            IconButton(onPressed: _busy ? null : _refreshRides, icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white24)),
                child: Text(l.logoutApp, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
            _TaxiCard(accent: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionLabel('Sign In'),
              const SizedBox(height: 14),
              TextField(controller: _emailCtrl, decoration: _fd(l.emailLabel, icon: Icons.alternate_email_rounded)),
              const SizedBox(height: 10),
              TextField(controller: _passwordCtrl, obscureText: true, decoration: _fd(l.passwordLabel, icon: Icons.lock_outline_rounded)),
              const SizedBox(height: 16),
              _YellowButton(label: l.signInApp, icon: Icons.login_rounded, onPressed: _busy ? null : _loginWithEmailPassword),
            ])),
            // Google
            if (kIsWeb)
              const PassengerGoogleGsiButton()
            else
              GestureDetector(
                onTap: _busy ? null : _loginWithGoogle,
                child: Container(
                  height: 50, margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(50), border: Border.all(color: _C.border)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.g_mobiledata_rounded, color: _C.charcoal, size: 22),
                    const SizedBox(width: 8),
                    Text(l.continueWithGoogle, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textStrong)),
                  ]),
                ),
              ),
            // Register
            _TaxiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionLabel('Create Account'),
              const SizedBox(height: 14),
              TextField(controller: _signupNameCtrl, decoration: _fd('Passenger name', icon: Icons.badge_outlined)),
              const SizedBox(height: 10),
              TextField(controller: _signupEmailCtrl, decoration: _fd(l.emailLabel, icon: Icons.alternate_email_rounded)),
              const SizedBox(height: 10),
              TextField(controller: _signupPhoneCtrl, decoration: _fd(l.operatorPhoneLabel, icon: Icons.phone_outlined)),
              const SizedBox(height: 10),
              TextField(controller: _signupPasswordCtrl, obscureText: true, decoration: _fd(l.passwordLabel, icon: Icons.lock_outline_rounded)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPassengerSignupImage,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(l.operatorPickFromGallery),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), side: const BorderSide(color: _C.border)),
              ),
              if (_signupPhotoData.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Builder(builder: (_) {
                  final p = _imageProviderFromString(_signupPhotoData);
                  return p != null ? Image(image: p, height: 90, fit: BoxFit.cover) : const SizedBox.shrink();
                })),
                TextButton.icon(onPressed: () => setState(() => _signupPhotoData = ''), icon: const Icon(Icons.delete_outline, size: 16, color: _C.danger), label: Text(l.operatorRemovePickedImage, style: const TextStyle(color: _C.danger))),
              ],
              const SizedBox(height: 14),
              _DarkButton(label: l.registerAppAccount, icon: Icons.person_add_rounded, onPressed: _busy ? null : _registerPassengerAccount),
            ])),
          ] else ...[
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Row(children: [
                const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 22),
                const SizedBox(width: 10),
                Text(l.passengerDispatchPanelTitle, style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                _statBadge('${activeCount} ${l.passengerActiveRidesChip(activeCount).split(' ').last}', _C.success),
                const SizedBox(width: 6),
                _statBadge('${_rides.length} total', _C.charcoal),
              ]),
            ),
            const SizedBox(height: 10),
            // Location
            _TaxiCard(padding: 0, child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)), child: const Icon(Icons.my_location_rounded, color: _C.charcoal, size: 18)),
              title: Text(_locationPlaceName != null ? localizedPlaceName(l, _locationPlaceName) : l.passengerLocationCurrent, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(_locationPlaceName != null ? '($_locationText)' : (_locationText ?? (_locating ? l.passengerLocationDetecting : (_locationError ?? l.passengerLocationUnavailable))), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
              trailing: IconButton(onPressed: _locating ? null : _detectPassengerLocation, icon: const Icon(Icons.refresh_rounded, color: _C.textMid, size: 18)),
            )),
            // Book
            _TaxiCard(accent: true, child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.flight_takeoff_rounded, color: _C.charcoal, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.passengerBookingSectionTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Text('Airport transfer', style: TextStyle(color: _C.textSoft, fontSize: 12)),
              ])),
              _YellowButton(label: l.requestRideButton, icon: Icons.add_rounded, onPressed: _busy || hasActiveRide ? null : _requestRide, small: true),
            ])),
            const SizedBox(height: 16),
            Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Text(l.myRidesHeading, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),
            if (_rides.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(l.noRidesYetApp, style: const TextStyle(color: _C.textSoft)))),
            ..._rides.map((r) => _rideCard(r, l)),
          ],
          if (_message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))),
              child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13)))]),
            ),
          ],
          if (_busy) ...[const SizedBox(height: 16), const Center(child: CircularProgressIndicator(color: _C.yellow, strokeWidth: 2.5))],
        ],
      ),
    );
  }

  Widget _statBadge(String label, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(50), border: Border.all(color: bg.withOpacity(0.4))),
    child: Text(label, style: TextStyle(color: bg == _C.charcoal ? _C.charcoal : bg, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _rideCard(Ride r, AppLocalizations l) {
    final sc = _statusColor(r.status);
    final provider = _imageProviderFromString(r.driverPhotoUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 20, backgroundImage: provider, child: provider == null ? const Icon(Icons.person_rounded, size: 20) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(localizedRideRouteRow(l, r.pickup, r.destination), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(50), border: Border.all(color: sc.withOpacity(0.35))),
                child: Text(localizedRideStatusLabel(l, r.status), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ])),
          ]),
          if ((r.driverName ?? '').isNotEmpty || (r.driverPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((r.driverName ?? '').isNotEmpty) Row(children: [const Icon(Icons.person_outline_rounded, color: _C.textSoft, size: 13), const SizedBox(width: 5), Text(l.passengerDriverLine(r.driverName!), style: const TextStyle(color: _C.textMid, fontSize: 12))]),
                if ((r.driverPhone ?? '').isNotEmpty) Row(children: [const Icon(Icons.phone_outlined, color: _C.textSoft, size: 13), const SizedBox(width: 5), Text(l.passengerPhoneLine(r.driverPhone!), style: const TextStyle(color: _C.textMid, fontSize: 12))]),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (r.status != 'completed' && r.status != 'cancelled')
              GestureDetector(
                onTap: _busy ? null : () => _cancelRide(r),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.danger.withOpacity(0.4))), child: Text(l.cancelRidePassenger, style: const TextStyle(color: _C.danger, fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            _chatActionButton(r),
            if (r.status == 'completed' && !_ratedRideIds.contains(r.id))
              GestureDetector(
                onTap: _busy ? null : () => _rateCompletedRide(r),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.yellowDeep)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, color: _C.charcoal, size: 13), const SizedBox(width: 4), Text(l.submitRating, style: const TextStyle(color: _C.charcoal, fontSize: 12, fontWeight: FontWeight.w800))])),
              ),
          ]),
        ]),
      ),
    );
  }

  String _phoneSuffix(String? phone) { final p = (phone ?? '').trim(); return p.isEmpty ? '' : ' ($p)'; }

  ImageProvider<Object>? _imageProviderFromString(String? value) {
    final raw = (value ?? '').trim(); if (raw.isEmpty) return null;
    if (raw.startsWith('data:image/')) {
      final commaIdx = raw.indexOf(','); if (commaIdx <= 0 || commaIdx + 1 >= raw.length) return null;
      try { return MemoryImage(base64Decode(raw.substring(commaIdx + 1))); } catch (_) { return null; }
    }
    return NetworkImage(raw);
  }
}

class _ZoneCoord {
  const _ZoneCoord(this.lat, this.lng);
  final double lat; final double lng;
}