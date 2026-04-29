// ═══════════════════════════════════════════════════════════════
// unified_login_screen.dart — TUNISIAN TAXI YELLOW THEME
// All original logic preserved — only UI/style changed
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import 'app_passenger_screen.dart';
import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';

// ── Design tokens ─────────────────────────────────────────────
class _C {
  static const yellow      = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft  = Color(0xFFFFF8E0);
  static const yellowDeep  = Color(0xFFE6A800);
  static const charcoal    = Color(0xFF1A1A1A);
  static const charcoalMid = Color(0xFF2C2C2C);
  static const bgWarm      = Color(0xFFFAF8F2);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF5F1E8);
  static const border      = Color(0xFFDDD8C8);
  static const textStrong  = Color(0xFF111111);
  static const textMid     = Color(0xFF3F3F3F);
  static const textSoft    = Color(0xFF5C5C5C);
  static const danger      = Color(0xFFB91C1C);
  static const dangerBg    = Color(0xFFFFE4E4);
}

// ── Shared widgets ────────────────────────────────────────────

// Yellow primary button
class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _C.yellow,
            borderRadius: BorderRadius.circular(50),
            boxShadow: disabled ? [] : [
              BoxShadow(color: _C.yellow.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: _C.charcoal, size: 18), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3)),
            ]),
          ),
        ),
      ),
    );
  }
}

// Charcoal dark button
class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed, this.icon, this.small = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.45 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: small ? 38 : 50,
          decoration: BoxDecoration(
            color: _C.charcoal,
            borderRadius: BorderRadius.circular(50),
            boxShadow: disabled ? [] : [BoxShadow(color: _C.charcoal.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: small ? 14 : 18), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 12 : 14, letterSpacing: 0.3)),
            ]),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
  prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
  filled: true,
  fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border, width: 1.5)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.yellow, width: 2)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Text(text.toUpperCase(), style: const TextStyle(color: _C.charcoal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  ]);
}

class _TaxiCard extends StatelessWidget {
  const _TaxiCard({required this.child, this.padding = 18, this.accent = false});
  final Widget child;
  final double padding;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
      boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});
  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  // ── Original fields (unchanged) ───────────────────────────
  final _api = TaxiAppService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _driverPinCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _message;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: googleOAuthWebClientId,
  );

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose(); _regNameCtrl.dispose();
    _regEmailCtrl.dispose(); _regPhoneCtrl.dispose(); _regPassCtrl.dispose();
    _driverPhoneCtrl.dispose(); _driverPinCtrl.dispose(); _codeCtrl.dispose();
    super.dispose();
  }

  // ── Original logic (all unchanged) ───────────────────────
  Future<void> _go(Widget screen) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<String?> _askPhone() async {
    String phone = '';
    return showDialog<String>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Phone required', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          autofocus: true, keyboardType: TextInputType.phone,
          onChanged: (v) => phone = v,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          decoration: _fd('Phone number', icon: Icons.phone_outlined),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
            onPressed: () => Navigator.of(ctx).pop(phone.trim()),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _loginPassengerEmail() async {
    final r = await _api.loginApp(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    await _go(AppPassengerScreen(initialSession: r));
  }

  Future<void> _loginPassengerGoogle() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    final idToken = auth.idToken; final accessToken = auth.accessToken;
    final hasIdToken = idToken != null && idToken.isNotEmpty;
    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    if (!hasIdToken && !hasAccessToken) throw TaxiApiException('missing_google_token', 400);
    AppLoginResponse r;
    try {
      r = await _api.loginGoogle(idToken: hasIdToken ? idToken : null, accessToken: hasAccessToken ? accessToken : null);
    } on TaxiApiException catch (e) {
      if (e.message != 'phone_required') rethrow;
      final phone = await _askPhone();
      if (phone == null || phone.trim().isEmpty) return;
      r = await _api.loginGoogle(idToken: hasIdToken ? idToken : null, accessToken: hasAccessToken ? accessToken : null, phone: phone.trim());
    }
    await _go(AppPassengerScreen(initialSession: r));
  }

  Future<void> _registerPassenger() async {
    await _api.registerAppUser(email: _regEmailCtrl.text.trim(), password: _regPassCtrl.text, role: 'user', displayName: _regNameCtrl.text.trim(), phone: _regPhoneCtrl.text.trim());
    final r = await _api.loginApp(email: _regEmailCtrl.text.trim(), password: _regPassCtrl.text);
    await _go(AppPassengerScreen(initialSession: r));
  }

  Future<void> _loginDriver() async {
    final r = await _api.loginDriverPin(phone: _driverPhoneCtrl.text.trim(), pin: _driverPinCtrl.text.trim());
    await _go(DriverScreen(initialSession: r));
  }

  Future<void> _loginByCodeAutoDetect() async {
    final secret = _codeCtrl.text.trim();
    if (secret.isEmpty) throw TaxiApiException('missing_code', 400);
    LoginResponse? picked;
    for (final role in const ['owner', 'operator', 'b2b']) {
      try { picked = await _api.login(role: role, secret: secret); break; } catch (_) {}
    }
    if (picked == null) throw TaxiApiException('invalid_credentials', 401);
    final r = picked;
    if (r.role == 'owner') { await _go(OwnerScreen(initialToken: r.accessToken)); return; }
    if (r.role == 'operator') { await _go(OperatorScreen(initialToken: r.accessToken)); return; }
    if (r.role == 'b2b') { await _go(B2bScreen(initialSession: r)); return; }
    throw TaxiApiException('invalid_role', 400);
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() { _busy = true; _message = null; });
    try { await fn(); }
    on TaxiAccountDisabledException { if (!mounted) return; setState(() => _message = AppLocalizations.of(context)!.accountDisabledContactAdmin); }
    catch (e) { if (!mounted) return; setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _C.bgWarm,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: _C.charcoal,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: _C.charcoal),
                  // Checkerboard stripe (classic taxi pattern)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: List.generate(40, (i) => Expanded(
                          child: Container(color: i.isEven ? _C.yellow : _C.charcoal),
                        )),
                      ),
                    ),
                  ),
                  // Logo area
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: _C.yellow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.5), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 36),
                        ),
                        const SizedBox(height: 10),
                        const Text('TAXI TUNISIA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                        const Text('Votre course, notre fierté', style: TextStyle(color: Color(0xFF888888), fontSize: 12, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Passenger card
                _TaxiCard(
                  accent: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.yellowDeep)), child: const Icon(Icons.person_outline_rounded, color: _C.charcoal, size: 22)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.rolePassenger, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textStrong)),
                        const Text('Passager', style: TextStyle(color: _C.textSoft, fontSize: 12)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    _YellowButton(label: 'Continue as Passenger', icon: Icons.arrow_forward_rounded, onPressed: _busy ? null : () => _go(const AppPassengerScreen())),
                  ]),
                ),

                // Staff collapsible
                Container(
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.admin_panel_settings_outlined, color: _C.yellow, size: 22),
                      ),
                      title: const Text('Staff / Partner Access', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textStrong)),
                      subtitle: const Text('Driver · B2B · Operator · Owner', style: TextStyle(color: _C.textSoft, fontSize: 12)),
                      iconColor: _C.charcoal,
                      collapsedIconColor: _C.textSoft,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        const Divider(color: Color(0xFFEEE9D8)),
                        const SizedBox(height: 12),
                        // Driver block
                        const _SectionLabel('Driver Login'),
                        const SizedBox(height: 10),
                        TextField(controller: _driverPhoneCtrl, decoration: _fd('Phone', icon: Icons.phone_outlined)),
                        const SizedBox(height: 10),
                        TextField(controller: _driverPinCtrl, obscureText: true, decoration: _fd('PIN', icon: Icons.pin_outlined)),
                        const SizedBox(height: 14),
                        _DarkButton(label: 'Driver Sign In', icon: Icons.local_taxi_rounded, onPressed: _busy ? null : () => _run(_loginDriver)),
                        const SizedBox(height: 20),
                        // Code block
                        const Divider(color: Color(0xFFEEE9D8)),
                        const SizedBox(height: 16),
                        const _SectionLabel('Owner / Operator / B2B'),
                        const SizedBox(height: 10),
                        TextField(controller: _codeCtrl, obscureText: true, decoration: _fd('Access Code', icon: Icons.vpn_key_outlined)),
                        const SizedBox(height: 14),
                        _DarkButton(label: 'Sign In with Code', icon: Icons.shield_outlined, onPressed: _busy ? null : () => _run(_loginByCodeAutoDetect)),
                      ],
                    ),
                  ),
                ),

                // Error
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13))),
                    ]),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator(color: _C.yellow, strokeWidth: 2.5)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}