import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_locale.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_passenger_screen.dart';
import 'screens/b2b_screen.dart';
import 'screens/driver_screen.dart';
import 'screens/operator_screen.dart';
import 'screens/owner_screen.dart';
import 'screens/unified_login_screen.dart';
import 'services/local_notification_service.dart';
import 'services/session_store.dart';
import 'theme/taxi_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.init();
  runApp(const TaxiProApp());
}

class TaxiProApp extends StatelessWidget {
  const TaxiProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Taxi Pro Tunisia',
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
          home: const _SessionGate(),
        );
      },
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
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
      _home = _screenFromSession(s) ?? const UnifiedLoginScreen(showPassengerEntry: false);
    });
  }

  Widget? _screenFromSession(PersistedSession? s) {
    if (s == null) return null;
    switch (s.role) {
      case PersistedRole.appPassenger:
        final r = s.appLogin;
        return r == null ? null : AppPassengerScreen(initialSession: r);
      case PersistedRole.appDriver:
        final r = s.appLogin;
        return r == null ? null : DriverScreen(appInitialSession: r);
      case PersistedRole.driverPin:
        final r = s.driverPinLogin;
        return r == null ? null : DriverScreen(initialSession: r);
      case PersistedRole.owner:
        final t = s.token;
        return (t == null || t.isEmpty) ? null : OwnerScreen(initialToken: t);
      case PersistedRole.operator:
        final t = s.token;
        return (t == null || t.isEmpty)
            ? null
            : OperatorScreen(initialToken: t);
      case PersistedRole.b2b:
        final r = s.login;
        return r == null ? null : B2bScreen(initialSession: r);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _home ?? const Scaffold(body: Center(child: CircularProgressIndicator()));
}
