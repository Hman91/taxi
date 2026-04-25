import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/client.dart';
import '../app_locale.dart' show
    AppUiRole,
    applyPreferredLanguageToApp,
    appLocale,
    rememberCurrentLocaleForRole,
    restoreUiRoleLocale,
    userChoseLocaleThisSession;
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
import '../theme/taxi_app_theme.dart';
import 'ride_chat_screen.dart';

class AppPassengerScreen extends StatefulWidget {
  const AppPassengerScreen({super.key});

  @override
  State<AppPassengerScreen> createState() => _AppPassengerScreenState();
}

class _AppPassengerScreenState extends State<AppPassengerScreen> {
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
    // Web uses `<meta name="google-signin-client_id">`; Android/iOS need Web client for ID tokens.
    serverClientId: kIsWeb ? null : googleOAuthWebClientId,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.passenger);
    });
    if (kIsWeb) {
      _googleUserSub = _googleSignIn.onCurrentUserChanged.listen((account) {
        if (account != null && _token == null && mounted) {
          unawaited(_completeLoginWithGoogleAccount(account));
        }
      });
    }
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
    _ridesPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _token == null || _busy) return;
      _refreshRides(silent: true);
    });
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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = l10n.passengerLocationPermissionDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nearestZone = _nearestZoneFor(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _locationText =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _locationPlaceName = nearestZone;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _nearestZoneFor(double lat, double lng) {
    String? bestZone;
    double? bestDistance;
    for (final entry in _zoneCoords.entries) {
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        entry.value.lat,
        entry.value.lng,
      );
      if (bestDistance == null || d < bestDistance) {
        bestDistance = d;
        bestZone = entry.key;
      }
    }
    return bestZone;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _pushNotification({
    required String title,
    required String body,
    String? event,
    int? rideId,
  }) {
    final now = DateTime.now();
    final duplicate = _notifications.isNotEmpty
        ? _notifications.first
        : null;
    if (duplicate != null &&
        duplicate.event == event &&
        duplicate.rideId == rideId &&
        now.difference(duplicate.createdAt).inMilliseconds < 1200) {
      return;
    }
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _notifications.isEmpty
              ? Center(child: Text(l10n.notificationsEmpty))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      leading: Icon(
                        n.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: n.isRead
                            ? null
                            : Theme.of(context).colorScheme.tertiary,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.passengerRideNotificationTitle),
        content: Text(
          '${l10n.passengerRideNumberLine(ride.id)}\n'
          '${l10n.rideStatusFmt(localizedRideStatusLabel(l10n, ride.status))}\n'
          '${l10n.ridePickupLabel}: ${localizedPlaceName(l10n, ride.pickup)}\n'
          '${l10n.rideDestinationLabel}: ${localizedPlaceName(l10n, ride.destination)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.dialogOk),
          ),
        ],
      ),
    );
  }

  void _connectRealtime() {
    final t = _token;
    if (t == null) return;
    _socket.connect(
      t,
      transports: const ['polling'],
      onReceiveMessage: _onChatMessage,
      onRideStatus: (data) {
        if (!mounted) return;
        final rideMap = data['ride'];
        if (rideMap is Map) {
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
          if (event.isNotEmpty || message.isNotEmpty) {
            if (!mounted) return;
            final pl = AppLocalizations.of(context)!;
            _pushNotification(
              title: pl.notificationRideUpdateTitle,
              body: message.isNotEmpty
                  ? message
                  : pl.notificationRideUpdatedBody(ride.id),
              event: event,
              rideId: ride.id,
            );
          }
        }
      },
      onConnectError: (_) {},
    );
  }

  Future<int?> _resolveRideIdFromChatPayload(Map<String, dynamic> data) async {
    final directRideId = (data['ride_id'] as num?)?.toInt();
    if (directRideId != null) return directRideId;
    final conversationId = (data['conversation_id'] as num?)?.toInt();
    if (conversationId == null) return null;
    final cached = _rideIdByConversationId[conversationId];
    if (cached != null) return cached;
    final t = _token;
    if (t == null) return null;
    final candidates = _rides
        .where((r) => r.status == 'accepted' || r.status == 'ongoing')
        .toList();
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

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token;
    if (t == null) return;
    final candidates = rides
        .where((r) => r.status == 'accepted' || r.status == 'ongoing')
        .toList();
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
    final pairs = _conversationIdByRideId.entries.toList();
    for (final entry in pairs) {
      final rideId = entry.key;
      final conversationId = entry.value;
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

  void _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted) return;
    final msg = ChatMessage.fromJson(data);
    if (msg.senderUserId == _userId) return;
    final rideId = await _resolveRideIdFromChatPayload(data);
    if (!mounted) return;
    if (rideId == null) return;
    if (_activeChatRideId == rideId) return;
    final conversationId = (data['conversation_id'] as num?)?.toInt();
    if (conversationId != null) {
      _lastSeenMessageIdByConversationId[conversationId] = msg.id;
      _conversationIdByRideId[rideId] = conversationId;
      _rideIdByConversationId[conversationId] = rideId;
    }
    final l = AppLocalizations.of(context)!;
    final body = msg.displayText.trim().isEmpty
        ? l.openChatButton
        : msg.displayText;
    setState(() {
      _unreadChatByRideId[rideId] = (_unreadChatByRideId[rideId] ?? 0) + 1;
    });
    final senderName = (msg.senderName ?? '').trim();
    final title = senderName.isEmpty
        ? l.openChatButton
        : '${l.openChatButton} • $senderName';
    _pushNotification(
      title: title,
      body: body,
      event: 'chat_message',
      rideId: rideId,
    );
    LocalNotificationService.instance.show(title: title, body: body);
  }

  /// Interactive Google login for Android/iOS.
  /// Web uses GIS `renderButton` + `onCurrentUserChanged`.
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
      final l = AppLocalizations.of(context)!;
      setState(() => _message = l.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    }
  }

  Future<void> _completeLoginWithGoogleAccount(GoogleSignInAccount account) async {
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
        setState(() => _message = AppLocalizations.of(context)!.errorGoogleSignInMissingToken);
        return;
      }
      AppLoginResponse r;
      try {
        r = await _api.loginGoogle(
          idToken: hasIdToken ? idToken : null,
          accessToken: hasAccessToken ? accessToken : null,
        );
      } on TaxiApiException catch (e) {
        if (e.message == 'phone_required') {
          final phone = await _askRequiredPhoneForGoogle();
          if (phone == null || phone.trim().isEmpty) {
            if (!mounted) return;
            setState(() => _message = 'Phone number is required.');
            return;
          }
          r = await _api.loginGoogle(
            idToken: hasIdToken ? idToken : null,
            accessToken: hasAccessToken ? accessToken : null,
            phone: phone.trim(),
          );
        } else {
          rethrow;
        }
      }
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
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken;
      _userId = r.userId;
      _connectRealtime();
      _startRidesPolling();
      _fares = await _api.getAirportFares();
      await _detectPassengerLocation();
      await _refreshRides();
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.signedInWithGoogle)),
      );
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _message = l.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      _backendLoginInFlight = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askRequiredPhoneForGoogle() async {
    final ctrl = TextEditingController();
    final focusNode = FocusNode();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: const Text('Phone required'),
          content: TextField(
            controller: ctrl,
            focusNode: focusNode,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: 'Enter your phone number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    focusNode.dispose();
    ctrl.dispose();
    return result;
  }

  Future<void> _loginWithEmailPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please fill in email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginApp(email: email, password: password);
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
      rememberCurrentLocaleForRole(AppUiRole.passenger);
      _token = r.accessToken;
      _userId = r.userId;
      _connectRealtime();
      _startRidesPolling();
      _fares = await _api.getAirportFares();
      await _detectPassengerLocation();
      await _refreshRides();
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
    final photoUrl = _signupPhotoData.trim();
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please fill all required fields.');
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
        photoUrl: photoUrl,
      );
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
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
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
    if (!silent) {
      setState(() => _busy = true);
    }
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
        if (prev == null && ride.status == 'accepted' && !_acceptedNotifiedRideIds.contains(ride.id)) {
          final driver = ride.driverName ?? loc.driverNameFallback;
          final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(
            title: loc.notificationDriverAcceptedTitle,
            body: loc.notificationDriverAcceptedBody(driver, ps),
            event: 'ride_accepted',
            rideId: ride.id,
          );
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (prev == null || prev.status == ride.status) {
          continue;
        }
        if (prev.status == 'pending' && ride.status == 'accepted') {
          final driver = ride.driverName ?? loc.driverNameFallback;
          final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(
            title: loc.notificationDriverAcceptedTitle,
            body: loc.notificationDriverAcceptedBody(driver, ps),
            event: 'ride_accepted',
            rideId: ride.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.notificationDriverAcceptedSnack(driver, ps),
              ),
            ),
          );
          LocalNotificationService.instance.show(
            title: loc.notificationDriverAcceptedTitle,
            body: loc.notificationDriverAcceptedBody(driver, ps),
          );
          _acceptedNotifiedRideIds.add(ride.id);
        }
        if (ride.status == 'accepted' &&
            (ride.driverCurrentZone ?? '').trim().isNotEmpty &&
            ride.driverCurrentZone!.trim() == ride.pickup.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.passengerDriverNearPickupSnack)),
          );
          LocalNotificationService.instance.show(
            title: loc.notificationDriverNearPickupTitle,
            body: loc.notificationDriverNearPickupBody(ride.pickup),
          );
        }
        if (ride.status == 'accepted' && !_acceptedNotifiedRideIds.contains(ride.id)) {
          final driver = ride.driverName ?? loc.driverNameFallback;
          final ps = _phoneSuffix(ride.driverPhone);
          _pushNotification(
            title: loc.notificationDriverAcceptedTitle,
            body: loc.notificationDriverAcceptedBody(driver, ps),
            event: 'ride_accepted',
            rideId: ride.id,
          );
          _acceptedNotifiedRideIds.add(ride.id);
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() => _message = e.toString());
      }
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

    final routeKeys = _fares.keys.toList()
      ..sort((a, b) =>
          localizedRouteKeyForDisplay(l, a).compareTo(localizedRouteKeyForDisplay(l, b)));
    if (routeKeys.isEmpty) {
      setState(() => _message = l.noRidesYetApp);
      return;
    }

    String selectedRouteKey = routeKeys.first;
    if ((_locationPlaceName ?? '').trim().isNotEmpty) {
      for (final key in routeKeys) {
        final parts = key.split(airportRouteKeySeparator);
        if (parts.isNotEmpty && parts.first.trim() == _locationPlaceName!.trim()) {
          selectedRouteKey = key;
          break;
        }
      }
    }
    String promoCode = '';
    Map<String, dynamic>? quote;
    bool? ok;
    final promoCtrl = TextEditingController();

    Future<void> recalcQuote(StateSetter setDialogState) async {
      final rk = selectedRouteKey;
      try {
        final q = await _api.quoteAirport(rk);
        var fare = (q['base_fare'] as num?)?.toDouble() ?? (_fares[rk] ?? 0);
        final p = promoCtrl.text.trim();
        if (p == 'WELCOME26') fare *= 0.8;
        final h = DateTime.now().hour;
        if (h >= 21 || h < 5) fare *= 1.5;
        q['final_fare'] = double.parse(fare.toStringAsFixed(3));
        q['route_key'] = rk;
        q['promo_code'] = p;
        setDialogState(() => quote = q);
      } catch (_) {
        setDialogState(() => quote = null);
      }
    }

    ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.requestRideButton),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputDecorator(
                  decoration: InputDecoration(labelText: l.route),
                  child: DropdownButton<String>(
                    value: selectedRouteKey,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: routeKeys
                        .map((k) => DropdownMenuItem(
                              value: k,
                              child: Text(localizedRouteKeyForDisplay(l, k)),
                            ))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      selectedRouteKey = v;
                      await recalcQuote(setDialogState);
                      setDialogState(() {});
                    },
                  ),
                ),
                TextField(
                  controller: promoCtrl,
                  decoration: InputDecoration(labelText: l.promoCodeOptionalLabel),
                  onChanged: (_) async {
                    promoCode = promoCtrl.text.trim();
                    await recalcQuote(setDialogState);
                  },
                ),
                const SizedBox(height: 8),
                if (quote != null) ...[
                  _buildPassengerFareCard(
                    l,
                    (quote!['final_fare'] as num).toDouble(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${l.route}: ${localizedRouteKeyForDisplay(l, quote!['route_key'] as String)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: TaxiAppColors.textStrong,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.genericCancel)),
            FilledButton(
              onPressed: quote == null
                  ? null
                  : () {
                      promoCode = promoCtrl.text.trim();
                      Navigator.pop(ctx, true);
                    },
              child: Text(l.requestRideButton),
            ),
          ],
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
      await _api.createRide(token: t, pickup: pu, destination: de);
      await _refreshRides();
      if (!mounted) return;
      final fareText = (q['final_fare'] as num).toStringAsFixed(3);
      final promoPart = promoCode.isEmpty ? '' : ' | $promoCode';
      _pushNotification(
        title: l.notificationRequestSentTitle,
        body: l.notificationRequestSentBody,
        event: 'ride_request_sent',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.requestSentSnackLine(
              l.fareDt(fareText),
              promoPart,
            ),
          ),
        ),
      );
      LocalNotificationService.instance.show(
        title: l.notificationRequestSentTitle,
        body: l.notificationRequestSentBody,
      );
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
        builder: (ctx, setSt) => AlertDialog(
          title: Text(l.rateYourLastRide),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final s = i + 1;
              return IconButton(
                icon: Icon(
                  stars >= s ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setSt(() => stars = s),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.genericCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.submitRating),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.submitRating(token: t, rideId: ride.id, stars: stars);
      if (!mounted) return;
      setState(() => _ratedRideIds.add(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.thankYouFeedback)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
      setState(() {
        _activeChatRideId = ride.id;
        _unreadChatByRideId.remove(ride.id);
      });
      _rideIdByConversationId[info.conversationId] = ride.id;
      _conversationIdByRideId[ride.id] = info.conversationId;
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
      if (mounted && _activeChatRideId == ride.id) {
        setState(() => _activeChatRideId = null);
      }
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
    if (kIsWeb) {
      unawaited(_googleSignIn.signOut());
    }
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
    });
  }

  Widget _chatActionButton(Ride ride) {
    final l = AppLocalizations.of(context)!;
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton.icon(
        onPressed: _busy ? null : () => _openChat(ride),
        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.openChatButton,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  List<String> _startsFromFares(AppLocalizations l) {
    final starts = <String>{};
    for (final key in _fares.keys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.isNotEmpty) starts.add(parts.first.trim());
    }
    return starts.toList()
      ..sort((a, b) =>
          localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
  }

  List<String> _endsForStart(AppLocalizations l, String start) {
    final ends = <String>{};
    for (final key in _fares.keys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.length != 2) continue;
      if (parts.first.trim() == start) ends.add(parts[1].trim());
    }
    return ends.toList()
      ..sort((a, b) =>
          localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const activeStatuses = {'pending', 'accepted', 'ongoing'};
    final hasActiveRide = _rides.any((r) => activeStatuses.contains(r.status));
    final activeCount = _rides.where((r) => activeStatuses.contains(r.status)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appPassengerTitle),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.passenger,
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.roleAppPassenger,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.signInApp,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: l.emailLabel),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.passwordLabel),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _busy ? null : _loginWithEmailPassword,
                      icon: const Icon(Icons.login),
                      label: Text(l.signInApp),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (kIsWeb)
              const PassengerGoogleGsiButton()
            else
              OutlinedButton.icon(
                onPressed: _busy ? null : _loginWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(l.continueWithGoogle),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.registerAppAccount,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _signupNameCtrl,
                      decoration: InputDecoration(labelText: l.operatorDriverNameLabel),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _signupEmailCtrl,
                      decoration: InputDecoration(labelText: l.emailLabel),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _signupPhoneCtrl,
                      decoration: InputDecoration(labelText: l.operatorPhoneLabel),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _signupPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.passwordLabel),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickPassengerSignupImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(l.operatorPickFromGallery),
                    ),
                    if (_signupPhotoData.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (_) {
                          final provider =
                              _imageProviderFromString(_signupPhotoData);
                          if (provider == null) return const SizedBox.shrink();
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: provider,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _signupPhotoData = ''),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.operatorRemovePickedImage),
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _busy ? null : _registerPassengerAccount,
                      icon: const Icon(Icons.person_add),
                      label: Text(l.registerAppAccount),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              color: TaxiAppColors.darkPanel,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.passengerDispatchPanelTitle,
                      style: const TextStyle(
                        color: TaxiAppColors.gradientEnd,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.timelapse, size: 16),
                          label: Text(l.passengerActiveRidesChip(activeCount)),
                        ),
                        Chip(
                          avatar: const Icon(Icons.history, size: 16),
                          label: Text(l.passengerTotalRidesChip(_rides.length)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.my_location),
                title: Text(
                  _locationPlaceName != null
                      ? localizedPlaceName(l, _locationPlaceName)
                      : l.passengerLocationCurrent,
                ),
                subtitle: Text(
                  _locationPlaceName != null
                      ? '($_locationText)'
                      : (_locationText ??
                          (_locating
                              ? l.passengerLocationDetecting
                              : (_locationError ?? l.passengerLocationUnavailable))),
                ),
                trailing: IconButton(
                  tooltip: l.passengerRefreshLocationTooltip,
                  onPressed: _locating ? null : _detectPassengerLocation,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flight_takeoff, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l.passengerBookingSectionTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy || hasActiveRide ? null : _requestRide,
                      icon: const Icon(Icons.add_road),
                      label: Text(l.requestRideButton),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.myRidesHeading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_rides.isEmpty) Text(l.noRidesYetApp),
            ..._rides.map(
              (r) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  title: Text(localizedRideRouteRow(l, r.pickup, r.destination)),
                  subtitle: Text([
                    l.rideStatusFmt(localizedRideStatusLabel(l, r.status)),
                    if ((r.driverName ?? '').isNotEmpty)
                      l.passengerDriverLine(r.driverName!),
                    if ((r.driverPhone ?? '').isNotEmpty)
                      l.passengerPhoneLine(r.driverPhone!),
                  ].join('\n')),
                  isThreeLine: true,
                  leading: (() {
                    final provider = _imageProviderFromString(r.driverPhotoUrl);
                    if (provider == null) return const CircleAvatar(child: Icon(Icons.person));
                    return CircleAvatar(backgroundImage: provider);
                  })(),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (r.status != 'completed' && r.status != 'cancelled')
                        TextButton(
                          onPressed: _busy ? null : () => _cancelRide(r),
                          child: Text(l.cancelRidePassenger),
                        ),
                      _chatActionButton(r),
                      if (r.status == 'completed' && !_ratedRideIds.contains(r.id))
                        TextButton(
                          onPressed: _busy ? null : () => _rateCompletedRide(r),
                          child: Text(l.submitRating),
                        ),
                    ],
                  ),
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

  Widget _buildPassengerFareCard(
    AppLocalizations l,
    double finalFare,
  ) {
    final fareStr = finalFare.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: TaxiAppColors.darkPanel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$fareStr DT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.passengerFareFinalEstimate,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
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
