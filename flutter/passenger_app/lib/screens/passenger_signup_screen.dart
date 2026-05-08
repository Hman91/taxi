import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/client.dart';
import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../utils/int_from_json.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';
import 'app_passenger_screen.dart';

class PassengerSignupScreen extends StatefulWidget {
  const PassengerSignupScreen({super.key});

  @override
  State<PassengerSignupScreen> createState() => _PassengerSignupScreenState();
}

class _PassengerSignupScreenState extends State<PassengerSignupScreen> {
  final _api = TaxiAppService();
  final _picker = ImagePicker();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _photo = '';
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = base64Encode(bytes));
  }

  Future<void> _signup() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      await _api.registerAppUser(
        email: email,
        password: password,
        role: 'user',
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        photoUrl: _photo.isEmpty ? null : _photo,
      );
      final session = await _api.loginApp(email: email, password: password);
      await SessionStore.saveAppPassenger(session);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AppPassengerScreen(initialSession: session),
        ),
        (_) => false,
      );
    } on TaxiApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC200),
        foregroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        title: const VoomLogo(height: 40),
        actions: const [LocalePopupMenuButton(uiRole: 'passenger')],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const VoomLogo(height: 90),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: 'Passenger name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(labelText: l.emailLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l.operatorPhoneLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.passwordLabel,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l.operatorPickFromGallery),
          ),
          if (_photo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Image selected (${intFromDynamic(_photo.length) ?? _photo.length} chars)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          if ((_error ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : _signup,
            icon: const Icon(Icons.person_add_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC200),
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            label: Text(
              l.registerAppAccount,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
