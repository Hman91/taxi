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
  static const accent = Color(0xFF28D7E5);
}

class PassengerForgotPasswordScreen extends StatefulWidget {
  const PassengerForgotPasswordScreen({super.key});

  @override
  State<PassengerForgotPasswordScreen> createState() =>
      _PassengerForgotPasswordScreenState();
}

class _PassengerForgotPasswordScreenState
    extends State<PassengerForgotPasswordScreen> {
  final TaxiAppService _api = TaxiAppService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _requested = false;
  bool _obscureNewPassword = true;

  String _t({
    required String en,
    String? ar,
    String? fr,
    String? de,
    String? es,
    String? it,
    String? ru,
    String? zh,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (code) {
      case 'ar':
        return ar ?? en;
      case 'fr':
        return fr ?? en;
      case 'de':
        return de ?? en;
      case 'es':
        return es ?? en;
      case 'it':
        return it ?? en;
      case 'ru':
        return ru ?? en;
      case 'zh':
        return zh ?? en;
      default:
        return en;
    }
  }

  InputDecoration _fd(String label, {IconData? icon, Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _C.accent, fontWeight: FontWeight.w700),
        prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _C.surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _C.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _C.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

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
      final emailSent = await _api.requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() {
        _requested = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailSent
                ? _t(
                    en: 'Reset code sent to your email.',
                    ar: 'تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني.',
                    fr: 'Le code de réinitialisation a été envoyé à votre e-mail.',
                    de: 'Der Zurücksetzungscode wurde an Ihre E-Mail gesendet.',
                    es: 'El código de restablecimiento fue enviado a tu correo.',
                    it: 'Il codice di reimpostazione è stato inviato alla tua email.',
                    ru: 'Код сброса отправлен на вашу электронную почту.',
                    zh: '重置验证码已发送到您的邮箱。',
                  )
                : _t(
                    en: 'Reset email could not be sent. Check SMTP settings.',
                    ar: 'تعذّر إرسال رسالة إعادة التعيين. تحقق من إعدادات SMTP.',
                    fr: 'Impossible d’envoyer l’e-mail de réinitialisation. Vérifiez les paramètres SMTP.',
                    de: 'Die Reset-E-Mail konnte nicht gesendet werden. Prüfen Sie die SMTP-Einstellungen.',
                    es: 'No se pudo enviar el correo de restablecimiento. Revisa la configuración SMTP.',
                    it: 'Impossibile inviare l’email di reimpostazione. Controlla le impostazioni SMTP.',
                    ru: 'Не удалось отправить письмо для сброса. Проверьте настройки SMTP.',
                    zh: '无法发送重置邮件。请检查 SMTP 设置。',
                  ),
          ),
        ),
      );
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
        SnackBar(
          content: Text(
            _t(
              en: 'Password updated. Please sign in.',
              ar: 'تم تحديث كلمة المرور. يرجى تسجيل الدخول.',
              fr: 'Mot de passe mis à jour. Veuillez vous connecter.',
              de: 'Passwort aktualisiert. Bitte melden Sie sich an.',
              es: 'Contraseña actualizada. Inicia sesión, por favor.',
              it: 'Password aggiornata. Accedi di nuovo.',
              ru: 'Пароль обновлён. Пожалуйста, войдите.',
              zh: '密码已更新。请登录。',
            ),
          ),
        ),
      );
      Navigator.of(context).pop();
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
        centerTitle: true,
        title: const Text(
          'Voom',
          style: TextStyle(
            color: _C.charcoal,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: _C.charcoal),
        actions: const [LocalePopupMenuButton(uiRole: AppUiRole.passenger)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: VoomLogo(height: 90)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    en: 'Reset your passenger password',
                    ar: 'إعادة تعيين كلمة مرور الراكب',
                    fr: 'Réinitialisez votre mot de passe passager',
                    de: 'Setzen Sie Ihr Fahrgast-Passwort zurück',
                    es: 'Restablece tu contraseña de pasajero',
                    it: 'Reimposta la password passeggero',
                    ru: 'Сбросьте пароль пассажира',
                    zh: '重置乘客密码',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd(
                    _t(
                      en: 'E-mail',
                      ar: 'البريد الإلكتروني',
                      fr: 'E-mail',
                      de: 'E-Mail',
                      es: 'Correo electrónico',
                      it: 'E-mail',
                      ru: 'Эл. почта',
                      zh: '电子邮箱',
                    ),
                    icon: Icons.alternate_email_rounded,
                  ),
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
                      _t(
                        en: 'Send reset code',
                        ar: 'إرسال رمز إعادة التعيين',
                        fr: 'Envoyer le code',
                        de: 'Reset-Code senden',
                        es: 'Enviar código de restablecimiento',
                        it: 'Invia codice di reimpostazione',
                        ru: 'Отправить код сброса',
                        zh: '发送重置验证码',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_requested) ...[
            const SizedBox(height: 18),
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
                    decoration: _fd(
                      _t(
                        en: 'Reset code',
                        ar: 'رمز إعادة التعيين',
                        fr: 'Code de réinitialisation',
                        de: 'Reset-Code',
                        es: 'Código de restablecimiento',
                        it: 'Codice di reimpostazione',
                        ru: 'Код сброса',
                        zh: '重置验证码',
                      ),
                      icon: Icons.vpn_key_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscureNewPassword,
                    decoration: _fd(
                      _t(
                        en: 'New password',
                        ar: 'كلمة المرور الجديدة',
                        fr: 'Nouveau mot de passe',
                        de: 'Neues Passwort',
                        es: 'Nueva contraseña',
                        it: 'Nuova password',
                        ru: 'Новый пароль',
                        zh: '新密码',
                      ),
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                        _t(
                          en: 'Update password',
                          ar: 'تحديث كلمة المرور',
                          fr: 'Mettre à jour le mot de passe',
                          de: 'Passwort aktualisieren',
                          es: 'Actualizar contraseña',
                          it: 'Aggiorna password',
                          ru: 'Обновить пароль',
                          zh: '更新密码',
                        ),
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
