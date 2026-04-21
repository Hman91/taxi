import 'package:flutter/material.dart';
import 'dart:convert';

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
import '../services/chat_socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/driver_ride_offer_card.dart';
import 'ride_chat_screen.dart';

class AppDriverScreen extends StatefulWidget {
  const AppDriverScreen({super.key});

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
  String? _message;
  bool _busy = false;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.driver);
    });
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
    final loc = AppLocalizations.of(context)!;
    final amount =
        (data['required_topup_dt'] as num?)?.round() ?? 100;
    final body = loc.driverWalletDepletedBody(amount);
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

  void _connectRealtime() {
    final t = _token;
    if (t == null) return;
    _socket.connect(
      t,
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

  Future<void> _login() async {
    final loc = AppLocalizations.of(context)!;
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
      rememberCurrentLocaleForRole(AppUiRole.driver);
      _token = r.accessToken;
      _userId = r.userId;
      _connectRealtime();
      final fares = await _api.getAirportFares();
      _locations = _startsFromRouteKeys(fares.keys, loc);
      if (_selectedLocation.isEmpty ||
          !_locations.contains(_selectedLocation)) {
        _selectedLocation = _locations.isNotEmpty ? _locations.first : '';
      }
      await _refreshRides();
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

  Future<void> _refreshRides() async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
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
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: info.conversationId,
          ),
        ),
      );
      await _refreshRides();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    _socket.disconnect();
    setState(() {
      _token = null;
      _userId = null;
      _driverPhotoUrl = null;
      _driverCarModel = null;
      _driverCarColor = null;
      _rides = [];
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
    w.add(TextButton(
        onPressed: _busy ? null : () => _openChat(r),
        child: Text(l10n.openChatButton)));
    return w;
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
