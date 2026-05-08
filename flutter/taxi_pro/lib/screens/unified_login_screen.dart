import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../services/session_store.dart';
import '../widgets/voom_logo.dart';
import '../widgets/locale_popup_menu.dart';
import 'app_passenger_screen.dart';
import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';
import 'taxi_pro_forgot_password_screen.dart';
import 'taxi_pro_login_screen.dart';
import 'taxi_pro_signup_screen.dart';
class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key, this.showPassengerEntry = false});
  final bool showPassengerEntry;
  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  String _uiText({
    required String en,
    required String ar,
    required String fr,
    required String es,
    required String de,
    required String it,
    required String ru,
    required String zh,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('fr')) return fr;
    if (code.startsWith('es')) return es;
    if (code.startsWith('de')) return de;
    if (code.startsWith('it')) return it;
    if (code.startsWith('ru')) return ru;
    if (code.startsWith('zh')) return zh;
    return en;
  }

  Future<void> _onLoginPressed() async {
    final s = await SessionStore.load();
    if (!mounted) return;
    Widget? target;
    if (s != null) {
      switch (s.role) {
        case PersistedRole.appPassenger:
          final r = s.appLogin;
          target = r == null ? null : AppPassengerScreen(initialSession: r);
          break;
        case PersistedRole.appDriver:
          final r = s.appLogin;
          target = r == null ? null : DriverScreen(appInitialSession: r);
          break;
        case PersistedRole.driverPin:
          final r = s.driverPinLogin;
          target = r == null ? null : DriverScreen(initialSession: r);
          break;
        case PersistedRole.owner:
          final t = s.token;
          target = (t == null || t.isEmpty) ? null : OwnerScreen(initialToken: t);
          break;
        case PersistedRole.operator:
          final t = s.token;
          target = (t == null || t.isEmpty) ? null : OperatorScreen(initialToken: t);
          break;
        case PersistedRole.b2b:
          final r = s.login;
          target = r == null ? null : B2bScreen(initialSession: r);
          break;
      }
    }
    if (target != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => target!));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaxiProLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC200),
        centerTitle: true,
        title: Text(
          _uiText(en: 'Voom', ar: 'فوم', fr: 'Voom', es: 'Voom', de: 'Voom', it: 'Voom', ru: 'Voom', zh: 'Voom'),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: const [LocalePopupMenuButton(uiRole: AppUiRole.home)],
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
                _uiText(
                  en: 'Fast rides, smart dispatch, and easy chat in one app.',
                  ar: 'رحلات سريعة وتوزيع ذكي ودردشة سهلة في تطبيق واحد.',
                  fr: 'Courses rapides, repartition intelligente et chat facile dans une seule app.',
                  es: 'Viajes rapidos, despacho inteligente y chat facil en una sola app.',
                  de: 'Schnelle Fahrten, smarte Disposition und einfacher Chat in einer App.',
                  it: 'Corse veloci, dispatch intelligente e chat facile in un unica app.',
                  ru: 'Быстрые поездки, умная диспетчеризация и удобный чат в одном приложении.',
                  zh: '一个应用实现快速叫车、智能调度和便捷聊天。',
                ),
                style: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onLoginPressed,
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
                    _uiText(en: 'Login', ar: 'دخول', fr: 'Connexion', es: 'Iniciar sesion', de: 'Anmelden', it: 'Accesso', ru: 'Вход', zh: '登录'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TaxiProSignupScreen()),
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text(_uiText(en: 'Sign up', ar: 'إنشاء حساب', fr: 'Inscription', es: 'Registrarse', de: 'Registrieren', it: 'Registrati', ru: 'Регистрация', zh: '注册')),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TaxiProForgotPasswordScreen(),
                  ),
                ),
                child: Text(_uiText(en: 'Forgot password?', ar: 'نسيت كلمة المرور؟', fr: 'Mot de passe oublie ?', es: 'Olvidaste la contrasena?', de: 'Passwort vergessen?', it: 'Password dimenticata?', ru: 'Забыли пароль?', zh: '忘记密码？')),
              ),
              if (widget.showPassengerEntry) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AppPassengerScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.airport_shuttle_rounded),
                  label: Text(_uiText(en: 'Passenger app', ar: 'تطبيق الراكب', fr: 'Application passager', es: 'App pasajero', de: 'Passagier-App', it: 'App passeggero', ru: 'Приложение пассажира', zh: '乘客应用')),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }
}