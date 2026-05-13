import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/client.dart';
import '../app_locale.dart';
import '../config.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const bgWarm = Color(0xFFF8F5EC);
  static const charcoal = Color(0xFF1A1A1A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFE6E6E6);
}

class TaxiProSignupScreen extends StatefulWidget {
  const TaxiProSignupScreen({super.key});

  @override
  State<TaxiProSignupScreen> createState() => _TaxiProSignupScreenState();
}

class _TaxiProSignupScreenState extends State<TaxiProSignupScreen> {
  final TaxiAppService _api = TaxiAppService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _carTypeCtrl = TextEditingController();
  final TextEditingController _carColorCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String _role = 'driver';
  String? _message;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: googleOAuthWebClientId,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _carTypeCtrl.dispose();
    _carColorCtrl.dispose();
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

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await fn();
    } on TaxiApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signupEmail() async {
    await _api.registerAppUser(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
      displayName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      carModel: _role == 'driver' ? _carTypeCtrl.text.trim() : null,
      carColor: _role == 'driver' ? _carColorCtrl.text.trim() : null,
    );
    setState(() => _message = _uiText(en: 'Account created. Awaiting approval.', ar: 'تم إنشاء الحساب. بانتظار الموافقة.', fr: 'Compte cree. En attente de validation.', es: 'Cuenta creada. En espera de aprobacion.', de: 'Konto erstellt. Warten auf Genehmigung.', it: 'Account creato. In attesa di approvazione.', ru: 'Аккаунт создан. Ожидает одобрения.', zh: '账号已创建，等待审核。'));
  }

  Future<void> _signupGoogle() async {
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
    await _api.loginGoogle(
      idToken: (idToken != null && idToken.isNotEmpty) ? idToken : null,
      accessToken: (accessToken != null && accessToken.isNotEmpty)
          ? accessToken
          : null,
      role: _role,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    setState(
      () => _message = _uiText(en: 'Google account received. Awaiting owner/operator approval.', ar: 'تم استلام حساب Google. بانتظار موافقة المالك/المشغل.', fr: 'Compte Google recu. En attente de validation proprietaire/operateur.', es: 'Cuenta Google recibida. En espera de aprobacion del propietario/operador.', de: 'Google-Konto empfangen. Warten auf Genehmigung durch Eigentümer/Operator.', it: 'Account Google ricevuto. In attesa approvazione proprietario/operatore.', ru: 'Google-аккаунт получен. Ожидание одобрения владельца/оператора.', zh: '已接收 Google 账户，等待所有者/运营员批准。'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = _role == 'driver';
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.yellow,
        foregroundColor: _C.charcoal,
        centerTitle: true,
        title: const Text(
          'Voom',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _C.charcoal,
            fontSize: 20,
          ),
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
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _fd(_uiText(en: 'Role', ar: 'الدور', fr: 'Role', es: 'Rol', de: 'Rolle', it: 'Ruolo', ru: 'Роль', zh: '角色'), icon: Icons.person_outline_rounded),
                  items: [
                    DropdownMenuItem(value: 'driver', child: Text(_uiText(en: 'Driver', ar: 'سائق', fr: 'Chauffeur', es: 'Conductor', de: 'Fahrer', it: 'Autista', ru: 'Водитель', zh: '司机'))),
                    DropdownMenuItem(value: 'b2b', child: Text(_uiText(en: 'B2B', ar: 'شركات', fr: 'B2B', es: 'B2B', de: 'B2B', it: 'B2B', ru: 'B2B', zh: 'B2B'))),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  decoration: _fd(_uiText(en: 'Name', ar: 'الاسم', fr: 'Nom', es: 'Nombre', de: 'Name', it: 'Nome', ru: 'Имя', zh: '姓名'), icon: Icons.badge_outlined),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd(_uiText(en: 'Email', ar: 'البريد الإلكتروني', fr: 'Email', es: 'Correo', de: 'E-Mail', it: 'Email', ru: 'Email', zh: '邮箱'), icon: Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fd(_uiText(en: 'Phone', ar: 'الهاتف', fr: 'Telephone', es: 'Telefono', de: 'Telefon', it: 'Telefono', ru: 'Телефон', zh: '电话'), icon: Icons.phone_outlined),
                ),
                if (isDriver) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _carTypeCtrl,
                    decoration:
                        _fd(_uiText(en: 'Car type', ar: 'نوع السيارة', fr: 'Type de voiture', es: 'Tipo de coche', de: 'Autotyp', it: 'Tipo auto', ru: 'Тип авто', zh: '车型'), icon: Icons.directions_car_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _carColorCtrl,
                    decoration: _fd(_uiText(en: 'Car color', ar: 'لون السيارة', fr: 'Couleur de voiture', es: 'Color del coche', de: 'Autofarbe', it: 'Colore auto', ru: 'Цвет авто', zh: '车颜色'), icon: Icons.palette_outlined),
                  ),
                ],
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
                    onPressed: _busy ? null : () => _run(_signupEmail),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.yellow,
                      foregroundColor: _C.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    label: Text(
                      _uiText(en: 'Create (pending approval)', ar: 'إنشاء (بانتظار الموافقة)', fr: 'Creer (en attente)', es: 'Crear (pendiente de aprobacion)', de: 'Erstellen (wartet auf Genehmigung)', it: 'Crea (in attesa approvazione)', ru: 'Создать (ожидает одобрения)', zh: '创建（待审核）'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(_signupGoogle),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: Text(_uiText(en: 'Register with Google', ar: 'التسجيل عبر Google', fr: 'S inscrire avec Google', es: 'Registrarse con Google', de: 'Mit Google registrieren', it: 'Registrati con Google', ru: 'Регистрация через Google', zh: '使用 Google 注册')),
                  ),
                ),
                if ((_message ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _message!,
                      style: const TextStyle(
                        color: Color(0xFF3F3F3F),
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
