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
import '../services/chat_socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import 'ride_chat_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
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
  String? _carModel;
  String? _carColor;
  String? _photoUrl;
  String? _message;
  List<Ride> _rides = [];
  final List<AppNotification> _notifications = [];
  final Set<int> _seenPendingRideIds = <int>{};
  final Set<int> _notifiedClosedRideIds = <int>{};
  Set<int> _lastPendingRideIds = <int>{};
  final Set<int> _selfAcceptedRideIds = <int>{};
  bool _busy = false;
  Timer? _ridesPollingTimer;

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
          createdAt: now,
          event: event,
          rideId: rideId,
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
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginDriverPin(
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
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
      setState(() {
        _token = r.accessToken;
        _userId = r.userId;
        _driverId = r.driverId;
        _driverName = r.driverName;
        _walletBalance = r.walletBalance;
        _carModel = r.carModel;
        _carColor = r.carColor;
        _photoUrl = r.photoUrl;
        _message = l.loggedInAs(r.role);
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
      _socket.connect(
        r.accessToken,
        onRideStatus: _onRideStatusEvent,
        onDriverWallet: _onDriverWallet,
        transports: kIsWeb ? ['websocket'] : ['polling'],
      );
      _startRidesPolling();
      await _pushDriverLocation();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshRides({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) {
      setState(() {
        _busy = true;
        _message = null;
      });
    }
    try {
      final previousById = {for (final r in _rides) r.id: r};
      final rides = await _api.listRides(t);
      if (_driverId == null) {
        for (final r in rides) {
          if (r.driverId != null) {
            _driverId = r.driverId;
            break;
          }
        }
      }
      setState(() => _rides = rides);
      if (mounted) _processRideTransitions(previousById, rides);
    } catch (e) {
      if (!silent) {
        setState(() => _message = e.toString());
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _processRideTransitions(Map<int, Ride> previousById, List<Ride> rides) {
    final loc = AppLocalizations.of(context)!;
    final currentById = {for (final r in rides) r.id: r};
    final currentPendingRideIds = rides
        .where((r) => r.status == 'pending')
        .map((r) => r.id)
        .toSet();

    final removedPending = _lastPendingRideIds.difference(currentPendingRideIds);
    for (final rideId in removedPending) {
      if (_selfAcceptedRideIds.contains(rideId)) {
        _selfAcceptedRideIds.remove(rideId);
        continue;
      }
      final stillVisible = currentById[rideId];
      if (stillVisible != null &&
          _driverId != null &&
          stillVisible.driverId == _driverId) {
        continue;
      }
      if (_notifiedClosedRideIds.contains(rideId)) continue;
      _notifiedClosedRideIds.add(rideId);
      _pushNotification(
        title: loc.driverNotificationRequestClosedTitle,
        body: loc.driverNotificationRequestClosedBodyOther,
        event: 'ride_no_longer_visible',
        rideId: rideId,
      );
    }
    _lastPendingRideIds = currentPendingRideIds;

    for (final ride in rides) {
      final prev = previousById[ride.id];
      if (prev == null && ride.status == 'pending') {
        _seenPendingRideIds.add(ride.id);
        _pushNotification(
          title: loc.driverNotificationNewRideTitle,
          body: loc.driverNotificationNewRideBodyDefault,
          event: 'ride_request_sent',
          rideId: ride.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.snackDriverNewNearbyRide)),
        );
        LocalNotificationService.instance.show(
          title: loc.driverNotificationNewRideTitle,
          body: loc.driverNotificationNewRideBodyDefault,
        );
      } else if (prev != null &&
          prev.status == 'pending' &&
          ride.status == 'accepted') {
        if (_selfAcceptedRideIds.contains(ride.id) ||
            (_driverId != null && ride.driverId == _driverId)) {
          _selfAcceptedRideIds.remove(ride.id);
              continue;
            }
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(
          title: loc.driverNotificationRequestClosedTitle,
          body: loc.driverNotificationRequestClosedBodyTaken,
          event: 'ride_taken_by_other_driver',
          rideId: ride.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.snackDriverRideTakenOther)),
        );
        LocalNotificationService.instance.show(
          title: loc.driverNotificationRequestClosedTitle,
          body: loc.driverNotificationRequestClosedBodyTaken,
        );
      } else if (prev != null &&
          prev.status != 'cancelled' &&
          ride.status == 'cancelled') {
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(
          title: loc.driverNotificationCancelledTitle,
          body: loc.driverNotificationCancelledBodyDefault,
          event: 'ride_cancelled_by_passenger',
          rideId: ride.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.snackDriverPassengerCancelled)),
        );
        LocalNotificationService.instance.show(
          title: loc.driverNotificationCancelledTitle,
          body: loc.driverNotificationCancelledBodyDefault,
        );
      }
      if (ride.status != 'pending') {
        _seenPendingRideIds.remove(ride.id);
      }
    }
    for (final prev in previousById.values) {
      if (prev.status == 'pending' &&
          !currentById.containsKey(prev.id) &&
          _seenPendingRideIds.contains(prev.id) &&
          !_notifiedClosedRideIds.contains(prev.id)) {
        _notifiedClosedRideIds.add(prev.id);
        _pushNotification(
          title: loc.driverNotificationRequestClosedTitle,
          body: loc.driverNotificationRequestClosedBodyOther,
          event: 'ride_no_longer_visible',
          rideId: prev.id,
        );
        _seenPendingRideIds.remove(prev.id);
      }
    }
  }

  void _startRidesPolling() {
    _ridesPollingTimer?.cancel();
    _ridesPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _token == null || _busy) return;
      _refreshRides(silent: true);
    });
  }

  Future<void> _pushDriverLocation() async {
    final t = _token;
    if (t == null || _location.isEmpty) return;
    try {
      await _api.updateDriverLocation(token: t, currentZone: _location);
    } catch (_) {}
  }

  void _onDriverWallet(Map<String, dynamic> data) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final wb = data['wallet_balance'];
    if (wb is num) {
      setState(() => _walletBalance = wb.toDouble());
    }
    final event = (data['event'] ?? '').toString();
    if (event != 'wallet_depleted') return;
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

  void _onRideStatusEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final event = (payload['event'] ?? '').toString();
    if (event == 'ride_taken_by_other_driver') {
      final accepterUserId = (payload['accepted_driver_user_id'] as num?)?.toInt()
          ?? (payload['driver_id'] as num?)?.toInt();
      if (accepterUserId != null && _userId != null && accepterUserId == _userId) {
        return;
      }
      _pushNotification(
        title: loc.driverNotificationRequestClosedTitle,
        body: loc.driverNotificationRequestClosedBodyTaken,
        event: event,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.snackDriverRideTakenOther)),
      );
      LocalNotificationService.instance.show(
        title: loc.driverNotificationRequestClosedTitle,
        body: loc.driverNotificationRequestClosedBodyTaken,
      );
      _refreshRides();
      return;
    }
    if (event == 'ride_request_sent') {
      _pushNotification(
        title: loc.driverNotificationNewRideTitle,
        body: loc.driverNotificationNewRideBodyDefault,
        event: event,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.snackDriverNewNearbyRide)),
      );
      LocalNotificationService.instance.show(
        title: loc.driverNotificationNewRideTitle,
        body: loc.driverNotificationNewRideBodyDefault,
      );
      _refreshRides();
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    _selfAcceptedRideIds.add(ride.id);
    setState(() => _busy = true);
    try {
      await _api.acceptRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      _selfAcceptedRideIds.remove(ride.id);
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _releaseRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.rejectRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.startRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.completeRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat(Ride ride) async {
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null || uid <= 0) return;
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.snackDriverChatAfterAcceptance)),
        );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _ridesPollingTimer?.cancel();
    _socket.disconnect();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final trackedRides = _rides
        .where((r) =>
            r.status == 'pending' ||
            (r.status == 'accepted' && r.driverId != null) ||
            r.status == 'ongoing')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appDriverTitle),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.driver,
          ),
          if (_token != null)
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.roleAppDriver,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.emailLabel),
                  ),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l.passwordLabel),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Text(l.login),
                  ),
                ],
              ),
            ),
          ),
          if (_token != null)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${l.sessionActive}${_driverName == null ? '' : ' — $_driverName'}'
                  ' | ${l.walletWithAmount(_walletBalance.toStringAsFixed(3))}',
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
            ),
          if (_token != null && (_carModel != null || _carColor != null)) ...[
            const SizedBox(height: 6),
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.directions_car),
                title: Text(l.driverVehicleIdentityTitle),
                subtitle: Text(
                  l.driverVehicleSummaryLine(
                    (_carModel ?? '').trim().isEmpty ? '—' : _carModel!,
                    (_carColor ?? '').trim().isEmpty ? '—' : _carColor!,
                  ),
                ),
              ),
            ),
          ],
          if (_token != null && (_photoUrl?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final provider = _imageProviderFromString(_photoUrl);
              if (provider == null) return const SizedBox.shrink();
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: provider,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              );
            }),
          ],
          if (_token != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.driverPendingRides,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: InputDecoration(labelText: l.ridePickupLabel),
                      child: DropdownButton<String>(
                        value: _location.isEmpty ? null : _location,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _locations
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(localizedPlaceName(l, e)),
                                ))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => _location = v);
                          await _pushDriverLocation();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _busy ? null : _refreshRides,
                      child: Text(l.adminLoadRidesBtn),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.list_alt, size: 16),
                          label: Text(l.driverOpenRequestsChip(trackedRides.length)),
                        ),
                        Chip(
                          avatar: const Icon(Icons.notifications_active, size: 16),
                          label: Text(l.driverUnreadAlertsChip(_unreadCount)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...trackedRides.map(
                  (r) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizedRideRouteRow(l, r.pickup, r.destination)),
                          Text(
                            l.rideStatusFmt(
                              localizedRideStatusLabel(l, r.status),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (r.status == 'pending')
                                TextButton(
                                  onPressed:
                                      _busy ? null : () => _acceptRide(r),
                                  child: Text(l.acceptRide),
                                ),
                              if (r.status == 'accepted')
                                TextButton(
                                  onPressed: _busy ? null : () => _startRide(r),
                                  child: Text(l.startRide),
                                ),
                              if (r.status == 'accepted' ||
                                  r.status == 'ongoing')
                                TextButton(
                                  onPressed:
                                      _busy ? null : () => _releaseRide(r),
                                  child: Text(l.rejectRide),
                                ),
                              if (r.status == 'ongoing')
                                FilledButton(
                                  onPressed:
                                      _busy ? null : () => _completeRide(r),
                                  child: Text(l.completeRide),
                                ),
                              if (r.status == 'accepted' || r.status == 'ongoing')
                                TextButton(
                                  onPressed: _busy ? null : () => _openChat(r),
                                  child: Text(l.openChatButton),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
          if (_message != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_message!)),
        ],
      ),
    );
  }

  List<String> _startsFromRouteKeys(
      Iterable<String> routeKeys, AppLocalizations l) {
    final starts = <String>{};
    for (final key in routeKeys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.isNotEmpty) {
        starts.add(parts.first.trim());
      }
    }
    return starts.toList()
      ..sort((a, b) =>
          localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
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
