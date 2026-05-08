import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api/models.dart';
import 'app_locale.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_passenger_screen.dart';
import 'screens/passenger_home_screen.dart';
import 'services/local_notification_service.dart';
import 'services/session_store.dart';
import 'theme/taxi_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.init();
  runApp(const PassengerApp());
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

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final s = await SessionStore.load();
    if (!mounted) return;
    setState(() {
      _home = _screenFromSession(s) ?? const PassengerHomeScreen();
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
