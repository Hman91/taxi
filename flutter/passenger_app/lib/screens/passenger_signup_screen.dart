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

  InputDecoration _fd(String label, {IconData? icon, Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF1A1A1A), size: 18)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F1E8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDD8C8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFFC200), width: 2),
        ),
      );

  String _t(String key, [Object? value]) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    const table = <String, Map<String, String>>{
      'passengerName': {
        'en': 'Passenger name',
        'fr': 'Nom du passager',
        'ar': 'اسم الراكب',
        'de': 'Name des Fahrgasts',
        'es': 'Nombre del pasajero',
        'it': 'Nome passeggero',
        'zh': '乘客姓名',
        'ru': 'Имя пассажира',
      },
      'imageSelected': {
        'en': 'Image selected ({value} chars)',
        'fr': 'Image sélectionnée ({value} caractères)',
        'ar': 'تم اختيار الصورة ({value} حرفاً)',
        'de': 'Bild ausgewählt ({value} Zeichen)',
        'es': 'Imagen seleccionada ({value} caracteres)',
        'it': 'Immagine selezionata ({value} caratteri)',
        'zh': '已选择图片（{value} 个字符）',
        'ru': 'Изображение выбрано ({value} символов)',
      },
    };
    return (table[key]?[code] ?? table[key]?['en'] ?? key)
        .replaceAll('{value}', '${value ?? ''}');
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
        title: const Text(
          'Voom',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: const [LocalePopupMenuButton(uiRole: 'passenger')],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const VoomLogo(height: 90),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: _fd(_t('passengerName'), icon: Icons.badge_outlined),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _fd(l.emailLabel, icon: Icons.alternate_email_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _fd(l.operatorPhoneLabel, icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: _fd(
              l.passwordLabel,
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l.operatorPickFromGallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFFE6A800), width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          if (_photo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _t('imageSelected',
                  intFromDynamic(_photo.length) ?? _photo.length),
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
