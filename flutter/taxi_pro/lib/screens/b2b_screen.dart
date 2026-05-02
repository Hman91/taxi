import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
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
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
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
  final _secretController = TextEditingController(text: 'Biz2026');
  final _guestController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _hotelController = TextEditingController();
  final _flightEtaController = TextEditingController();
  final _roomController = TextEditingController();
  Map<String, double> _fares = {};
  String? _routeKey;
  String? _token;
  String? _appToken;
  int? _userId;
  List<Ride> _rides = [];
  final List<AppNotification> _notifications = [];
  final Map<int, int> _unreadChatByRideId = {};
  final Map<int, int> _rideIdByConversationId = {};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  final Set<int> _ratedRideIds = <int>{};
  final Map<int, int> _ratingByRideId = <int, int>{};
  int? _activeChatRideId;
  int? _pendingRatingRideId;
  Timer? _pollingTimer;
  String? _message;
  bool _busy = false;
  bool _ok = false;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;
  int _rideUnread(int rideId) => _unreadChatByRideId[rideId] ?? 0;
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
      final fares = await _api.getAirportFares();
      _token = auth.accessToken;
      _appToken = auth.appAccessToken;
      _userId = auth.userId;
      if (_appToken != null) {
        _connectRealtime(_appToken!);
        await _refreshRides();
        _startPolling();
      }
      setState(() {
        _ok = true;
        _fares = fares;
        _routeKey = fares.keys.isNotEmpty ? fares.keys.first : null;
      });
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
    final route = _routeKey;
    final token = _token;
    if (guest.isEmpty || route == null || token == null) {
      setState(() => _message = l.loginFirst);
      return;
    }
    final room = _roomController.text.trim();
    final guestPhone = _guestPhoneController.text.trim();
    final hotel = _hotelController.text.trim();
    final flightEta = _flightEtaController.text.trim();
    final fare = (_fares[route] ?? 0).toDouble();
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
      sourceCode: _secretController.text.trim(),
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
      onReceiveMessage: (data) {
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        final senderId = (data['sender_user_id'] ?? data['sender_id']) as num?;
        final myUserId = _userId;
        if (senderId != null && myUserId != null && senderId.toInt() == myUserId) {
          return;
        }
        final rideIdRaw = data['ride_id'] as num?;
        final convIdRaw = data['conversation_id'] as num?;
        final rideId = rideIdRaw?.toInt() ??
            (convIdRaw != null ? _rideIdByConversationId[convIdRaw.toInt()] : null);
        if (rideId != null && _activeChatRideId != rideId) {
          setState(() => _unreadChatByRideId[rideId] = (_unreadChatByRideId[rideId] ?? 0) + 1);
        }
        final sender = (data['sender_name'] ?? '').toString().trim();
        final msg = (data['original_text'] ?? '').toString().trim();
        final title = sender.isEmpty ? l.openChatButton : '${l.openChatButton} • $sender';
        final body = msg.isEmpty ? l.openChatButton : msg;
        LocalNotificationService.instance.show(title: title, body: body);
        _pushNotification(
          title: title,
          body: body,
          event: 'receive_message',
          rideId: rideId,
        );
      },
    );
  }

  Future<void> _refreshRides() async {
    final t = _appToken;
    if (t == null) return;
    try {
      final list = await _api.listRides(t);
      if (!mounted) return;
      setState(() {
        _rides = list;
        _recomputePendingRatingFromRides();
      });
      for (final r in list) {
        if (r.status == 'cancelled') continue;
        try {
          final info = await _api.getRideConversation(token: t, rideId: r.id);
          if (info == null) continue;
          _rideIdByConversationId[info.conversationId] = r.id;
          _lastSeenMessageIdByConversationId.putIfAbsent(info.conversationId, () => 0);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_ok || _busy || _appToken == null) return;
      await _refreshRides();
      await _pollChatUnreadFallback();
    });
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _appToken;
    final uid = _userId;
    if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    final pairs = _rideIdByConversationId.entries.toList();
    for (final entry in pairs) {
      final conversationId = entry.key;
      final rideId = entry.value;
      if (_activeChatRideId == rideId) continue;
      try {
        final msgs = await _api.listConversationMessages(
          token: t,
          conversationId: conversationId,
          limit: 20,
        );
        if (msgs.isEmpty) continue;
        final prevSeen = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
        int maxId = prevSeen;
        int incomingCount = 0;
        ChatMessage? latestIncoming;
        for (final m in msgs) {
          if (m.id > maxId) maxId = m.id;
          if (prevSeen > 0 && m.id > prevSeen && m.senderUserId != uid) {
            incomingCount++;
            if (latestIncoming == null || m.id > latestIncoming.id) {
              latestIncoming = m;
            }
          }
        }
        if (prevSeen == 0) {
          _lastSeenMessageIdByConversationId[conversationId] = maxId;
          continue;
        }
        if (incomingCount > 0) {
          if (!mounted) return;
          setState(() {
            _unreadChatByRideId[rideId] =
                (_unreadChatByRideId[rideId] ?? 0) + incomingCount;
          });
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
            rideId: rideId,
          );
          LocalNotificationService.instance.show(title: title, body: body);
        }
        _lastSeenMessageIdByConversationId[conversationId] = maxId;
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
      setState(() {
        _activeChatRideId = ride.id;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _unreadChatByRideId.remove(ride.id);
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: info.conversationId,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _activeChatRideId = null;
        _unreadChatByRideId.remove(ride.id);
      });
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

  @override
  void initState() {
    super.initState();
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
    final fares = await _api.getAirportFares();
    _token = auth.accessToken;
    _appToken = auth.appAccessToken;
    _userId = auth.userId;
    if (_appToken != null) {
      _connectRealtime(_appToken!);
      await _refreshRides();
      _startPolling();
    }
    if (!mounted) return;
    setState(() {
      _ok = true;
      _fares = fares;
      _routeKey = fares.keys.isNotEmpty ? fares.keys.first : null;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socket.disconnect();
    _secretController.dispose();
    _guestController.dispose();
    _guestPhoneController.dispose();
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
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        centerTitle: true,
        title: _appBarHomeLogo(),
        backgroundColor: _C.charcoal,
        foregroundColor: Colors.white,
        actions: [
          const LocalePopupMenuButton(uiRole: AppUiRole.b2b),
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
                    obscureText: true,
                    decoration: _fd(l.companyCode, icon: Icons.business_rounded),
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
                        _rowInfoCard(
                          icon: Icons.verified_user,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.b2bConnectedStub,
                                style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.b2bConnectedWorkflowSubtitle,
                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                              ),
                            ],
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
                          _SectionHead(l.b2bBookOnAccountHeading, subtitle: 'Request a ride for a guest'),
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
                          InputDecorator(
                            decoration: _fd(l.route, icon: Icons.route_rounded),
                            child: DropdownButton<String>(
                              value: _routeKey,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: _fares.keys
                                  .map((k) => DropdownMenuItem(
                                        value: k,
                                        child: Text(
                                            localizedRouteKeyForDisplay(l, k)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _routeKey = v),
                            ),
                          ),
                          if (_routeKey != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${l.fareDt((_fares[_routeKey] ?? 0).toStringAsFixed(2))} ${l.b2bFareAdminPercentSuffix}',
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _C.charcoal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              onPressed: _busy ? null : _bookGuest,
                              child: Text(l.requestRideButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Module(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHead(l.b2bMonthlyUsageTitle),
                        _rowInfoCard(
                          icon: Icons.bar_chart,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.b2bMonthlyUsageTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(l.b2bMonthlyAmountDue('450.000'), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionHead(l.myRidesHeading, subtitle: '${_rides.length} rides'),
                  _Module(
                    child: _rides.isEmpty
                        ? Text(l.noRidesYetApp, style: const TextStyle(color: _C.textSoft))
                        : Column(
                            children: _rides
                                .map(
                                  (r) => Container(
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
                                                    final provider = _imageProviderFromString(r.driverPhotoUrl);
                                                    if (provider == null) return const SizedBox.shrink();
                                                    return CircleAvatar(radius: 16, backgroundImage: provider);
                                                  },
                                                )
                                              : null,
                                        ),
                                        Wrap(
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
                                            Container(
                                              decoration: BoxDecoration(
                                                color: _C.charcoal,
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3))],
                                              ),
                                              child: TextButton.icon(
                                                onPressed: _busy ? null : () => _openChat(r),
                                                icon: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                                                    if (_rideUnread(r.id) > 0)
                                                      Positioned(
                                                        right: -8,
                                                        top: -8,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                          decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(10)),
                                                          child: Text(
                                                            _rideUnread(r.id) > 99 ? '99+' : '${_rideUnread(r.id)}',
                                                            style: const TextStyle(color: _C.charcoal, fontSize: 10, fontWeight: FontWeight.w700),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                label: Text(
                                                  l.openChatButton,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ),
                                            if (r.status == 'completed' &&
                                                (_pendingRatingRideId == r.id || !_ratedRideIds.contains(r.id)))
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ...List.generate(5, (i) {
                                                    final star = i + 1;
                                                    return IconButton(
                                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                      padding: EdgeInsets.zero,
                                                      icon: Icon(
                                                        (_ratingByRideId[r.id] ?? 0) >= star ? Icons.star : Icons.star_border,
                                                        color: _C.yellowDeep,
                                                        size: 18,
                                                      ),
                                                      onPressed: _busy ? null : () => setState(() => _ratingByRideId[r.id] = star),
                                                    );
                                                  }),
                                                  const SizedBox(width: 4),
                                                  FilledButton(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: _C.yellow,
                                                      foregroundColor: _C.charcoal,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                                    ),
                                                    onPressed: _busy || ((_ratingByRideId[r.id] ?? 0) < 1) ? null : () => _submitRideRating(r.id),
                                                    child: Text(l.submitRating, style: const TextStyle(fontWeight: FontWeight.w800)),
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
