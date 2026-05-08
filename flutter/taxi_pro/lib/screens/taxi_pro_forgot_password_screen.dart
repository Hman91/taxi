import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../api/client.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const bgWarm = Color(0xFFFFF8E0);
  static const charcoal = Color(0xFF1A1A1A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFE6E6E6);
}

class TaxiProForgotPasswordScreen extends StatefulWidget {
  const TaxiProForgotPasswordScreen({super.key});

  @override
  State<TaxiProForgotPasswordScreen> createState() =>
      _TaxiProForgotPasswordScreenState();
}

class _TaxiProForgotPasswordScreenState
    extends State<TaxiProForgotPasswordScreen> {
  final TaxiAppService _api = TaxiAppService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _requested = false;
  bool _obscure = true;

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _api.requestPasswordReset(email: email);
      setState(() => _requested = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_uiText(en: 'Reset code sent to your email.', ar: 'تم إرسال رمز إعادة التعيين إلى بريدك.', fr: 'Code de reinitialisation envoye a votre email.', es: 'Codigo de restablecimiento enviado a tu correo.', de: 'Zuruecksetzungscode wurde an Ihre E-Mail gesendet.', it: 'Codice di ripristino inviato alla tua email.', ru: 'Код сброса отправлен на вашу почту.', zh: '重置验证码已发送到你的邮箱。'))),
      );
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || code.isEmpty || password.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _api.confirmPasswordReset(
        email: email,
        resetCode: code,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_uiText(en: 'Password updated. Please sign in.', ar: 'تم تحديث كلمة المرور. يرجى تسجيل الدخول.', fr: 'Mot de passe mis a jour. Veuillez vous connecter.', es: 'Contrasena actualizada. Inicia sesion.', de: 'Passwort aktualisiert. Bitte anmelden.', it: 'Password aggiornata. Effettua l accesso.', ru: 'Пароль обновлен. Пожалуйста, войдите.', zh: '密码已更新，请登录。'))),
      );
      Navigator.of(context).pop();
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          _uiText(en: 'Forgot Password', ar: 'نسيت كلمة المرور', fr: 'Mot de passe oublie', es: 'Olvide mi contrasena', de: 'Passwort vergessen', it: 'Password dimenticata', ru: 'Забыли пароль', zh: '忘记密码'),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _requestCode,
                    icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.yellow,
                      foregroundColor: _C.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    label: Text(
                      _uiText(en: 'Send reset code', ar: 'إرسال رمز التعيين', fr: 'Envoyer le code', es: 'Enviar codigo', de: 'Code senden', it: 'Invia codice', ru: 'Отправить код', zh: '发送重置码'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_requested) ...[
            const SizedBox(height: 16),
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
                    controller: _codeCtrl,
                    decoration: _fd(_uiText(en: 'Reset code', ar: 'رمز التعيين', fr: 'Code de reinitialisation', es: 'Codigo de restablecimiento', de: 'Reset-Code', it: 'Codice reset', ru: 'Код сброса', zh: '重置码'), icon: Icons.vpn_key_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: _fd(
                      _uiText(en: 'New password', ar: 'كلمة مرور جديدة', fr: 'Nouveau mot de passe', es: 'Nueva contrasena', de: 'Neues Passwort', it: 'Nuova password', ru: 'Новый пароль', zh: '新密码'),
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
                      onPressed: _busy ? null : _confirmReset,
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.yellow,
                        foregroundColor: _C.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      label: Text(
                        _uiText(en: 'Update password', ar: 'تحديث كلمة المرور', fr: 'Mettre a jour le mot de passe', es: 'Actualizar contrasena', de: 'Passwort aktualisieren', it: 'Aggiorna password', ru: 'Обновить пароль', zh: '更新密码'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
