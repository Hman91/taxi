// ═══════════════════════════════════════════════════════════════
// owner_screen.dart — TUNISIAN TAXI YELLOW THEME
// Refactored: modular treasury · decoupled driver mgmt · styled B2B
// All original logic preserved — only UI/structure improved
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import 'unified_login_screen.dart';

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
  static const success     = Color(0xFF1A7A4A);
  static const successBg   = Color(0xFFD4EDDA);
  static const info        = Color(0xFF1E3A8A);
  static const infoBg      = Color(0xFFDEEBFF);
}

// ── Shared UI helpers ─────────────────────────────────────────

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, required this.onPressed, this.icon, this.small = false, this.fullWidth = true});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small; final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final child = Container(
      height: small ? 38 : 48,
      width: fullWidth ? double.infinity : null,
      padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: disabled ? _C.yellowSoft : _C.yellow,
        borderRadius: BorderRadius.circular(50),
        boxShadow: disabled ? [] : [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: _C.charcoal, size: small ? 14 : 18), const SizedBox(width: 6)],
        Text(label, style: TextStyle(color: _C.charcoal, fontWeight: FontWeight.w900, fontSize: small ? 12 : 14, letterSpacing: 0.2)),
      ])),
    );
    return GestureDetector(onTap: onPressed, child: child);
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed, this.icon, this.small = false, this.fullWidth = true});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool small; final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 38 : 48,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFCCCCCC) : _C.charcoal,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled ? [] : [BoxShadow(color: _C.charcoal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: small ? 14 : 18), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 12 : 14, letterSpacing: 0.2)),
        ])),
      ),
    );
  }
}

InputDecoration _fd(String label, {IconData? icon, String? suffix}) => InputDecoration(
  labelText: label, labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
  prefixIcon: icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
  suffixText: suffix,
  filled: true, fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border, width: 1.4)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.yellow, width: 2)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

// ── Section heading with yellow accent bar ────────────────────
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title; final String? subtitle; final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
        if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
      ])),
      if (trailing != null) trailing!,
    ]),
  );
}

// ── Module card container ─────────────────────────────────────
class _Module extends StatelessWidget {
  const _Module({required this.child, this.padding = 16, this.accent = false});
  final Widget child; final double padding; final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: _C.surface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
      boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

// ── Stat chip ────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, this.color = _C.charcoal});
  final String label; final String value; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
    ]),
  );
}

// ── B2B Tenant card ───────────────────────────────────────────
class _B2bCard extends StatelessWidget {
  const _B2bCard({required this.tenant, required this.onEdit, required this.onToggle, required this.busy, required this.uiText});
  final Map<String, dynamic> tenant;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final bool busy;
  final String Function(String) uiText;

  @override
  Widget build(BuildContext context) {
    final enabled = tenant['is_enabled'] == true;
    final code = tenant['code']?.toString() ?? '';
    final label = tenant['label']?.toString() ?? code;
    final hotel = tenant['hotel']?.toString() ?? '';
    final wallet = (tenant['wallet_balance'] ?? 0).toString();
    final name = tenant['contact_name']?.toString() ?? '';
    final phone = tenant['phone']?.toString() ?? '';
    final pin = tenant['pin']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? _C.yellowDeep.withOpacity(0.5) : _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: enabled ? _C.yellowSoft : _C.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: enabled ? _C.yellowDeep : _C.border),
              ),
              child: Icon(Icons.hotel_rounded, color: enabled ? _C.charcoal : _C.textSoft, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textStrong))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: enabled ? _C.successBg : _C.dangerBg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(enabled ? 'Active' : 'Paused', style: TextStyle(color: enabled ? _C.success : _C.danger, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ]),
              if (hotel.isNotEmpty) Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: _C.textSoft),
                const SizedBox(width: 3),
                Text(hotel, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
              ]),
            ])),
          ]),
          const SizedBox(height: 12),
          // Details grid
          Wrap(spacing: 8, runSpacing: 6, children: [
            _infoTag(Icons.tag_rounded, 'Code: $code'),
            _infoTag(Icons.person_outline_rounded, name.isEmpty ? 'No contact' : name),
            _infoTag(Icons.phone_outlined, phone.isEmpty ? 'No phone' : phone),
            _infoTag(Icons.account_balance_wallet_outlined, '$wallet DT'),
            _infoTag(Icons.pin_outlined, pin.isEmpty ? 'No PIN' : '••••'),
          ]),
          const SizedBox(height: 12),
          // Actions
          Row(children: [
            Expanded(child: _DarkButton(label: 'Edit', icon: Icons.edit_outlined, onPressed: busy ? null : onEdit, small: true)),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: busy ? null : onToggle,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: enabled ? _C.dangerBg : _C.successBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: enabled ? _C.danger.withOpacity(0.3) : _C.success.withOpacity(0.3)),
                ),
                child: Center(child: Text(enabled ? 'Pause' : 'Activate', style: TextStyle(color: enabled ? _C.danger : _C.success, fontWeight: FontWeight.w800, fontSize: 12))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: _C.textSoft),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: _C.textMid, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Driver wallet card ────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.onEdit, required this.busy, required this.subtitle});
  final Map<String, dynamic> driver; final VoidCallback onEdit; final bool busy; final String subtitle;

  @override
  Widget build(BuildContext context) {
    final name = driver['driver_name']?.toString() ?? '';
    final wallet = (driver['wallet_balance'] ?? 0);
    final autoDeduct = driver['auto_deduct_enabled'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)), child: const Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textStrong)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(50), border: Border.all(color: _C.yellowDeep)),
                  child: Text('$wallet DT', style: const TextStyle(color: _C.charcoal, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                if (autoDeduct) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _C.successBg, borderRadius: BorderRadius.circular(50)),
                  child: const Text('Auto-deduct', style: TextStyle(color: _C.success, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
            ])),
            IconButton(
              onPressed: busy ? null : onEdit,
              icon: Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_outlined, color: Colors.white, size: 15)),
              padding: EdgeInsets.zero,
            ),
          ]),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Text(subtitle, style: const TextStyle(color: _C.textMid, fontSize: 11, height: 1.4)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key, this.initialToken});
  final String? initialToken;

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> with SingleTickerProviderStateMixin {
  // ALL ORIGINAL FIELDS (unchanged)
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'NabeulGold2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverPin = TextEditingController();
  final _newDriverCarModel = TextEditingController();
  final _newDriverCarColor = TextEditingController();
  String _newDriverPhotoData = '';
  final _topUpAmountController = TextEditingController(text: '10');
  int? _topUpAccountId;
  TabController? _tabController;
  bool _obscurePassword = true;
  String? _token;
  String? _message;
  bool _busy = false;
  Map<String, dynamic>? _metrics;
  Map<String, dynamic>? _adminMetrics;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  List<Map<String, dynamic>> _fareRoutes = [];
  List<Map<String, dynamic>> _driverWalletBreakdown = [];
  List<Map<String, dynamic>> _driverRatings = [];
  final Map<int, TextEditingController> _fareCtrls = {};
  double _commissionDemoPercent = 10.0;
  Widget _appBarHomeLogo() => GestureDetector(
    onTap: () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      );
    },
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(9)),
      child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 18),
    ),
  );

  // ALL ORIGINAL LOGIC (unchanged)
  void _syncFareControllers(List<Map<String, dynamic>> routes) {
    final ids = <int>{};
    for (final r in routes) {
      final idRaw = r['id']; if (idRaw is! num) continue;
      final id = idRaw.toInt(); ids.add(id);
      final bf = r['base_fare'];
      final text = bf is num ? bf.toStringAsFixed(2) : bf?.toString() ?? '0.00';
      if (_fareCtrls.containsKey(id)) { _fareCtrls[id]!.text = text; }
      else { _fareCtrls[id] = TextEditingController(text: text); }
    }
    for (final k in _fareCtrls.keys.toList()) { if (!ids.contains(k)) _fareCtrls.remove(k)?.dispose(); }
  }

  String _ownerDriverPinSubtitle(AppLocalizations l, Map<String, dynamic> d) {
    final walletS = (d['wallet_balance'] ?? 0).toString(); final ownerS = (d['owner_commission_rate'] ?? 10).toString(); final b2bS = (d['b2b_commission_rate'] ?? 5).toString();
    var line = l.operatorDriverWalletLine(walletS, ownerS, b2bS);
    final model = (d['car_model'] ?? '').toString().trim(); final color = (d['car_color'] ?? '').toString().trim();
    if (model.isNotEmpty) line += l.operatorDriverCarLine(model);
    if (color.isNotEmpty) line += l.operatorDriverCarColorAppend(color);
    line += '\n${_uiText(en: 'Simple rides income', ar: 'مداخيل الرحلات العادية', fr: 'Revenus des courses simples', es: 'Ingresos de viajes simples', de: 'Einnahmen aus einfachen Fahrten', it: 'Entrate corse semplici', ru: 'Доход с обычных поездок', zh: '普通行程收入')}: ${(d['gross_normal'] ?? 0).toString()} DT';
    line += ' | ${_uiText(en: 'B2B rides income', ar: 'مداخيل رحلات B2B', fr: 'Revenus des courses B2B', es: 'Ingresos de viajes B2B', de: 'Einnahmen aus B2B-Fahrten', it: 'Entrate corse B2B', ru: 'Доход с B2B поездок', zh: 'B2B行程收入')}: ${(d['gross_b2b'] ?? 0).toString()} DT';
    line += '\n${_uiText(en: 'Deducted from simple rides', ar: 'المخصوم من الرحلات العادية', fr: 'Retenu des courses simples', es: 'Descontado de viajes simples', de: 'Abzug aus einfachen Fahrten', it: 'Detratto da corse semplici', ru: 'Удержано с обычных поездок', zh: '普通行程扣除')}: ${(d['deducted_normal'] ?? 0).toString()} DT';
    line += ' | ${_uiText(en: 'Deducted from B2B rides', ar: 'المخصوم من رحلات B2B', fr: 'Retenu des courses B2B', es: 'Descontado de viajes B2B', de: 'Abzug aus B2B-Fahrten', it: 'Detratto da corse B2B', ru: 'Удержано с B2B поездок', zh: 'B2B行程扣除')}: ${(d['deducted_b2b'] ?? 0).toString()} DT';
    return line;
  }

  String _uiText({required String en, required String ar, required String fr, required String es, required String de, required String it, required String ru, required String zh}) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return ar; if (code.startsWith('fr')) return fr; if (code.startsWith('es')) return es;
    if (code.startsWith('de')) return de; if (code.startsWith('it')) return it; if (code.startsWith('ru')) return ru;
    if (code.startsWith('zh')) return zh; return en;
  }

  Future<void> _login() async {
    setState(() { _busy = true; _message = null; });
    try {
      final r = await _api.login(role: 'owner', secret: _secretController.text.trim());
      _token = r.accessToken; await _refreshAll();
    } catch (e) { setState(() => _message = e.toString()); }
    finally { setState(() => _busy = false); }
  }

  Future<void> _refreshAll() async {
    final t = _token; if (t == null) return;
    setState(() => _busy = true);
    try {
      final m = await _api.ownerMetrics(t); final trips = await _api.listTrips(t);
      final adminRides = await _api.listAdminRides(t); final adminB2b = await _api.listAdminB2bTenants(t);
      final adminB2bBookings = await _api.listAdminB2bBookings(t); final adminMetrics = await _api.adminOwnerMetrics(t);
      final flights = await _api.listAdminTunisiaFlightArrivals(t); final fareRoutes = await _api.listAdminFareRoutes(t);
      final driverWallets = await _api.listAdminDriverWalletBreakdown(t); final ratings = await _api.listAdminDriverRatings(t);
      if (!mounted) return;
      setState(() {
        _metrics = m; _adminMetrics = adminMetrics;
        _trips = trips.map((e) => {'id': e.id, 'date': e.date, 'route': e.route, 'fare': e.fare, 'commission': e.commission, 'type': e.type}).toList();
        _adminRides = adminRides; _adminB2b = adminB2b; _adminB2bBookings = adminB2bBookings;
        _flightArrivals = flights; _fareRoutes = fareRoutes; _driverWalletBreakdown = driverWallets; _driverRatings = ratings;
        final ids = driverWallets.map((e) => (e['id'] as num?)?.toInt()).whereType<int>().toList();
        if (_topUpAccountId != null && !ids.contains(_topUpAccountId)) _topUpAccountId = null;
        _topUpAccountId ??= ids.isEmpty ? null : ids.first;
        _syncFareControllers(fareRoutes); _message = null;
      });
    } catch (e) {
      final msg = e.toString();
      setState(() => _message = msg.contains('phone_exists_or_invalid') ? _uiText(en: 'Phone already exists or invalid.', ar: 'رقم الهاتف موجود مسبقا أو غير صالح.', fr: 'Le numero existe deja ou est invalide.', es: 'El telefono ya existe o no es valido.', de: 'Telefon existiert bereits oder ist ungueltig.', it: 'Il telefono esiste gia o non e valido.', ru: 'Телефон уже существует или недействителен.', zh: '电话号码已存在或无效。') : msg);
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveFareRoute(int routeId) async {
    final t = _token; final ctrl = _fareCtrls[routeId]; if (t == null || ctrl == null) return;
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0) { setState(() => _message = _uiText(en: 'Invalid fare', ar: 'تعرفة غير صالحة', fr: 'Tarif invalide', es: 'Tarifa invalida', de: 'Ungueltiger Fahrpreis', it: 'Tariffa non valida', ru: 'Неверный тариф', zh: '无效费用')); return; }
    setState(() { _busy = true; _message = null; });
    try { await _api.patchAdminFareRoute(token: t, routeId: routeId, baseFare: v); await _refreshAll(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _toggleB2b(Map<String, dynamic> tenant) async {
    final t = _token; if (t == null) return;
    final idRaw = tenant['id']; if (idRaw is! num) return;
    final current = (tenant['is_enabled'] == true);
    setState(() { _busy = true; _message = null; });
    try { await _api.setAdminB2bEnabled(token: t, tenantId: idRaw.toInt(), isEnabled: !current); await _refreshAll(); }
    catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _pickNewDriverImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes(); final name = picked.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
    final mime = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
    if (!mounted) return;
    setState(() { _newDriverPhotoData = 'data:$mime;base64,${base64Encode(bytes)}'; });
  }

  Future<void> _createDriverAccount() async {
    final t = _token; if (t == null) return;
    final phone = _newDriverPhone.text.trim(); final name = _newDriverName.text.trim();
    final pin = _newDriverPin.text.trim(); final carModel = _newDriverCarModel.text.trim();
    final carColor = _newDriverCarColor.text.trim(); final photoUrl = _newDriverPhotoData.trim();
    final loc = AppLocalizations.of(context)!;
    if (phone.isEmpty || name.isEmpty || pin.isEmpty || carModel.isEmpty || carColor.isEmpty) { setState(() => _message = loc.operatorFillDriverFields); return; }
    setState(() { _busy = true; _message = null; });
    try {
      await _api.createAdminDriverPinAccount(token: t, phone: phone, pin: pin, driverName: name, carModel: carModel, carColor: carColor, photoUrl: photoUrl);
      _newDriverPhone.clear(); _newDriverName.clear(); _newDriverPin.clear(); _newDriverCarModel.clear(); _newDriverCarColor.clear(); _newDriverPhotoData = '';
      await _refreshAll();
    } catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _editDriverAccount(Map<String, dynamic> row) async {
    final t = _token; if (t == null) return;
    final id = (row['id'] as num?)?.toInt(); if (id == null) return;
    final walletCtrl = TextEditingController(text: (row['wallet_balance'] ?? 0).toString());
    final ownerRateCtrl = TextEditingController(text: (row['owner_commission_rate'] ?? 10).toString());
    final b2bRateCtrl = TextEditingController(text: (row['b2b_commission_rate'] ?? 5).toString());
    final modelCtrl = TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl = TextEditingController(text: row['car_color']?.toString() ?? '');
    bool autoDeduct = row['auto_deduct_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)), child: const Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text((row['driver_name'] ?? 'Driver').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            TextField(controller: walletCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _fd(AppLocalizations.of(ctx)!.operatorWalletBalanceLabel, icon: Icons.account_balance_wallet_outlined, suffix: 'DT')),
            const SizedBox(height: 10),
            TextField(controller: ownerRateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _fd(AppLocalizations.of(ctx)!.operatorOwnerCommissionLabel, icon: Icons.percent_rounded, suffix: '%')),
            const SizedBox(height: 10),
            TextField(controller: b2bRateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _fd(AppLocalizations.of(ctx)!.operatorB2bCommissionLabel, icon: Icons.business_center_outlined, suffix: '%')),
            const SizedBox(height: 10),
            TextField(controller: modelCtrl, decoration: _fd(AppLocalizations.of(ctx)!.operatorCarModelLabel, icon: Icons.directions_car_outlined)),
            const SizedBox(height: 10),
            TextField(controller: colorCtrl, decoration: _fd(AppLocalizations.of(ctx)!.operatorCarColorLabel, icon: Icons.palette_outlined)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
              child: SwitchListTile(
                dense: true,
                title: Text(AppLocalizations.of(ctx)!.operatorAutoDeductEnabled, style: const TextStyle(fontWeight: FontWeight.w600)),
                value: autoDeduct,
                onChanged: (v) => setSt(() => autoDeduct = v),
                activeColor: _C.yellow,
              ),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: _C.textMid))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() { _busy = true; _message = null; });
      try {
        await _api.patchAdminDriverPinAccount(token: t, accountId: id, payload: {
          'wallet_balance': double.tryParse(walletCtrl.text.trim().replaceAll(',', '.')) ?? (row['wallet_balance'] as num?)?.toDouble() ?? 0.0,
          'owner_commission_rate': double.tryParse(ownerRateCtrl.text.trim().replaceAll(',', '.')) ?? (row['owner_commission_rate'] as num?)?.toDouble() ?? 10.0,
          'b2b_commission_rate': double.tryParse(b2bRateCtrl.text.trim().replaceAll(',', '.')) ?? (row['b2b_commission_rate'] as num?)?.toDouble() ?? 5.0,
          'auto_deduct_enabled': autoDeduct, 'car_model': modelCtrl.text.trim(), 'car_color': colorCtrl.text.trim(),
        });
        await _refreshAll();
      } catch (e) { setState(() => _message = e.toString()); }
      finally { if (mounted) setState(() => _busy = false); }
    }
    walletCtrl.dispose(); ownerRateCtrl.dispose(); b2bRateCtrl.dispose(); modelCtrl.dispose(); colorCtrl.dispose();
  }

  Future<void> _rechargeDriverWallet() async {
    final t = _token; final id = _topUpAccountId; if (t == null || id == null) return;
    final amount = double.tryParse(_topUpAmountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) { setState(() => _message = _uiText(en: 'Invalid recharge amount', ar: 'مبلغ الشحن غير صالح', fr: 'Montant de recharge invalide', es: 'Importe de recarga invalido', de: 'Ungueltiger Aufladebetrag', it: 'Importo ricarica non valido', ru: 'Неверная сумма пополнения', zh: '充值金额无效')); return; }
    int? _toIntId(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }
    final row = _driverWalletBreakdown.firstWhere((e) => _toIntId(e['id']) == id, orElse: () => const <String, dynamic>{});
    if (row.isEmpty) {
      setState(() => _message = _uiText(
        en: 'Selected driver wallet not found. Refresh and retry.',
        ar: 'محفظة السائق المحدد غير موجودة. حدّث الصفحة وأعد المحاولة.',
        fr: 'Portefeuille du chauffeur introuvable. Rafraichissez puis reessayez.',
        es: 'No se encontro la billetera del conductor. Actualiza y reintenta.',
        de: 'Fahrer-Wallet nicht gefunden. Aktualisieren und erneut versuchen.',
        it: 'Wallet autista non trovato. Aggiorna e riprova.',
        ru: 'Кошелек водителя не найден. Обновите и повторите.',
        zh: '未找到所选司机钱包，请刷新后重试。',
      ));
      return;
    }
    final current = (row['wallet_balance'] as num?)?.toDouble() ?? 0.0;
    setState(() { _busy = true; _message = null; });
    try {
      await _api.patchAdminDriverPinAccount(token: t, accountId: id, payload: {'wallet_balance': current + amount});
      _topUpAmountController.text = '10';
      await _refreshAll();
      if (mounted) {
        setState(() => _message = _uiText(
          en: 'Wallet recharged successfully.',
          ar: 'تم شحن المحفظة بنجاح.',
          fr: 'Portefeuille recharge avec succes.',
          es: 'Billetera recargada con exito.',
          de: 'Wallet erfolgreich aufgeladen.',
          it: 'Wallet ricaricato con successo.',
          ru: 'Кошелек успешно пополнен.',
          zh: '钱包充值成功。',
        ));
      }
    } catch (e) { setState(() => _message = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _createB2bTenant() async {
    final t = _token; if (t == null) return;
    final codeCtrl = TextEditingController(); final labelCtrl = TextEditingController(); final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController(); final phoneCtrl = TextEditingController(); final hotelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)), child: const Icon(Icons.add_business_rounded, color: _C.charcoal, size: 18)),
          const SizedBox(width: 10),
          const Text('Create B2B Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          TextField(controller: hotelCtrl, decoration: _fd('Hotel / Company', icon: Icons.hotel_rounded)),
          const SizedBox(height: 10),
          TextField(controller: codeCtrl, decoration: _fd('Code', icon: Icons.tag_rounded)),
          const SizedBox(height: 10),
          TextField(controller: labelCtrl, decoration: _fd('Label', icon: Icons.label_outline_rounded)),
          const SizedBox(height: 10),
          TextField(controller: nameCtrl, decoration: _fd('Contact Name', icon: Icons.person_outline_rounded)),
          const SizedBox(height: 10),
          TextField(controller: phoneCtrl, decoration: _fd('Phone', icon: Icons.phone_outlined)),
          const SizedBox(height: 10),
          TextField(controller: pinCtrl, obscureText: true, decoration: _fd('PIN', icon: Icons.pin_outlined)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: _C.textMid))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), elevation: 0), onPressed: () => Navigator.pop(ctx, true), child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok == true) {
      setState(() { _busy = true; _message = null; });
      try { await _api.createAdminB2bTenant(token: t, code: codeCtrl.text.trim(), label: labelCtrl.text.trim(), contactName: nameCtrl.text.trim(), pin: pinCtrl.text.trim(), phone: phoneCtrl.text.trim(), hotel: hotelCtrl.text.trim()); await _refreshAll(); }
      catch (e) { setState(() => _message = e.toString()); }
      finally { if (mounted) setState(() => _busy = false); }
    }
    codeCtrl.dispose(); labelCtrl.dispose(); nameCtrl.dispose(); pinCtrl.dispose(); phoneCtrl.dispose(); hotelCtrl.dispose();
  }

  Future<void> _editB2bTenant(Map<String, dynamic> row) async {
    final t = _token; if (t == null) return;
    final id = (row['id'] as num?)?.toInt(); if (id == null) return;
    final codeCtrl = TextEditingController(text: (row['code'] ?? '').toString()); final labelCtrl = TextEditingController(text: (row['label'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (row['contact_name'] ?? '').toString()); final pinCtrl = TextEditingController(text: (row['pin'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString()); final hotelCtrl = TextEditingController(text: (row['hotel'] ?? '').toString());
    bool enabled = row['is_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit B2B Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            TextField(controller: hotelCtrl, decoration: _fd('Hotel / Company', icon: Icons.hotel_rounded)),
            const SizedBox(height: 10),
            TextField(controller: codeCtrl, decoration: _fd('Code', icon: Icons.tag_rounded)),
            const SizedBox(height: 10),
            TextField(controller: labelCtrl, decoration: _fd('Label', icon: Icons.label_outline_rounded)),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: _fd('Contact Name', icon: Icons.person_outline_rounded)),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: _fd('Phone', icon: Icons.phone_outlined)),
            const SizedBox(height: 10),
            TextField(controller: pinCtrl, obscureText: true, decoration: _fd('PIN', icon: Icons.pin_outlined)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
              child: SwitchListTile(dense: true, title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w600)), value: enabled, onChanged: (v) => setSt(() => enabled = v), activeColor: _C.yellow),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: _C.textMid))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.yellow, foregroundColor: _C.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), elevation: 0), onPressed: () => Navigator.pop(ctx, true), child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() { _busy = true; _message = null; });
      try {
        await _api.patchAdminB2bTenant(token: t, tenantId: id, payload: {'code': codeCtrl.text.trim(), 'label': labelCtrl.text.trim(), 'contact_name': nameCtrl.text.trim(), 'pin': pinCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'hotel': hotelCtrl.text.trim(), 'is_enabled': enabled});
        await _refreshAll();
      } catch (e) { setState(() => _message = e.toString()); }
      finally { if (mounted) setState(() => _busy = false); }
    }
    codeCtrl.dispose(); labelCtrl.dispose(); nameCtrl.dispose(); pinCtrl.dispose(); phoneCtrl.dispose(); hotelCtrl.dispose();
  }

  String _arrivalAirportLabel(Map<String, dynamic> row) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'ar' ? (row['arrival_airport_ar']?.toString() ?? row['arrival_airport_en']?.toString() ?? '') : (row['arrival_airport_en']?.toString() ?? row['arrival_airport_ar']?.toString() ?? '');
  }

  String _departureAirportLabel(Map<String, dynamic> row) {
    final city = (row['departure_city'] ?? '').toString().trim();
    final country = (row['departure_country'] ?? '').toString().trim();
    final iata = (row['departure_iata'] ?? '').toString().trim().toUpperCase();
    if (city.isNotEmpty && country.isNotEmpty && iata.isNotEmpty) {
      return '$city, $country ($iata)';
    }
    return (row['departure_airport'] ?? '').toString();
  }

  String _prettyDateTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    final normalized = s.replaceFirst(' - ', 'T').replaceFirst(' ', 'T');
    final dt = DateTime.tryParse(normalized) ?? DateTime.tryParse(s);
    if (dt == null) return s;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final mon = months[local.month - 1];
    final year = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day $mon $year – $hh:$mm';
  }

  // ══ TAB BUILDERS ══════════════════════════════════════════

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _DarkButton(label: l.adminLoadRidesBtn, icon: Icons.refresh_rounded, onPressed: _busy ? null : _refreshAll),
          const SizedBox(height: 16),
          _SectionHead(l.operatorTabTodaysArrivals),
          if (_flightArrivals.isEmpty)
            _Module(child: Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Icon(Icons.flight_land_rounded, size: 40, color: _C.textSoft),
                const SizedBox(height: 8),
                Text(l.operatorNoFlightArrivals, style: const TextStyle(color: _C.textSoft)),
              ]),
            )))
          else
            _Module(padding: 0, child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_C.charcoal),
                headingTextStyle: const TextStyle(color: _C.yellow, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                dataRowColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _C.yellowSoft : null),
                border: TableBorder(horizontalInside: BorderSide(color: _C.border)),
                columns: [
                  DataColumn(label: Text(l.operatorColFlightNumber)),
                  const DataColumn(label: Text('Airline')),
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('Aircraft')),
                  DataColumn(label: Text(l.operatorColDepartureAirport)),
                  DataColumn(label: Text(l.operatorColTakeoffTime)),
                  DataColumn(label: Text(l.operatorColExpectedArrival)),
                  const DataColumn(label: Text('Last update')),
                  const DataColumn(label: Text('Speed')),
                  const DataColumn(label: Text('Altitude')),
                  DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                ],
                rows: _flightArrivals.asMap().entries.map((e) {
                  final r = e.value;
                  return DataRow(cells: [
                    DataCell(Text(r['flight_number']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    DataCell(Text((r['airline'] ?? '').toString(), style: const TextStyle(fontSize: 13))),
                    DataCell(Text((r['status'] ?? '').toString(), style: const TextStyle(fontSize: 13))),
                    DataCell(Text((r['aircraft'] ?? '').toString(), style: const TextStyle(fontSize: 13))),
                    DataCell(Text(_departureAirportLabel(r), style: const TextStyle(fontSize: 13))),
                    DataCell(Text(r['takeoff_time']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(
                      (() {
                        final raw = _prettyDateTime(r['expected_arrival']?.toString() ?? '');
                        return raw.trim().isEmpty ? '-' : raw;
                      })(),
                      style: const TextStyle(fontSize: 13),
                    )),
                    DataCell(Text(_prettyDateTime(r['last_update']?.toString() ?? ''), style: const TextStyle(fontSize: 13))),
                    DataCell(Text((r['speed_kmh'] == null) ? '-' : '${r['speed_kmh']} km/h', style: const TextStyle(fontSize: 13))),
                    DataCell(Text((r['altitude_m'] == null) ? '-' : '${r['altitude_m']} m', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(_arrivalAirportLabel(r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  ]);
                }).toList(),
              ),
            )),
        ],
      ),
    );
  }

  // ══ TREASURY TAB — Modular, decoupled sections ════════════
  Widget _buildTreasuryTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ① KPI overview
          _buildKpiModule(l),
          const SizedBox(height: 4),
          // ② Driver management (create + top-up)
          _buildDriverManagementModule(l),
          const SizedBox(height: 4),
          // ③ Driver wallets list
          _buildDriverWalletsModule(l),
          const SizedBox(height: 4),
          // ④ Driver ratings
          _buildDriverRatingsModule(l),
          const SizedBox(height: 4),
          // ⑤ Trip ledger
          _buildTripLedgerModule(l),
        ],
      ),
    );
  }

  // ══ LIVE ORDERS TAB ════════════════════════════════════════
  Widget _buildLiveOrdersTab(AppLocalizations l) {
    int countByStatus(String status) => _adminRides.where((r) => (r['status'] ?? '').toString().trim() == status).length;
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHead('Dispatch & monitoring', subtitle: 'Live operational overview'),
                  Text(
                    _adminRides.any((r) => (r['status'] ?? '').toString() == 'pending')
                        ? 'There are pending requests that need assigning.'
                        : 'No pending requests right now.',
                    style: const TextStyle(color: _C.textSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Pending', value: '${countByStatus('pending')}', icon: Icons.hourglass_top, color: _C.yellowDeep),
                      _StatChip(label: 'Accepted', value: '${countByStatus('accepted')}', icon: Icons.local_taxi, color: _C.charcoal),
                      _StatChip(label: 'Ongoing', value: '${countByStatus('ongoing')}', icon: Icons.route, color: _C.info),
                      _StatChip(label: 'Completed', value: '${countByStatus('completed')}', icon: Icons.check_circle, color: _C.success),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRidesLogModule(l),
        ],
      ),
    );
  }

  // ① KPIs
  Widget _buildKpiModule(AppLocalizations l) {
    final m = _metrics; final am = _adminMetrics;
    return _Module(
      accent: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead(l.ownerTabTreasury, subtitle: 'Financial overview', trailing: _DarkButton(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: _busy ? null : _refreshAll, small: true, fullWidth: false)),
        if (m != null || am != null)
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (m != null) ...[
              _StatChip(label: 'My Profit', value: '${m['total_commission'] ?? 0} DT', icon: Icons.payments_outlined, color: _C.success),
              _StatChip(label: 'Trips', value: '${m['trip_count'] ?? 0}', icon: Icons.route_outlined),
              _StatChip(label: 'Rating', value: '${m['rating_average'] ?? 0} ⭐', icon: Icons.star_outlined, color: _C.yellowDeep),
            ],
            if (am != null) ...[
              _StatChip(label: 'Total Commission', value: '${am['total_commission'] ?? 0} DT', icon: Icons.account_balance_outlined, color: _C.info),
              _StatChip(label: 'All Trips', value: '${am['trip_count'] ?? 0}', icon: Icons.analytics_outlined),
            ],
          ])
        else
          const Text('Tap Refresh to load metrics', style: TextStyle(color: _C.textSoft)),
      ]),
    );
  }

  // ② Driver management (create + wallet top-up)
  Widget _buildDriverManagementModule(AppLocalizations l) {
    return _Module(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead(_uiText(en: 'Driver Management', ar: 'إدارة السائقين', fr: 'Gestion des chauffeurs', es: 'Gestión de conductores', de: 'Fahrerverwaltung', it: 'Gestione autisti', ru: 'Управление водителями', zh: '司机管理'), subtitle: 'Create accounts · Top up wallets'),
        // Create driver
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)), child: const Icon(Icons.person_add_alt_1_outlined, color: _C.charcoal, size: 18)),
          title: const Text('Create Driver Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          childrenPadding: const EdgeInsets.only(top: 8),
          children: [
            TextField(controller: _newDriverPhone, keyboardType: TextInputType.phone, decoration: _fd('Phone', icon: Icons.phone_outlined)),
            const SizedBox(height: 8),
            TextField(controller: _newDriverName, decoration: _fd(l.operatorDriverNameLabel, icon: Icons.badge_outlined)),
            const SizedBox(height: 8),
            TextField(controller: _newDriverPin, obscureText: true, decoration: _fd('PIN', icon: Icons.pin_outlined)),
            const SizedBox(height: 8),
            TextField(controller: _newDriverCarModel, decoration: _fd(l.operatorCarModelLabel, icon: Icons.directions_car_outlined)),
            const SizedBox(height: 8),
            TextField(controller: _newDriverCarColor, decoration: _fd(l.operatorCarColorLabel, icon: Icons.palette_outlined)),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _busy ? null : _pickNewDriverImage, icon: const Icon(Icons.photo_library_outlined, size: 16), label: Text(l.operatorPickFromGallery), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), side: const BorderSide(color: _C.border))),
            const SizedBox(height: 12),
            _YellowButton(label: _uiText(en: 'Create Driver Account', ar: 'إنشاء حساب سائق', fr: 'Créer un compte chauffeur', es: 'Crear cuenta de conductor', de: 'Fahrerkonto erstellen', it: 'Crea account autista', ru: 'Создать аккаунт водителя', zh: '创建司机账户'), icon: Icons.add_rounded, onPressed: _busy ? null : _createDriverAccount),
          ],
        ),
        const Divider(height: 24, color: _C.border),
        // Wallet top-up
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.infoBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.savings_outlined, color: _C.info, size: 18)),
          const SizedBox(width: 10),
          const Text('Recharge Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: _topUpAccountId,
            decoration: _fd(l.operatorDriverNameLabel, icon: Icons.person_outline_rounded),
            dropdownColor: _C.surface,
            items: _driverWalletBreakdown.map((d) => DropdownMenuItem<int>(value: (d['id'] as num?)?.toInt(), child: Text('${d['driver_name'] ?? ''}', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: _busy ? null : (v) => setState(() => _topUpAccountId = v),
          )),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: TextField(controller: _topUpAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _fd('Amount', suffix: 'DT'))),
        ]),
        const SizedBox(height: 12),
        _DarkButton(label: _uiText(en: 'Recharge Balance', ar: 'شحن الرصيد', fr: 'Recharger le solde', es: 'Recargar saldo', de: 'Guthaben aufladen', it: 'Ricarica saldo', ru: 'Пополнить баланс', zh: '充值余额'), icon: Icons.bolt_rounded, onPressed: _busy || _topUpAccountId == null ? null : _rechargeDriverWallet),
      ]),
    );
  }

  // ③ Driver wallets
  Widget _buildDriverWalletsModule(AppLocalizations l) {
    return _Module(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead(l.ownerDriverPinWalletsHeading, subtitle: '${_driverWalletBreakdown.length} drivers'),
        if (_driverWalletBreakdown.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 36, color: _C.textSoft),
            const SizedBox(height: 8),
            Text(l.ownerDriverPinWalletsEmpty, style: const TextStyle(color: _C.textSoft)),
          ])))
        else
          ..._driverWalletBreakdown.map((d) => _DriverCard(driver: d, onEdit: () => _editDriverAccount(d), busy: _busy, subtitle: _ownerDriverPinSubtitle(l, d))),
      ]),
    );
  }

  // ④ Driver ratings
  Widget _buildDriverRatingsModule(AppLocalizations l) {
    return _Module(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead(_uiText(en: 'Driver Ratings', ar: 'تقييمات السائقين', fr: 'Notes des chauffeurs', es: 'Calificaciones', de: 'Fahrerbewertungen', it: 'Valutazioni', ru: 'Рейтинг', zh: '司机评分')),
        if (_driverRatings.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(_uiText(en: 'No ratings yet', ar: 'لا توجد تقييمات بعد', fr: 'Pas encore de notes', es: 'Sin calificaciones', de: 'Keine Bewertungen', it: 'Nessuna valutazione', ru: 'Нет оценок', zh: '暂无评分'), style: const TextStyle(color: _C.textSoft)))
        else
          ..._driverRatings.map((row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.yellowDeep)), child: const Center(child: Icon(Icons.star_rounded, color: _C.charcoal, size: 18))),
              const SizedBox(width: 10),
              Expanded(child: Text((row['driver_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${row['rating_average']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _C.charcoal)),
                Text('${row['rating_count']} ${_uiText(en: 'ratings', ar: 'تقييمات', fr: 'notes', es: 'califs.', de: 'Bewert.', it: 'valut.', ru: 'оценок', zh: '评分')}', style: const TextStyle(color: _C.textSoft, fontSize: 10)),
              ]),
            ]),
          )),
      ]),
    );
  }

  // ⑤ Trip ledger
  Widget _buildTripLedgerModule(AppLocalizations l) {
    return _Module(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead(l.ownerVaultHeading, subtitle: '${_trips.length} trips'),
        if (_trips.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.noTripsYet, style: const TextStyle(color: _C.textSoft)))
        else
          ..._trips.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(9)), child: const Center(child: Icon(Icons.receipt_long_rounded, color: _C.yellow, size: 16))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.ownerTripRouteFareRow(t['route']?.toString() ?? '', t['fare']?.toString() ?? ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(l.tripListSubtitle(t['date'] as String, t['commission'].toString()), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
              ])),
            ]),
          )),
      ]),
    );
  }

  // ⑥ Rides log
  Widget _buildRidesLogModule(AppLocalizations l) {
    return _Module(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHead('App rides', subtitle: '${_adminRides.length} rides'),
        if (_adminRides.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.adminNoRidesLoaded, style: const TextStyle(color: _C.textSoft)))
        else
          ..._adminRides.take(30).map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.border)), child: const Center(child: Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 16))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(localizedRideRouteRow(l, r['pickup']?.toString() ?? '', r['destination']?.toString() ?? ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(l.operatorRideSubtitleLine('${l.statusLinePrefix}${localizedRideStatusLabel(l, r['status']?.toString())}', ((r['driver_name'] ?? r['driver_id'] ?? '').toString().trim().isEmpty) ? '' : '${l.driverLabelPrefix}${(r['driver_name'] ?? r['driver_id']).toString()}', (r['created_at'] ?? '').toString().trim().isEmpty ? '' : '${l.createdAtLinePrefix}${r['created_at']}'), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
              ])),
              Text(
                (r['is_b2b'] == true)
                    ? '${l.roleB2b}: ${(r['b2b_guest_name'] ?? r['passenger_name'] ?? r['user_id'] ?? '-').toString()}'
                    : '${l.rolePassenger}: ${(r['passenger_name'] ?? r['user_id'] ?? '-').toString()}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ]),
          )),
      ]),
    );
  }

  // ══ SETTINGS TAB ══════════════════════════════════════════
  Widget _buildSettingsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Commission slider module
          _Module(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SectionHead(l.ownerSettingsCommissionLabel),
              Text(l.ownerSettingsCommissionHint, style: const TextStyle(color: _C.textSoft, fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              Center(child: Text(_commissionDemoPercent.toStringAsFixed(2), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _C.charcoal))),
              const Center(child: Text('%', style: TextStyle(color: _C.textSoft, fontSize: 14))),
              Slider(value: _commissionDemoPercent.clamp(0.0, 40.0), min: 0, max: 40, divisions: 400, label: _commissionDemoPercent.toStringAsFixed(1), activeColor: _C.yellow, inactiveColor: _C.border, onChanged: _busy ? null : (v) => setState(() => _commissionDemoPercent = v)),
            ]),
          ),
          // Fare routes module
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(l.ownerSettingsRouteFaresHeading, subtitle: '${_fareRoutes.length} routes'),
              if (_fareRoutes.isEmpty)
                Text(l.adminNoRidesLoaded, style: const TextStyle(color: _C.textSoft))
              else
                ..._fareRoutes.map((r) {
                  final id = (r['id'] as num).toInt();
                  final label = localizedRideRouteRow(l, r['start']?.toString() ?? '', r['destination']?.toString() ?? '');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textStrong)),
                      const SizedBox(height: 12),
                      Row(children: [
                        GestureDetector(
                          onTap: _busy ? null : () { final c = _fareCtrls[id]; if (c == null) return; final v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0; c.text = (v > 1 ? v - 1 : 0).toStringAsFixed(2); setState(() {}); },
                          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.remove_rounded, color: Colors.white, size: 18)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(
                          controller: _fareCtrls[id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          decoration: _fd('', suffix: 'DT'),
                        )),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _busy ? null : () { final c = _fareCtrls[id]; if (c == null) return; final v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0; c.text = (v + 1).toStringAsFixed(2); setState(() {}); },
                          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: _YellowButton(label: l.ownerSaveRouteFare, icon: Icons.save_outlined, onPressed: _busy ? null : () => _saveFareRoute(id), small: true, fullWidth: false)),
                    ]),
                  );
                }),
            ]),
          ),
        ],
      ),
    );
  }

  // ══ B2B HOTEL TAB ════════════════════════════════════════
  Widget _buildB2bTab(AppLocalizations l) {
    final enabled = _adminB2b.where((b) => b['is_enabled'] == true).toList();
    final paused = _adminB2b.where((b) => b['is_enabled'] != true).toList();

    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Action buttons
          Row(children: [
            Expanded(child: _DarkButton(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: _busy ? null : _refreshAll, small: true)),
            const SizedBox(width: 8),
            Expanded(child: _YellowButton(label: 'New B2B Account', icon: Icons.add_business_rounded, onPressed: _busy ? null : _createB2bTenant, small: true)),
          ]),
          const SizedBox(height: 16),

          // B2B Bookings module
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(l.ownerAdminOversightHeading, subtitle: '${_adminB2bBookings.length} bookings'),
              if (_adminB2bBookings.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                  const Icon(Icons.book_outlined, size: 36, color: _C.textSoft),
                  const SizedBox(height: 8),
                  Text(l.noTripsLoaded, style: const TextStyle(color: _C.textSoft)),
                ])))
              else
                ..._adminB2bBookings.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(9)), child: const Center(child: Icon(Icons.hotel_rounded, color: _C.yellow, size: 16))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b['route']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(l.adminB2bBookingRowSubtitle(b['guest_name']?.toString() ?? '', b['room_number']?.toString() ?? '-', b['fare']?.toString() ?? ''), style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    ])),
                  ]),
                )),
            ]),
          ),

          // Active hotels
          if (enabled.isNotEmpty) ...[
            _SectionHead('Active Hotels', subtitle: '${enabled.length} accounts'),
            ...enabled.map((b) => _B2bCard(tenant: b, onEdit: () => _editB2bTenant(b), onToggle: () => _toggleB2b(b), busy: _busy, uiText: (en) => en)),
          ],

          // Paused hotels
          if (paused.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SectionHead('Paused Hotels', subtitle: '${paused.length} accounts'),
            ...paused.map((b) => _B2bCard(tenant: b, onEdit: () => _editB2bTenant(b), onToggle: () => _toggleB2b(b), busy: _busy, uiText: (en) => en)),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final t = widget.initialToken;
    if (t != null && t.isNotEmpty) {
      _token = t;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; _refreshAll(); });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; restoreUiRoleLocale(AppUiRole.owner); });
  }

  @override
  void dispose() {
    _tabController?.dispose(); _secretController.dispose(); _newDriverPhone.dispose();
    _newDriverName.dispose(); _newDriverPin.dispose(); _newDriverCarModel.dispose();
    _newDriverCarColor.dispose(); _topUpAmountController.dispose();
    for (final c in _fareCtrls.values) { c.dispose(); }
    _fareCtrls.clear(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;

    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.charcoal,
        centerTitle: true,
        title: _appBarHomeLogo(),
        actions: [
          const LocalePopupMenuButton(uiRole: AppUiRole.owner),
          if (_token != null)
            IconButton(onPressed: _busy ? null : _refreshAll, icon: const Icon(Icons.refresh_rounded, color: _C.yellow)),
        ],
      ),
      body: _token == null
          // ── Login ──────────────────────────────────────────
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.45), blurRadius: 20)]),
                    child: const Icon(Icons.local_taxi_rounded, color: _C.charcoal, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Owner HQ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _C.textStrong)),
                  const SizedBox(height: 4),
                  Text(l.ownerPasswordCeoLabel, style: const TextStyle(color: _C.textSoft, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border), boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))]),
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      TextField(
                        controller: _secretController, obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l.ownerPassword, labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: _C.charcoal, size: 18),
                          filled: true, fillColor: _C.surfaceAlt,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.yellow, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _C.textSoft), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _YellowButton(label: l.loginLoadDashboard, icon: Icons.login_rounded, onPressed: _busy ? null : _login),
                    ]),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))), child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13)))])),
                  ],
                  if (_busy) ...[const SizedBox(height: 16), const CircularProgressIndicator(color: _C.yellow, strokeWidth: 2.5)],
                ]),
              ),
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator(color: _C.yellow))
              // ── Dashboard ──────────────────────────────────
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Welcome banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFC200), Color(0xFFFFD84D)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _C.yellow.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: _C.charcoal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.ownerWelcomeHq, style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w700, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(14)),
                    child: TabBar(
                      controller: tc, isScrollable: true,
                      indicatorColor: _C.yellow, indicatorWeight: 3,
                      labelColor: _C.yellow, unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.3),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      tabs: [
                        Tab(text: '✈️ ${l.operatorTabTodaysArrivals}'),
                        Tab(text: '💸 ${_uiText(en: "Live orders", ar: "طلبات مباشرة", fr: "Commandes en direct", es: "Pedidos en vivo", de: "Live-Aufträge", it: "Ordini live", ru: "Заказы онлайн", zh: "实时订单")}'),
                        Tab(text: '💰 ${l.ownerTabTreasury}'),
                        Tab(text: '⚙️ ${l.ownerTabSettings}'),
                        Tab(text: '🏨 ${l.ownerTabHostelB2b}'),
                      ],
                    ),
                  ),
                  Expanded(child: TabBarView(
                    controller: tc,
                    children: [_buildArrivalsTab(l), _buildLiveOrdersTab(l), _buildTreasuryTab(l), _buildSettingsTab(l), _buildB2bTab(l)],
                  )),
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: _C.dangerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.danger.withOpacity(0.3))),
                      child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13)))]),
                    ),
                ]),
    );
  }
}