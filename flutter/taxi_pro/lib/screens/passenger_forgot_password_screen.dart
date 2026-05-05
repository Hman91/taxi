import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../api/client.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';

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
                ? 'Reset code sent to your email.'
                : 'Reset email could not be sent. Check SMTP settings.',
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
        const SnackBar(content: Text('Password updated. Please sign in.')),
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
          'Forgot Password',
          style: TextStyle(color: _C.charcoal, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: _C.charcoal),
        actions: const [LocalePopupMenuButton(uiRole: AppUiRole.passenger)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                const Text(
                  'Reset your passenger password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd('E-mail', icon: Icons.alternate_email_rounded),
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
                    label: const Text(
                      'Send reset code',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
                    decoration: _fd('Reset code', icon: Icons.vpn_key_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscureNewPassword,
                    decoration: _fd(
                      'New password',
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
                      label: const Text(
                        'Update password',
                        style: TextStyle(fontWeight: FontWeight.w800),
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
