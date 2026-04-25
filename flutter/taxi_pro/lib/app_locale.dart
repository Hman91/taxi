import 'package:flutter/material.dart';

/// Keys for per-role UI language (in-memory for this app session).
abstract final class AppUiRole {
  AppUiRole._();

  static const home = 'home';
  static const passenger = 'passenger';
  static const driver = 'driver';
  static const owner = 'owner';
  static const operator = 'operator';
  static const b2b = 'b2b';
}

/// Single app-wide UI locale (must match [MaterialApp.locale]).
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

/// True after the user picks a language from [LocalePopupMenuButton] this session.
/// Passenger/driver login then keeps [appLocale] and syncs to the server instead of overwriting.
final ValueNotifier<bool> userChoseLocaleThisSession = ValueNotifier(false);

final Map<String, String> _localeByUiRole = <String, String>{};

/// Called when opening a role screen — applies the last language chosen for that flow
/// or records the current [appLocale] the first time.
void restoreUiRoleLocale(String role) {
  final saved = _localeByUiRole[role];
  if (saved != null && saved.isNotEmpty) {
    appLocale.value = localeFromPreferredLanguage(saved);
    return;
  }
  _localeByUiRole[role] = appLocale.value.languageCode;
}

/// Saves the current UI language for [role] (e.g. before leaving Home, or after login).
void rememberCurrentLocaleForRole(String role) {
  _localeByUiRole[role] = appLocale.value.languageCode;
}

void setAppLocaleForUiRole(String? role, Locale loc) {
  appLocale.value = loc;
  userChoseLocaleThisSession.value = true;
  if (role != null && role.isNotEmpty) {
    _localeByUiRole[role] = loc.languageCode;
  }
}

/// Maps backend `users.preferred_language` (ISO-style code) to a [Locale].
Locale localeFromPreferredLanguage(String? code) {
  final c = (code ?? 'en').trim().toLowerCase();
  const codes = <String>{
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ru',
    'zh',
  };
  if (codes.contains(c)) {
    return Locale(c);
  }
  return const Locale('en');
}

void applyPreferredLanguageToApp(String? code) {
  appLocale.value = localeFromPreferredLanguage(code);
}
