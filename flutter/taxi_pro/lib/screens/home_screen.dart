import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../widgets/locale_popup_menu.dart';
import 'app_passenger_screen.dart';
import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';

/// 8 UI languages: AR, EN, FR, DE, ZH, IT, ES, RU
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _pushRole(BuildContext context, Widget page) async {
    rememberCurrentLocaleForRole(AppUiRole.home);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (!context.mounted) return;
    restoreUiRoleLocale(AppUiRole.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: const [
          LocalePopupMenuButton(uiRole: AppUiRole.home),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.homeWhatIsTitle),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SelectableText(l.homeWhatIsBody),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            l.loginAs,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _tile(
              context, l.rolePassenger, Icons.person, const AppPassengerScreen()),
          _tile(context, l.roleDriver, Icons.local_taxi, const DriverScreen()),
          _tile(
              context, l.roleOwner, Icons.business_center, const OwnerScreen()),
          _tile(context, l.roleOperator, Icons.headset_mic,
              const OperatorScreen()),
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
        onTap: () => _pushRole(context, page),
      ),
    );
  }
}
