import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 1000;

  Future<void> init() async {
    if (kIsWeb) {
      // Plugin local notifications is not used on web.
      _initialized = true;
      return;
    }
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'ride_events',
      'Ride & dispatch',
      description: 'Ride status, driver wallet, and dispatch alerts',
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'chat_messages',
      'Chat messages',
      description: 'New chat messages while the app is in the background',
      importance: Importance.max,
    ));

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    bool isChat = false,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    final channelId = isChat ? 'chat_messages' : 'ride_events';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        isChat ? 'Chat messages' : 'Ride & dispatch',
        channelDescription: isChat
            ? 'New messages in ride chat'
            : 'Ride status, driver wallet, and dispatch',
        importance: isChat ? Importance.max : Importance.high,
        priority: isChat ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      await _plugin.show(_nextId++, title, body, details);
    } catch (e, st) {
      debugPrint('LocalNotificationService.show failed: $e\n$st');
      try {
        await _plugin.show(
          _nextId++,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              isChat ? 'Chat messages' : 'Ride & dispatch',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      } catch (_) {}
    }
  }
}
