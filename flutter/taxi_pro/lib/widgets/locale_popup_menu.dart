import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

/// Same eight languages as the home screen — drives global [appLocale].
/// [uiRole] should be an [AppUiRole] constant so each flow keeps its own language.
/// When [authToken] is set, updates `preferred_language` on the server (user/driver only).
class LocalePopupMenuButton extends StatelessWidget {
  const LocalePopupMenuButton({super.key, this.authToken, this.uiRole});

  /// Bearer token for `/api/me` when logged in; otherwise only [appLocale] updates.
  final String? authToken;

  /// See [AppUiRole]; omit on generic hubs if desired.
  final String? uiRole;

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

  static const _labels = <String>[
    'العربية',
    'English',
    'Français',
    'Deutsch',
    '中文',
    'Italiano',
    'Español',
    'Русский',
  ];

  Future<void> _onSelected(Locale loc) async {
    setAppLocaleForUiRole(uiRole, loc);
    final t = (authToken ?? '').trim();
    if (t.isEmpty) return;
    try {
      await TaxiAppService()
          .patchPreferredLanguage(token: t, preferredLanguage: loc.languageCode);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: l.language,
      onSelected: _onSelected,
      itemBuilder: (context) => List<PopupMenuEntry<Locale>>.generate(
        _locales.length,
        (i) => PopupMenuItem(
          value: _locales[i],
          child: Text(_labels[i]),
        ),
      ),
    );
  }
}
