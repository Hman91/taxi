import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';
import 'passenger_screen.dart';

/// 8 UI languages: AR, EN, FR, DE, ZH, IT, ES, RU
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  static const _locales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
    Locale('it'),
    Locale('es'),
    Locale('ru'),
  ];

  static const _localeLabels = <String>[
    'العربية',
    'English',
    'Français',
    'Deutsch',
    '中文',
    'Italiano',
    'Español',
    'Русский',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: l.language,
            onSelected: onLocaleChanged,
            itemBuilder: (context) => List<PopupMenuEntry<Locale>>.generate(
              _locales.length,
              (i) => PopupMenuItem(
                value: _locales[i],
                child: Text(_localeLabels[i]),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.loginAs,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _tile(context, l.rolePassenger, Icons.person, const PassengerScreen()),
          _tile(context, l.roleDriver, Icons.local_taxi, const DriverScreen()),
          _tile(context, l.roleOwner, Icons.business_center, const OwnerScreen()),
          _tile(context, l.roleOperator, Icons.headset_mic, const OperatorScreen()),
          _tile(context, l.roleB2b, Icons.apartment, const B2bScreen()),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
        },
      ),
    );
  }
}
