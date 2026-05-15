import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api/models.dart';
import 'app_locale.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_passenger_screen.dart';
import 'screens/passenger_home_screen.dart';
import 'api/auth_token_store.dart';
import 'services/local_notification_service.dart';
import 'services/session_store.dart';
import 'theme/taxi_app_theme.dart';
import 'widgets/passenger_language_reminder_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeFuture = loadStoredPreferredLanguage();
  runApp(const PassengerApp());
  await localeFuture;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(LocalNotificationService.instance.init());
  });
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Taxi Tunisia Passenger',
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTaxiProTheme(),
          builder: (context, child) =>
              TaxiProBackground(child: child ?? const SizedBox.shrink()),
          home: const _PassengerSessionGate(),
        );
      },
    );
  }
}

class _PassengerSessionGate extends StatefulWidget {
  const _PassengerSessionGate();

  @override
  State<_PassengerSessionGate> createState() => _PassengerSessionGateState();
}

class _PassengerSessionGateState extends State<_PassengerSessionGate> {
  Widget? _home;
  bool _languageReminderQueued = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final s = await SessionStore.load();
    if (s != null) {
      await AuthTokenStore.instance.ensureFreshAccess();
    }
    if (!mounted) return;
    setState(() {
      _home = _screenFromSession(s) ?? const PassengerHomeScreen();
    });
    _queueLanguageReminder(s);
  }

  void _queueLanguageReminder(PersistedSession? session) {
    if (_languageReminderQueued) return;
    _languageReminderQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = session?.role == PersistedRole.appPassenger
          ? session?.appLogin?.accessToken
          : null;
      showPassengerLanguageReminderSheet(context: context, authToken: token);
    });
  }

  Widget? _screenFromSession(PersistedSession? s) {
    if (s == null) return null;
    if (s.role != PersistedRole.appPassenger) return null;
    final AppLoginResponse? r = s.appLogin;
    return r == null ? null : AppPassengerScreen(initialSession: r);
  }

  @override
  Widget build(BuildContext context) =>
      _home ?? const Scaffold(body: Center(child: CircularProgressIndicator()));
}
