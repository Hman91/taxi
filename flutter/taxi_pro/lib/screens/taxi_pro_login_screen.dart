import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../app_locale.dart';
import '../config.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';
import 'app_passenger_screen.dart';
import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';
import 'taxi_pro_forgot_password_screen.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const bgWarm = Color(0xFFF8F5EC);
  static const charcoal = Color(0xFF1A1A1A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFE6E6E6);
}

class TaxiProLoginScreen extends StatefulWidget {
  const TaxiProLoginScreen({super.key});

  @override
  State<TaxiProLoginScreen> createState() => _TaxiProLoginScreenState();
}

class _TaxiProLoginScreenState extends State<TaxiProLoginScreen> {
  final TaxiAppService _api = TaxiAppService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _message;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: googleOAuthWebClientId,
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fd(String label, {IconData? icon, Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _C.surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _C.border, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _C.yellow, width: 2),
        ),
      );

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

  Future<void> _go(Widget screen) async {
    if (!mounted) return;
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _goByRole(AppLoginResponse r) async {
    if (r.role == 'owner') {
      await SessionStore.saveOwnerToken(
        r.accessToken,
        refreshToken: r.refreshToken,
      );
      await _go(OwnerScreen(initialToken: r.accessToken));
      return;
    }
    if (r.role == 'operator') {
      await SessionStore.saveOperatorToken(
        r.accessToken,
        refreshToken: r.refreshToken,
      );
      await _go(OperatorScreen(initialToken: r.accessToken));
      return;
    }
    if (r.role == 'driver') {
      await SessionStore.saveAppDriver(r);
      await _go(DriverScreen(appInitialSession: r));
      return;
    }
    if (r.role == 'user') {
      await SessionStore.saveAppPassenger(r);
      await _go(AppPassengerScreen(initialSession: r));
      return;
    }
    if (r.role == 'b2b') {
      final b2b = LoginResponse(
        accessToken: r.accessToken,
        role: 'b2b',
        appAccessToken: r.accessToken,
        userId: r.userId,
      );
      await SessionStore.saveB2b(b2b);
      await _go(B2bScreen(initialSession: b2b));
      return;
    }
    throw TaxiApiException('invalid_role', 400);
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await fn();
    } on TaxiAccountDisabledException {
      setState(() => _message = _uiText(en: 'Account disabled. Contact owner/operator.', ar: 'الحساب معطل. اتصل بالمالك/المشغل.', fr: 'Compte desactive. Contactez le proprietaire/operateur.', es: 'Cuenta deshabilitada. Contacta al propietario/operador.', de: 'Konto deaktiviert. Kontaktieren Sie Eigentümer/Operator.', it: 'Account disabilitato. Contatta proprietario/operatore.', ru: 'Аккаунт отключен. Свяжитесь с владельцем/оператором.', zh: '账号已禁用，请联系所有者/运营员。'));
    } on TaxiAccountPendingException {
      setState(() => _message = _uiText(en: 'Account pending approval by owner/operator.', ar: 'الحساب بانتظار موافقة المالك/المشغل.', fr: 'Compte en attente de validation par proprietaire/operateur.', es: 'Cuenta pendiente de aprobacion por propietario/operador.', de: 'Konto wartet auf Genehmigung durch Eigentümer/Operator.', it: 'Account in attesa di approvazione da proprietario/operatore.', ru: 'Аккаунт ожидает одобрения владельца/оператора.', zh: '账号等待所有者/运营员批准。'));
    } on TaxiApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginEmail() async {
    final response = await _api.loginApp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    await _goByRole(response);
  }

  Future<void> _loginGoogle() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw TaxiApiException('missing_google_token', 400);
    }
    final response = await _api.loginGoogle(
      idToken: (idToken != null && idToken.isNotEmpty) ? idToken : null,
      accessToken: (accessToken != null && accessToken.isNotEmpty)
          ? accessToken
          : null,
    );
    await _goByRole(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.yellow,
        foregroundColor: _C.charcoal,
        centerTitle: true,
        title: Text(
          _uiText(en: 'Login', ar: 'تسجيل الدخول', fr: 'Connexion', es: 'Iniciar sesion', de: 'Anmelden', it: 'Accesso', ru: 'Вход', zh: '登录'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: _C.charcoal),
        ),
        actions: const [LocalePopupMenuButton(uiRole: AppUiRole.home)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const VoomLogo(height: 90),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd(_uiText(en: 'Email', ar: 'البريد الإلكتروني', fr: 'Email', es: 'Correo', de: 'E-Mail', it: 'Email', ru: 'Email', zh: '邮箱'), icon: Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: _fd(
                    _uiText(en: 'Password', ar: 'كلمة المرور', fr: 'Mot de passe', es: 'Contrasena', de: 'Passwort', it: 'Password', ru: 'Пароль', zh: '密码'),
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _C.charcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _run(_loginEmail),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.yellow,
                      foregroundColor: _C.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    label: Text(
                      _uiText(en: 'Sign In', ar: 'دخول', fr: 'Se connecter', es: 'Entrar', de: 'Anmelden', it: 'Accedi', ru: 'Войти', zh: '登录'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(_loginGoogle),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: Text(_uiText(en: 'Sign In with Google', ar: 'تسجيل الدخول عبر Google', fr: 'Se connecter avec Google', es: 'Entrar con Google', de: 'Mit Google anmelden', it: 'Accedi con Google', ru: 'Войти через Google', zh: '使用 Google 登录')),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TaxiProForgotPasswordScreen(),
                              ),
                            ),
                    child: Text(_uiText(en: 'Forgot password?', ar: 'نسيت كلمة المرور؟', fr: 'Mot de passe oublie ?', es: 'Olvidaste la contrasena?', de: 'Passwort vergessen?', it: 'Password dimenticata?', ru: 'Забыли пароль?', zh: '忘记密码？')),
                  ),
                ),
                if ((_message ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
