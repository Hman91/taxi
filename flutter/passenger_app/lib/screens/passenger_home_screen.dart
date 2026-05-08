import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';
import 'app_passenger_screen.dart';

String _voomTagline(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  if (code.startsWith('ar')) {
    return 'رحلات سريعة وتوزيع ذكي ودردشة سهلة في تطبيق واحد.';
  }
  if (code.startsWith('fr')) {
    return 'Courses rapides, repartition intelligente et chat facile dans une seule app.';
  }
  if (code.startsWith('es')) {
    return 'Viajes rapidos, despacho inteligente y chat facil en una sola app.';
  }
  if (code.startsWith('de')) {
    return 'Schnelle Fahrten, smarte Disposition und einfacher Chat in einer App.';
  }
  if (code.startsWith('it')) {
    return 'Corse veloci, dispatch intelligente e chat facile in un unica app.';
  }
  if (code.startsWith('ru')) {
    return 'Быстрые поездки, умная диспетчеризация и удобный чат в одном приложении.';
  }
  if (code.startsWith('zh')) {
    return '一个应用实现快速叫车、智能调度和便捷聊天。';
  }
  return 'Fast rides, smart dispatch, and easy chat in one app.';
}

Future<void> navigateFromPassengerHome(BuildContext context) async {
  final s = await SessionStore.load();
  if (!context.mounted) return;
  final AppLoginResponse? session =
      s?.role == PersistedRole.appPassenger ? s?.appLogin : null;

  if (!context.mounted) return;
  if (session != null && session.accessToken.trim().isNotEmpty) {
    final sess = session;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AppPassengerScreen(initialSession: sess),
      ),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AppPassengerScreen()),
  );
}

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC200),
        foregroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        title: const Text(
          'Voom',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: const [LocalePopupMenuButton(uiRole: AppUiRole.passenger)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VoomLogo(height: 100),
              const SizedBox(height: 16),
              Text(
                _voomTagline(context),
                style: const TextStyle(
                  color: Color(0xFF5C5C5C),
                  fontSize: 13,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => navigateFromPassengerHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC200),
                    foregroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    l.signInApp,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
