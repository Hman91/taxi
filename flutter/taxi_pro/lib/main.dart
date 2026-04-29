import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_locale.dart';
import 'l10n/app_localizations.dart';
import 'screens/unified_login_screen.dart';
import 'services/local_notification_service.dart';
import 'theme/taxi_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: const UnifiedLoginScreen(),
        );
      },
    );
  }
}
