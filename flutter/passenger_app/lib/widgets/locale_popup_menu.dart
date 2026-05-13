import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

/// Same eight languages as the home screen — drives global [appLocale].
/// [uiRole] should be an [AppUiRole] constant so each flow keeps its own language.
/// When [authToken] is set, updates `preferred_language` on the server (user/driver only).
class LocalePopupMenuButton extends StatelessWidget {
  const LocalePopupMenuButton({
    super.key,
    this.authToken,
    this.uiRole,
    this.foregroundColor,
  });

  /// Bearer token for `/api/me` when logged in; otherwise only [appLocale] updates.
  final String? authToken;

  /// See [AppUiRole]; omit on generic hubs if desired.
  final String? uiRole;

  /// Overrides the icon and label color when an AppBar needs a custom accent.
  final Color? foregroundColor;

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
    await savePreferredLanguageForUiRole(uiRole, loc);
    final t = (authToken ?? '').trim();
    if (t.isEmpty) return;
    try {
      await TaxiAppService().patchPreferredLanguage(
          token: t, preferredLanguage: loc.languageCode);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final actionColor = foregroundColor ?? IconTheme.of(context).color;
    return PopupMenuButton<Locale>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: actionColor, size: 18),
            const SizedBox(width: 4),
            Text(
              l.language,
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
