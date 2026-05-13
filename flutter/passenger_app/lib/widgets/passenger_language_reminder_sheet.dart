import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

class PassengerLanguageOption {
  const PassengerLanguageOption({
    required this.locale,
    required this.nativeName,
    required this.icon,
  });

  final Locale locale;
  final String nativeName;
  final IconData icon;
}

const List<PassengerLanguageOption> passengerLanguageOptions =
    <PassengerLanguageOption>[
  PassengerLanguageOption(
    locale: Locale('en'),
    nativeName: 'English',
    icon: Icons.public_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('fr'),
    nativeName: 'Français',
    icon: Icons.travel_explore_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('ar'),
    nativeName: 'العربية',
    icon: Icons.auto_awesome_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('de'),
    nativeName: 'Deutsch',
    icon: Icons.map_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('es'),
    nativeName: 'Español',
    icon: Icons.language_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('it'),
    nativeName: 'Italiano',
    icon: Icons.route_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('zh'),
    nativeName: '中文',
    icon: Icons.hub_rounded,
  ),
  PassengerLanguageOption(
    locale: Locale('ru'),
    nativeName: 'Русский',
    icon: Icons.explore_rounded,
  ),
];

Future<void> showPassengerLanguageReminderSheet({
  required BuildContext context,
  String? authToken,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (context) => _PassengerLanguageReminderSheet(authToken: authToken),
  );
}

class _PassengerLanguageReminderSheet extends StatefulWidget {
  const _PassengerLanguageReminderSheet({this.authToken});

  final String? authToken;

  @override
  State<_PassengerLanguageReminderSheet> createState() =>
      _PassengerLanguageReminderSheetState();
}

class _PassengerLanguageReminderSheetState
    extends State<_PassengerLanguageReminderSheet> {
  late Locale _selectedLocale = appLocale.value;
  bool _saving = false;

  Future<void> _saveSelection() async {
    if (_saving) return;
    setState(() => _saving = true);
    await savePreferredLanguageForUiRole(AppUiRole.passenger, _selectedLocale);
    final token = (widget.authToken ?? '').trim();
    if (token.isNotEmpty) {
      try {
        await TaxiAppService().patchPreferredLanguage(
          token: token,
          preferredLanguage: _selectedLocale.languageCode,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F5EC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -46,
                top: -42,
                child: _GlowOrb(color: Color(0xFFFFC200), size: 160),
              ),
              Positioned(
                left: -38,
                bottom: 70,
                child: _GlowOrb(color: Color(0xFFFFD84D), size: 128),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD84D), Color(0xFFFFA800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFFFC200).withOpacity(0.34),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.translate_rounded,
                            color: Color(0xFF17120A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.passengerLanguageReminderTitle,
                                style: const TextStyle(
                                  color: Color(0xFF111111),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.passengerLanguageReminderSubtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5C5C5C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: passengerLanguageOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.24,
                      ),
                      itemBuilder: (context, index) {
                        final option = passengerLanguageOptions[index];
                        return _LanguageCard(
                          option: option,
                          languageName:
                              _localizedLanguageName(l, option.locale),
                          regionName:
                              _localizedLanguageRegion(l, option.locale),
                          selected: option.locale.languageCode ==
                              _selectedLocale.languageCode,
                          delay: Duration(milliseconds: 55 * index),
                          onTap: () =>
                              setState(() => _selectedLocale = option.locale),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _saving ? null : _saveSelection,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC200),
                          foregroundColor: const Color(0xFF17120A),
                          disabledBackgroundColor:
                              const Color(0xFFFFC200).withOpacity(0.48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _saving
                              ? const SizedBox(
                                  key: ValueKey<String>('saving'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF17120A),
                                  ),
                                )
                              : Text(
                                  l.passengerLanguageReminderContinue,
                                  key: const ValueKey<String>('confirm'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.languageName,
    required this.regionName,
    required this.selected,
    required this.delay,
    required this.onTap,
  });

  final PassengerLanguageOption option;
  final String languageName;
  final String regionName;
  final bool selected;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFF8E0)
                  : Colors.white.withOpacity(0.86),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFFC200)
                    : const Color(0xFFDDD8C8),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFC200).withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFC200)
                            : const Color(0xFFF5F1E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        option.icon,
                        color: selected
                            ? const Color(0xFF17120A)
                            : const Color(0xFF1E3A8A),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    AnimatedScale(
                      scale: selected ? 1 : 0.72,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? const Color(0xFFFFC200)
                            : const Color(0xFFDDD8C8),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  option.nativeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$languageName · $regionName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5C5C5C),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localizedLanguageName(AppLocalizations l, Locale locale) {
  return switch (locale.languageCode) {
    'ar' => l.passengerLanguageNameArabic,
    'de' => l.passengerLanguageNameGerman,
    'es' => l.passengerLanguageNameSpanish,
    'fr' => l.passengerLanguageNameFrench,
    'it' => l.passengerLanguageNameItalian,
    'ru' => l.passengerLanguageNameRussian,
    'zh' => l.passengerLanguageNameChinese,
    _ => l.passengerLanguageNameEnglish,
  };
}

String _localizedLanguageRegion(AppLocalizations l, Locale locale) {
  return switch (locale.languageCode) {
    'ar' => l.passengerLanguageRegionMena,
    'zh' => l.passengerLanguageRegionAsia,
    'de' || 'fr' || 'it' || 'ru' => l.passengerLanguageRegionEurope,
    _ => l.passengerLanguageRegionGlobal,
  };
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
