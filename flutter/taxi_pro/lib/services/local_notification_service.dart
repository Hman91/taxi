import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 1000;

  static bool get _isLinuxDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: _isLinuxDesktop
          ? const LinuxInitializationSettings(defaultActionName: 'Open')
          : null,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await init();
    }
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'ride_events',
        'Ride Events',
        channelDescription: 'Taxi ride updates and dispatch notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      linux: _isLinuxDesktop ? const LinuxNotificationDetails() : null,
    );
    await _plugin.show(_nextId++, title, body, details);
  }
}
