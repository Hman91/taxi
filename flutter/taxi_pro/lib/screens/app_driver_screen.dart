import 'dart:async' show Timer, unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/client.dart';
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
import '../widgets/locale_popup_menu.dart';
import '../widgets/driver_ride_offer_card.dart';
import 'ride_chat_screen.dart';

class AppDriverScreen extends StatefulWidget {
  const AppDriverScreen({super.key, this.initialSession});
  final AppLoginResponse? initialSession;

  @override
  State<AppDriverScreen> createState() => _AppDriverScreenState();
}

class _AppDriverScreenState extends State<AppDriverScreen> {
  final _api = TaxiAppService();
  final _socket = ChatSocketService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  List<String> _locations = [];
  String? _token;
  int? _userId;
  String _selectedLocation = '';
  String? _driverPhotoUrl;
  String? _driverCarModel;
  String? _driverCarColor;
  List<Ride> _rides = [];
  final Set<int> _dismissedPendingRideIds = {};
  final List<AppNotification> _notifications = [];
  final Map<int, int> _unreadChatByRideId = <int, int>{};
  final Map<int, int> _rideIdByConversationId = <int, int>{};
  final Map<int, int> _conversationIdByRideId = <int, int>{};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  int? _activeChatRideId;
  String? _message;
  bool _busy = false;
  double? _lastWalletSample;
  DateTime? _lastWalletDepletedNotifAt;
  /// Dedupes alerts when gains first load while wallet is already 0 (no prev > 0 → 0 transition).
  bool _walletDepletedNotifiedForZero = false;
  Timer? _periodicRideTimer;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.driver);
      final s = widget.initialSession;
      if (s != null && _token == null) unawaited(_bootstrapFromSession(s));
    });
  }

  Future<void> _bootstrapFromSession(AppLoginResponse r) async {
    if (!userChoseLocaleThisSession.value) {
      applyPreferredLanguageToApp(r.preferredLanguage);
    }
    rememberCurrentLocaleForRole(AppUiRole.driver);
    _token = r.accessToken;
    _userId = r.userId;
    await SessionStore.saveAppDriver(r);
    _unreadChatByRideId.clear();
    _rideIdByConversationId.clear();
    _conversationIdByRideId.clear();
    _lastSeenMessageIdByConversationId.clear();
    _activeChatRideId = null;
    _connectRealtime();
    final fares = await _api.getAirportFares();
    final loc = AppLocalizations.of(context)!;
    _locations = _startsFromRouteKeys(fares.keys, loc);
    if (_selectedLocation.isEmpty || !_locations.contains(_selectedLocation)) {
      _selectedLocation = _locations.isNotEmpty ? _locations.first : '';
    }
    await _refreshRides();
    _startPeriodicRideSync();
    if (mounted) setState(() {});
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
          rideId: rideId,
          event: event,
          createdAt: now,
        ),
      );
      if (_notifications.length > 60) {
        _notifications.removeRange(60, _notifications.length);
      }
    });
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _notifications.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.notificationsEmpty))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      leading: Icon(
                        n.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: n.isRead ? null : Theme.of(context).colorScheme.tertiary,
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(n.body),
                      trailing: n.isRead ? null : const Icon(Icons.brightness_1, size: 10),
                      onTap: () {
                        setState(() => n.isRead = true);
                        Navigator.of(context).pop();
                        final ride = n.rideId == null
                            ? null
                            : _rides.where((r) => r.id == n.rideId).cast<Ride?>().firstWhere(
                                  (r) => r != null,
                                  orElse: () => null,
                                );
                        if (ride != null) {
                          _showRideNotificationDetails(ride);
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(n.body)));
                        }
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showRideNotificationDetails(Ride ride) {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.passengerRideNotificationTitle),
        content: Text(
          '${loc.passengerRideNumberLine(ride.id)}\n'
          '${loc.rideStatusFmt(localizedRideStatusLabel(loc, ride.status))}\n'
          '${loc.ridePickupLabel}: ${localizedPlaceName(loc, ride.pickup)}\n'
          '${loc.rideDestinationLabel}: ${localizedPlaceName(loc, ride.destination)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.dialogOk),
          ),
        ],
      ),
    );
  }

  void _onDriverWallet(Map<String, dynamic> data) {
    if (!mounted) return;
    final event = (data['event'] ?? '').toString();
    if (event != 'wallet_depleted') return;
    final wbRaw = data['wallet_balance'];
    if (wbRaw is num) {
      _lastWalletSample = wbRaw.toDouble();
    }
    final now = DateTime.now();
    if (_lastWalletDepletedNotifAt != null &&
        now.difference(_lastWalletDepletedNotifAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastWalletDepletedNotifAt = now;
    _walletDepletedNotifiedForZero = true;
    final loc = AppLocalizations.of(context)!;
    final amount =
        (data['required_topup_dt'] as num?)?.round() ?? 100;
    final body = ((data['message'] ?? '').toString().trim().isNotEmpty)
        ? (data['message'] as String).trim()
        : loc.driverWalletDepletedBody(amount);
    _pushNotification(
      title: loc.driverWalletDepletedTitle,
      body: body,
      event: 'wallet_depleted',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(body)),
    );
    LocalNotificationService.instance.show(
      title: loc.driverWalletDepletedTitle,
      body: body,
    );
  }

  Future<void> _pollWalletDepletionFromApi() async {
    final t = _token;
    if (t == null) return;
    try {
      final g = await _api.driverGains(t);
      if (!mounted) return;
      final wb = (g['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      final prev = _lastWalletSample;
      _lastWalletSample = wb;
      if (wb > 0) {
        _walletDepletedNotifiedForZero = false;
      } else if (wb <= 0) {
        final crossedZero = prev != null && prev > 0;
        final openedFreshAtZero =
            prev == null && !_walletDepletedNotifiedForZero;
        if (crossedZero || openedFreshAtZero) {
          _onDriverWallet({
            'event': 'wallet_depleted',
            'wallet_balance': wb,
            'required_topup_dt': 100,
            'message': '',
          });
        }
      }
    } catch (_) {}
  }

  void _connectRealtime() {
    final t = _token;
    if (t == null) return;
    _socket.connect(
      t,
      onReceiveMessage: _onChatMessage,
      onDriverWallet: _onDriverWallet,
      onRideStatus: (data) {
        if (!mounted) return;
        final rideMap = data['ride'];
        if (rideMap is! Map) return;
        final ride = Ride.fromJson(Map<String, dynamic>.from(rideMap));
        setState(() {
          final idx = _rides.indexWhere((r) => r.id == ride.id);
          if (idx >= 0) {
            _rides[idx] = ride;
          } else {
            _rides.insert(0, ride);
          }
        });
        final event = (data['event'] ?? '').toString();
        final message = (data['message'] ?? '').toString();
        if (event == 'ride_request_sent') {
          final loc = AppLocalizations.of(context)!;
          _pushNotification(
            title: loc.driverNotificationNewNearbyTitle,
            body: message.isNotEmpty
                ? message
                : loc.driverNotificationNewNearbyBodyDefault,
            event: event,
            rideId: ride.id,
          );
        } else if (event == 'ride_taken_by_other_driver') {
          final accepterUserId = (data['accepted_driver_user_id'] as num?)?.toInt()
              ?? (data['driver_id'] as num?)?.toInt();
          if (accepterUserId != null && _userId != null && accepterUserId == _userId) {
            return;
          }
          final loc = AppLocalizations.of(context)!;
          _pushNotification(
            title: loc.driverNotificationTakenTitle,
            body: message.isNotEmpty
                ? message
                : loc.driverNotificationTakenBodyDefault,
            event: event,
            rideId: ride.id,
          );
        } else if (event == 'ride_cancelled_by_passenger' || event == 'ride_cancelled') {
          final loc = AppLocalizations.of(context)!;
          _pushNotification(
            title: loc.driverNotificationCancelledTitle,
            body: message.isNotEmpty
                ? message
                : loc.driverNotificationCancelledBodyDefault,
            event: event,
            rideId: ride.id,
          );
        } else if (message.isNotEmpty) {
          final loc = AppLocalizations.of(context)!;
          _pushNotification(
            title: loc.notificationRideUpdateTitle,
            body: message,
            event: event,
            rideId: ride.id,
          );
        }
      },
    );
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
    final candidates =
        _rides.where((r) => rideMayHaveConversation(r.status)).toList();
    for (final ride in candidates) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
        if (info.conversationId == conversationId) {
          return ride.id;
        }
      } catch (_) {}
    }
    return null;
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
      final tok = _token;
      if (tok != null) {
        try {
          final list = await _api.listRides(tok);
          if (!mounted) return;
          setState(() => _rides = list);
          await _syncConversationRideMap(list);
        } catch (_) {}
      }
      if (!mounted) return;
      rideId = await _resolveRideIdFromChatPayload(data);
    }
    if (!mounted || rideId == null) return;
    final conversationId = intFromDynamic(data['conversation_id']);
    final int rid = rideId;
    if (conversationId != null) {
      final prev = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
      if (msg.id > prev) _lastSeenMessageIdByConversationId[conversationId] = msg.id;
      _conversationIdByRideId[rid] = conversationId;
      _rideIdByConversationId[conversationId] = rid;
    }
    if (_activeChatRideId == rid) return;
    final loc = AppLocalizations.of(context)!;
    final body = msg.displayText.trim().isEmpty ? loc.openChatButton : msg.displayText;
    setState(() {
      _unreadChatByRideId[rid] = (_unreadChatByRideId[rid] ?? 0) + 1;
    });
    final senderName = (msg.senderName ?? '').trim();
    final title = senderName.isEmpty
        ? loc.openChatButton
        : '${loc.openChatButton} • $senderName';
    _pushNotification(
      title: title,
      body: body,
      event: 'chat_message',
      rideId: rid,
    );
    LocalNotificationService.instance.show(title: title, body: body, isChat: true);
  }

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token;
    if (t == null) return;
    final candidates =
        rides.where((r) => rideMayHaveConversation(r.status)).toList();
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
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    for (final ride
        in _rides.where((r) => rideMayHaveConversation(r.status) && _isMine(r))) {
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

  void _startPeriodicRideSync() {
    _periodicRideTimer?.cancel();
    Future<void> tick() async {
      if (!mounted || _token == null || _userId == null) return;
      if (_busy) {
        await _pollChatUnreadFallback();
      } else {
        await _refreshRides(quiet: true);
      }
    }

    unawaited(tick());
    _periodicRideTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => unawaited(tick()));
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginApp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!userChoseLocaleThisSession.value) {
        applyPreferredLanguageToApp(r.preferredLanguage);
      } else {
        try {
          await _api.patchPreferredLanguage(
            token: r.accessToken,
            preferredLanguage: appLocale.value.languageCode,
          );
        } catch (_) {}
      }
      await _bootstrapFromSession(r);
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _message = l.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.registerAppUser(
        email: _email.text.trim(),
        password: _password.text,
        role: 'driver',
      );
      await _login();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshRides({bool quiet = false}) async {
    final t = _token;
    if (t == null) return;
    if (!quiet) {
      setState(() => _busy = true);
    }
    try {
      final list = await _api.listRides(t);
      final mine = list.where((r) => _isMine(r)).toList();
      final ownPhoto =
          mine.map((r) => r.driverPhotoUrl).firstWhere((v) => (v ?? '').trim().isNotEmpty, orElse: () => null);
      final ownModel =
          mine.map((r) => r.driverCarModel).firstWhere((v) => (v ?? '').trim().isNotEmpty, orElse: () => null);
      final ownColor =
          mine.map((r) => r.driverCarColor).firstWhere((v) => (v ?? '').trim().isNotEmpty, orElse: () => null);
      setState(() {
        _rides = list;
        _driverPhotoUrl = ownPhoto ?? _driverPhotoUrl;
        _driverCarModel = ownModel ?? _driverCarModel;
        _driverCarColor = ownColor ?? _driverCarColor;
        _message = null;
      });
      await _syncConversationRideMap(list);
      await _pollChatUnreadFallback();
      await _pollWalletDepletionFromApi();
    } catch (e) {
      if (!quiet) {
        setState(() => _message = e.toString());
      }
    } finally {
      if (mounted && !quiet) setState(() => _busy = false);
    }
  }

  Future<void> _accept(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.acceptRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.rejectRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.startRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.completeRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
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
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: cid,
          ),
        ),
      );
      if (mounted && _activeChatRideId == ride.id) {
        setState(() => _activeChatRideId = null);
      }
      await _primeReadWatermarkAfterChat(token: t, conversationId: cid, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted && _activeChatRideId == ride.id) {
        setState(() => _activeChatRideId = null);
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    unawaited(SessionStore.clear());
    _periodicRideTimer?.cancel();
    _periodicRideTimer = null;
    _socket.disconnect();
    setState(() {
      _token = null;
      _userId = null;
      _driverPhotoUrl = null;
      _driverCarModel = null;
      _driverCarColor = null;
      _rides = [];
      _unreadChatByRideId.clear();
      _rideIdByConversationId.clear();
      _conversationIdByRideId.clear();
      _lastSeenMessageIdByConversationId.clear();
      _activeChatRideId = null;
      _dismissedPendingRideIds.clear();
      _notifications.clear();
      _message = null;
    });
  }

  List<Widget> _actionsFor(Ride r) {
    final l10n = AppLocalizations.of(context)!;
    final w = <Widget>[];
    if (r.status == 'pending') {
      w.add(TextButton(
          onPressed: _busy ? null : () => _accept(r),
          child: Text(l10n.acceptRide)));
    }
    if (r.status == 'accepted' || r.status == 'ongoing') {
      w.add(TextButton(
          onPressed: _busy ? null : () => _reject(r),
          child: Text(l10n.rejectRide)));
    }
    if (r.status == 'accepted') {
      w.add(TextButton(
          onPressed: _busy ? null : () => _start(r),
          child: Text(l10n.startRide)));
    }
    if (r.status == 'ongoing') {
      w.add(TextButton(
          onPressed: _busy ? null : () => _complete(r),
          child: Text(l10n.completeRide)));
    }
    if (rideMayHaveConversation(r.status)) {
      w.add(_chatActionButton(r, l10n));
    }
    return w;
  }

  Widget _chatActionButton(Ride ride, AppLocalizations l10n) {
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return Badge(
      label: Text(
        unread > 99 ? '99+' : '$unread',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      padding: EdgeInsets.only(left: unread > 0 ? 6 : 0, right: unread > 0 ? 6 : 0),
      isLabelVisible: unread > 0,
      offset: const Offset(8, -6),
      backgroundColor: Colors.redAccent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextButton.icon(
          onPressed: _busy ? null : () => _openChat(ride),
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
          label: Text(
            l10n.openChatButton,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }

  bool _isMine(Ride r) => _userId != null && r.driverId == _userId;

  List<Ride> _activeMine() => _rides
      .where((r) =>
          _isMine(r) && (r.status == 'accepted' || r.status == 'ongoing'))
      .toList();

  List<Ride> _pendingForLocation() => _rides
      .where((r) =>
          r.status == 'pending' &&
          r.pickup.trim() == _selectedLocation.trim() &&
          !_dismissedPendingRideIds.contains(r.id))
      .toList();

  void _declineOffer(Ride r) {
    setState(() => _dismissedPendingRideIds.add(r.id));
  }

  List<String> _startsFromRouteKeys(
      Iterable<String> routeKeys, AppLocalizations loc) {
    final starts = <String>{};
    for (final key in routeKeys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.isNotEmpty) starts.add(parts.first.trim());
    }
    return starts.toList()
      ..sort((a, b) => localizedPlaceName(loc, a)
          .compareTo(localizedPlaceName(loc, b)));
  }

  @override
  void dispose() {
    _periodicRideTimer?.cancel();
    _socket.disconnect();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appDriverTitle),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.driver,
          ),
          if (_token != null) ...[
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
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 14),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
                onPressed: _busy ? null : _refreshRides,
                icon: const Icon(Icons.refresh)),
            TextButton(onPressed: _logout, child: Text(l.logoutApp)),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_token == null) ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.emailLabel),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passwordLabel),
            ),
            FilledButton(
                onPressed: _busy ? null : _login, child: Text(l.signInApp)),
            TextButton(
                onPressed: _busy ? null : _register,
                child: Text(l.registerDriverAccount)),
          ] else ...[
            if ((_driverPhotoUrl ?? '').trim().isNotEmpty ||
                (_driverCarModel ?? '').trim().isNotEmpty ||
                (_driverCarColor ?? '').trim().isNotEmpty)
              Card(
                child: ListTile(
                  leading: Builder(
                    builder: (context) {
                      final provider = _imageProviderFromString(_driverPhotoUrl);
                      if (provider == null) return const Icon(Icons.directions_car);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(
                          image: provider,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.directions_car),
                        ),
                      );
                    },
                  ),
                  title: Text(l.driverMyVehicleTitle),
                  subtitle: Text(
                    l.driverVehicleSummaryLine(
                      (_driverCarModel ?? '').trim().isEmpty
                          ? '—'
                          : _driverCarModel!,
                      (_driverCarColor ?? '').trim().isEmpty
                          ? '—'
                          : _driverCarColor!,
                    ),
                  ),
                ),
              ),
            DropdownButtonFormField<String>(
              value: _selectedLocation.isEmpty ? null : _selectedLocation,
              decoration: InputDecoration(labelText: l.ridePickupLabel),
              items: _locations
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(localizedPlaceName(l, e)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedLocation = v ?? _selectedLocation),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _refreshRides,
              child: Text(l.adminLoadRidesBtn),
            ),
            const SizedBox(height: 8),
            Text(l.driverPendingRides,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_activeMine().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l.rideStatusFmt(localizedRideStatusLabel(l, 'active')),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            ..._activeMine().map(
              (r) => Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizedRideRouteRow(l, r.pickup, r.destination)),
                      Text(
                        l.rideStatusFmt(
                          localizedRideStatusLabel(l, r.status),
                        ),
                      ),
                      if (r.isB2b == true)
                        Text(
                          'B2B • ${r.b2bGuestName ?? '-'} • Room ${r.b2bRoomNumber ?? '-'}'
                          ' • ${r.b2bSourceCode ?? '-'}'
                          ' • ${((r.b2bFare ?? 0)).toStringAsFixed(3)} DT',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if ((r.passengerName ?? '').trim().isNotEmpty ||
                          (r.passengerPhone ?? '').trim().isNotEmpty)
                        Text(
                          'Passenger: ${(r.passengerName ?? '').trim().isEmpty ? '-' : r.passengerName}'
                          ' • ${(r.passengerPhone ?? '').trim().isEmpty ? '-' : r.passengerPhone}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      Wrap(spacing: 4, children: _actionsFor(r)),
                    ],
                  ),
                ),
              ),
            ),
            if (_pendingForLocation().isEmpty && _activeMine().isEmpty)
              Text(l.noRidesYetApp),
            ..._pendingForLocation().map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DriverRideOfferCard(
                  ride: r,
                  api: _api,
                  busy: _busy,
                  onAccept: () => _accept(r),
                  onReject: () => _declineOffer(r),
                ),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
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
