import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_locale.dart'
    show
        AppUiRole,
        rememberCurrentLocaleForRole,
        restoreUiRoleLocale,
        userChoseLocaleThisSession,
        appLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/voom_logo.dart';
import 'unified_login_screen.dart';

class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const bgWarm = Color(0xFFFAF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF111111);
  static const textMid = Color(0xFF3F3F3F);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE4E4);
  static const info = Color(0xFF1D4ED8);
  static const success = Color(0xFF15803D);
}

InputDecoration _fd(String label, {Widget? suffixIcon}) => InputDecoration(
  labelText: label,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: _C.surfaceAlt,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.border, width: 1.4),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _C.yellow, width: 2),
  ),
);

class _Module extends StatelessWidget {
  const _Module({required this.child, this.accent = false});
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent ? _C.yellowDeep : _C.border, width: accent ? 2 : 1),
          boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

Widget _kpiChip({required IconData icon, required String label}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: _C.yellowSoft,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _C.yellowDeep),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 16, color: _C.charcoal),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: _C.charcoal, fontWeight: FontWeight.w700, fontSize: 12)),
  ]),
);

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color = _C.charcoal,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

Widget _rowInfoCard({
  required IconData icon,
  required Widget content,
  Widget? trailing,
  Color iconBg = _C.surfaceAlt,
  Color iconColor = _C.charcoal,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.border),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );

Widget _b2bStatusPill({required bool enabled}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? _C.yellowSoft : _C.dangerBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        enabled ? 'Active' : 'Paused',
        style: TextStyle(
          color: enabled ? _C.charcoal : _C.danger,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _C.yellow, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _C.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key, this.initialToken});
  final String? initialToken;

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen>
    with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'Operator2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverEmail = TextEditingController();
  final _newDriverPin = TextEditingController();
  final _newDriverCarModel = TextEditingController();
  final _newDriverCarColor = TextEditingController();
  String _newDriverPhotoData = '';
  final _topUpAmountController = TextEditingController(text: '10');
  TabController? _tabController;
  bool _obscureOperatorPassword = true;
  bool _obscureNewDriverPin = true;
  String? _token;
  String? _message;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _driverPinAccounts = [];
  List<Map<String, dynamic>> _managedDriverUsers = [];
  List<Map<String, dynamic>> _managedB2bUsers = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  String? _flightDataSource;
  List<Map<String, dynamic>> _driverRatings = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  String _rideStatusFilter = 'all';
  String _b2bApprovalFilter = 'all';
  int? _topUpAccountId;
  bool _busy = false;
  Future<void> _goToHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Future<void> _goBack() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    await _goToHome();
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Future<void> _editMyAccount() async {
    final t = _token;
    if (t == null || t.isEmpty) return;
    final currentPasswordCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool busy = false;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('My Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: _fd('New email (optional)', suffixIcon: const Icon(Icons.email_outlined, size: 18))),
              const SizedBox(height: 8),
              TextField(controller: newPasswordCtrl, obscureText: true, decoration: _fd('New password (optional)', suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18))),
              const SizedBox(height: 8),
              TextField(controller: currentPasswordCtrl, obscureText: true, decoration: _fd('Current password', suffixIcon: const Icon(Icons.password_rounded, size: 18))),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setLocal(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await _api.patchMyAccount(
                          token: t,
                          currentPassword: currentPasswordCtrl.text,
                          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          password: newPasswordCtrl.text.trim().isEmpty ? null : newPasswordCtrl.text,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setLocal(() => error = e.toString());
                      } finally {
                        setLocal(() => busy = false);
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    currentPasswordCtrl.dispose();
    emailCtrl.dispose();
    newPasswordCtrl.dispose();
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully.')),
      );
    }
  }

  Widget _appBarHomeLogo() => GestureDetector(
        onTap: () => unawaited(_goToHome()),
        child: const VoomLogo(height: 30),
      );

  int _countByStatus(String status) => _adminRides
      .where((r) => (r['status'] ?? '').toString().trim() == status)
      .length;

  double get _tripVaultRevenue => _trips.fold<double>(
      0.0, (sum, t) => sum + ((t['fare'] as num?)?.toDouble() ?? 0.0));

  bool _isRealManagedDriver(Map<String, dynamic> u) {
    final email = (u['email'] ?? '').toString().toLowerCase();
    if (email.endsWith('@taxipro.local')) return false;
    if (email.endsWith('@example.com')) return false;
    if (email.startsWith('dispatch_')) return false;
    if (email.startsWith('smoke_')) return false;
    return true;
  }

  static const Map<String, ({double lat, double lng})> _zoneCoords = {
    'مطار قرطاج': (lat: 36.8508, lng: 10.2272),
    'مطار النفيضة': (lat: 36.0758, lng: 10.4386),
    'مطار المنستير': (lat: 35.7581, lng: 10.7547),
    'وسط سوسة': (lat: 35.8256, lng: 10.63699),
    'الحمامات': (lat: 36.4000, lng: 10.6167),
    'نابل': (lat: 36.4561, lng: 10.7376),
    'القنطاوي': (lat: 35.8920, lng: 10.5950),
  };

  double? _rideDistanceKm(Map<String, dynamic> r) {
    final pickup = (r['pickup'] ?? '').toString().trim();
    final destination = (r['destination'] ?? '').toString().trim();
    final a = _zoneCoords[pickup];
    final b = _zoneCoords[destination];
    if (a == null || b == null) return null;
    final dLat = a.lat - b.lat;
    final dLng = a.lng - b.lng;
    return math.sqrt(dLat * dLat + dLng * dLng) * 111.0;
  }

  String _ridePrice(Map<String, dynamic> r) {
    final p = r['b2b_fare'] ?? r['fare'];
    if (p is num) return '${p.toStringAsFixed(2)} DT';
    return '-';
  }

  Widget _rideMiniChip({
    required IconData icon,
    required String text,
    Color color = _C.textSoft,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _b2bApprovalStatus(Map<String, dynamic> row) {
    final raw = (row['approval_status'] ?? '').toString().trim().toLowerCase();
    if (raw == 'approved' || raw == 'pending' || raw == 'rejected') return raw;
    return row['is_enabled'] == true ? 'approved' : 'pending';
  }

  bool _matchesB2bApprovalFilter(Map<String, dynamic> row) {
    if (_b2bApprovalFilter == 'all') return true;
    return _b2bApprovalStatus(row) == _b2bApprovalFilter;
  }

  Widget _b2bApprovalChip(String status) {
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final bg = isApproved
        ? const Color(0xFFD4EDDA)
        : (isPending ? const Color(0xFFFFF3CD) : _C.dangerBg);
    final fg = isApproved
        ? _C.success
        : (isPending ? const Color(0xFF8A6D3B) : _C.danger);
    final label = isApproved
        ? _uiText(
            en: 'Approved',
            ar: 'موافق عليه',
            fr: 'Approuve',
            es: 'Aprobado',
            de: 'Genehmigt',
            it: 'Approvato',
            ru: 'Одобрено',
            zh: '已批准',
          )
        : (isPending
            ? _uiText(
                en: 'Pending',
                ar: 'قيد الانتظار',
                fr: 'En attente',
                es: 'Pendiente',
                de: 'Ausstehend',
                it: 'In attesa',
                ru: 'В ожидании',
                zh: '待处理',
              )
            : _uiText(
                en: 'Rejected',
                ar: 'مرفوض',
                fr: 'Refuse',
                es: 'Rechazado',
                de: 'Abgelehnt',
                it: 'Rifiutato',
                ru: 'Отклонено',
                zh: '已拒绝',
              ));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _b2bFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _busy ? null : (_) => onTap(),
      selectedColor: _C.yellowSoft,
      backgroundColor: _C.surface,
      side: BorderSide(color: selected ? _C.yellowDeep : _C.border),
      labelStyle: TextStyle(
        color: selected ? _C.charcoal : _C.textStrong,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Map<String, dynamic>? _findManagedDriverForRow({
    required String name,
    required String phone,
  }) {
    final n = name.trim().toLowerCase();
    final p = phone.trim();
    for (final u in _managedDriverUsers) {
      final un = (u['display_name'] ?? '').toString().trim().toLowerCase();
      final up = (u['phone'] ?? '').toString().trim();
      if (p.isNotEmpty && up == p) return u;
      if (n.isNotEmpty && un == n) return u;
    }
    return null;
  }

  List<Map<String, dynamic>> _visibleDriverRatings() => _driverRatings
      .where((r) => _findManagedDriverForRow(
            name: (r['driver_name'] ?? '').toString(),
            phone: (r['phone'] ?? '').toString(),
          ) != null)
      .toList();

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(
          role: 'operator', secret: _secretController.text.trim());
      if (userChoseLocaleThisSession.value) {
        try {
          await _api.patchPreferredLanguage(
            token: r.accessToken,
            preferredLanguage: appLocale.value.languageCode,
          );
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.operator);
      _token = r.accessToken;
      await SessionStore.saveOperatorToken(r.accessToken);
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshAll() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      Future<T?> safe<T>(Future<T> request) async {
        try {
          return await request;
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait<dynamic>([
        safe(_api.listTrips(t)),
        safe(_api.listAdminRides(t, limit: 80)),
        safe(_api.listAdminDriverPinAccounts(t)),
        safe(_api.listAdminB2bTenants(t)),
        safe(_api.listAdminB2bBookings(t, limit: 80)),
        safe(_api.listAdminTunisiaFlightArrivals(t)),
        safe(_api.listAdminDriverRatings(t)),
        safe(_api.listAdminPendingUsers(t, limit: 80)),
        safe(_api.listAdminUsers(t, limit: 160)),
      ]);
      final trips = results[0] as List<dynamic>?;
      final rides = results[1] as List<dynamic>?;
      final driverPins = results[2] as List<dynamic>?;
      final b2bTenants = results[3] as List<dynamic>?;
      final b2bBookings = results[4] as List<dynamic>?;
      final fr = results[5] as ({List<Map<String, dynamic>> flights, String? source})?;
      final ratings = results[6] as List<dynamic>?;
      final pendingApprovals = results[7] as List<dynamic>?;
      final appUsers = results[8] as List<dynamic>?;

      if (trips == null ||
          rides == null ||
          driverPins == null ||
          b2bTenants == null ||
          b2bBookings == null ||
          fr == null ||
          ratings == null ||
          pendingApprovals == null ||
          appUsers == null) {
        setState(() => _message = 'Cannot reach API server. Check backend IP/network.');
        return;
      }
      setState(() {
        _trips = trips
            .map(
              (e) => {
                'id': e.id,
                'date': e.date,
                'route': e.route,
                'fare': e.fare,
                'status': e.status,
              },
            )
            .toList();
        _adminRides = rides.cast<Map<String, dynamic>>();
        _driverPinAccounts = driverPins.cast<Map<String, dynamic>>();
        _adminB2b = b2bTenants.cast<Map<String, dynamic>>();
        _adminB2bBookings = b2bBookings.cast<Map<String, dynamic>>();
        _flightArrivals = fr.flights;
        _flightDataSource = fr.source;
        _driverRatings = ratings.cast<Map<String, dynamic>>();
        _pendingApprovals = pendingApprovals.cast<Map<String, dynamic>>();
        final appUsersTyped = appUsers.cast<Map<String, dynamic>>();
        final appDriverUsers = appUsersTyped
            .where((u) => (u['role'] ?? '') == 'driver')
            .where(_isRealManagedDriver)
            .map((u) => {...u, 'source': 'app_user'})
            .cast<Map<String, dynamic>>()
            .toList();
        _managedDriverUsers = appDriverUsers;
        _managedB2bUsers = appUsersTyped
            .where((u) => (u['role'] ?? '') == 'b2b')
            .toList();
        final ids = driverPins
            .map((e) => (e['id'] as num?)?.toInt())
            .whereType<int>()
            .toList();
        if (_topUpAccountId != null &&
            !ids.contains(_topUpAccountId)) {
          _topUpAccountId = null;
        }
        _topUpAccountId ??= ids.isEmpty ? null : ids.first;
      });
    } catch (e) {
      final msg = e.toString();
      setState(
        () => _message = msg.contains('phone_exists_or_invalid')
            ? _uiText(
                en: 'Phone already exists or invalid.',
                ar: 'رقم الهاتف موجود مسبقا أو غير صالح.',
                fr: 'Le numero existe deja ou est invalide.',
                es: 'El telefono ya existe o no es valido.',
                de: 'Telefon existiert bereits oder ist ungueltig.',
                it: 'Il telefono esiste gia o non e valido.',
                ru: 'Телефон уже существует или недействителен.',
                zh: '电话号码已存在或无效。',
              )
            : msg,
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _createDriverAccount() async {
    final t = _token;
    if (t == null) return;
    final phone = _newDriverPhone.text.trim();
    final name = _newDriverName.text.trim();
    final email = _newDriverEmail.text.trim();
    final password = _newDriverPin.text.trim();
    final carModel = _newDriverCarModel.text.trim();
    final carColor = _newDriverCarColor.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (phone.isEmpty ||
        name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        carModel.isEmpty ||
        carColor.isEmpty) {
      setState(() => _message = loc.operatorFillDriverFields);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.createAdminAppUser(
        token: t,
        email: email,
        password: password,
        role: 'driver',
        displayName: name,
        phone: phone,
        carModel: carModel,
        carColor: carColor,
        autoApprove: true,
      );
      _newDriverEmail.clear();
      _newDriverPhone.clear();
      _newDriverName.clear();
      _newDriverPin.clear();
      _newDriverCarModel.clear();
      _newDriverCarColor.clear();
      _newDriverPhotoData = '';
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setApproval(Map<String, dynamic> row, bool accepted) async {
    final t = _token;
    final id = (row['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.setAdminUserEnabled(token: t, userId: id, isEnabled: accepted);
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteManagedDriver(Map<String, dynamic> row) async {
    final t = _token;
    final id = (row['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete driver account?'),
        content: Text('This will permanently remove ${(row['display_name'] ?? row['email'] ?? 'this driver').toString()}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.deleteAdminAppUser(token: t, userId: id);
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editManagedDriver(Map<String, dynamic> row) async {
    final t = _token;
    final id = (row['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    final emailCtrl = TextEditingController(text: (row['email'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (row['display_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString());
    final passCtrl = TextEditingController();
    final modelCtrl = TextEditingController(text: (row['car_model'] ?? '').toString());
    final colorCtrl = TextEditingController(text: (row['car_color'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Driver'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: emailCtrl, decoration: _fd('Email', suffixIcon: const Icon(Icons.email_outlined, size: 18))),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: _fd(
                'Password (optional)',
                suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              ),
            ),
            TextField(controller: nameCtrl, decoration: _fd('Name', suffixIcon: const Icon(Icons.badge_outlined, size: 18))),
            TextField(controller: phoneCtrl, decoration: _fd('Phone', suffixIcon: const Icon(Icons.phone_outlined, size: 18))),
            TextField(controller: modelCtrl, decoration: _fd('Car type', suffixIcon: const Icon(Icons.directions_car_outlined, size: 18))),
            TextField(controller: colorCtrl, decoration: _fd('Car color', suffixIcon: const Icon(Icons.palette_outlined, size: 18))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _api.patchAdminAppUserProfile(
        token: t,
        userId: id,
        payload: {
          'email': emailCtrl.text.trim(),
          'display_name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'car_model': modelCtrl.text.trim(),
          'car_color': colorCtrl.text.trim(),
          if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text,
        },
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editManagedB2b(Map<String, dynamic> row) async {
    final t = _token;
    final id = (row['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    final emailCtrl = TextEditingController(text: (row['email'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (row['display_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString());
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit B2B Account'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: emailCtrl, decoration: _fd('Email', suffixIcon: const Icon(Icons.email_outlined, size: 18))),
            TextField(controller: passCtrl, decoration: _fd('Password (optional)', suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18))),
            TextField(controller: nameCtrl, decoration: _fd('Name', suffixIcon: const Icon(Icons.badge_outlined, size: 18))),
            TextField(controller: phoneCtrl, decoration: _fd('Phone', suffixIcon: const Icon(Icons.phone_outlined, size: 18))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _api.patchAdminAppUserProfile(
        token: t,
        userId: id,
        payload: {
          'email': emailCtrl.text.trim(),
          'display_name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text,
        },
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDriverAccount(Map<String, dynamic> row) async {
    final t = _token;
    if (t == null) return;
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return;
    final modelCtrl =
        TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl =
        TextEditingController(text: row['car_color']?.toString() ?? '');
    final photoCtrl =
        TextEditingController(text: row['photo_url']?.toString() ?? '');
    String selectedPhotoData = photoCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
          title: Text(row['driver_name']?.toString() ?? loc.operatorDriverNameLabel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: _fd(loc.operatorCarModelLabel),
                ),
                TextField(
                  controller: colorCtrl,
                  decoration: _fd(loc.operatorCarColorLabel),
                ),
                const SizedBox(height: 8),
                if (selectedPhotoData.isNotEmpty)
                  Builder(
                    builder: (_) {
                      final provider = _imageProviderFromString(selectedPhotoData);
                      if (provider == null) return const SizedBox.shrink();
                      return Center(
                        child: SizedBox(
                          width: 220,
                          height: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: provider,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1600,
                    );
                    if (picked == null) return;
                    final bytes = await picked.readAsBytes();
                    final name = picked.name.toLowerCase();
                    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
                    final mime = ext == 'png'
                        ? 'image/png'
                        : ext == 'webp'
                            ? 'image/webp'
                            : 'image/jpeg';
                    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
                    if (!mounted) return;
                    setSt(() {
                      selectedPhotoData = dataUrl;
                    });
                  },
                  icon: const Icon(Icons.photo_library),
                  label: Text(loc.operatorPickFromGallery),
                ),
                if (selectedPhotoData.isNotEmpty &&
                    selectedPhotoData.startsWith('data:image/'))
                  TextButton.icon(
                    onPressed: () => setSt(() => selectedPhotoData = ''),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(loc.operatorRemovePickedImage),
                  ),
                TextField(
                  controller: photoCtrl,
                  decoration: _fd(loc.operatorPhotoUrlOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.operatorCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.operatorSave),
            ),
          ],
          ),
        );
      },
    );
    if (ok != true) {
      modelCtrl.dispose();
      colorCtrl.dispose();
      photoCtrl.dispose();
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminDriverPinAccount(
        token: t,
        accountId: id,
        payload: {
          'car_model': modelCtrl.text.trim(),
          'car_color': colorCtrl.text.trim(),
          'photo_url': selectedPhotoData.isNotEmpty
              ? selectedPhotoData
              : photoCtrl.text.trim(),
        },
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      modelCtrl.dispose();
      colorCtrl.dispose();
      photoCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.operator);
      final t = widget.initialToken;
      if (t != null && t.isNotEmpty && _token == null) {
        _token = t;
        unawaited(SessionStore.saveOperatorToken(t));
        _refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _secretController.dispose();
    _newDriverPhone.dispose();
    _newDriverName.dispose();
    _newDriverEmail.dispose();
    _newDriverPin.dispose();
    _newDriverCarModel.dispose();
    _newDriverCarColor.dispose();
    _topUpAmountController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _imageProviderFromString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:image/')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx > 0 && commaIdx + 1 < trimmed.length) {
        try {
          final b64 = trimmed.substring(commaIdx + 1);
          return MemoryImage(base64Decode(b64));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    return Uri.tryParse(trimmed)?.hasScheme == true ? NetworkImage(trimmed) : null;
  }

  Future<void> _pickNewDriverImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : 'jpeg';
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    if (!mounted) return;
    setState(() {
      _newDriverPhotoData = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  TextStyle _operatorHeadingTextStyle() => const TextStyle(
        color: _C.textStrong,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  InputDecoration _operatorFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMid, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _C.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.border, width: 1.4),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _C.yellow, width: 2),
      ),
    );
  }

  Widget _driverMgmtSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.yellowSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.yellowDeep),
                  ),
                  child: Icon(icon, color: _C.charcoal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _C.textStrong,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _driverPinAccountTile(AppLocalizations l, Map<String, dynamic> d) {
    final title =
        '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})'.trim();
    final subtitle = () {
      var line = _uiText(
        en: 'Driver profile',
        ar: 'ملف السائق',
        fr: 'Profil chauffeur',
        es: 'Perfil del conductor',
        de: 'Fahrerprofil',
        it: 'Profilo autista',
        ru: 'Профиль водителя',
        zh: '司机资料',
      );
      final model = (d['car_model'] ?? '').toString().trim();
      final color = (d['car_color'] ?? '').toString().trim();
      if (model.isNotEmpty) line += l.operatorDriverCarLine(model);
      if (color.isNotEmpty) line += l.operatorDriverCarColorAppend(color);
      return line;
    }();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.charcoal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _busy ? null : () => _editDriverAccount(d),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                child: const Icon(Icons.local_taxi_outlined, color: _C.charcoal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.isEmpty ? '—' : title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textStrong),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => _editDriverAccount(d),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 15),
                ),
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
      ),
    );
  }

  Future<void> _createB2bTenant() async {
    final t = _token;
    if (t == null) return;
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hotelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
        title: const Text('Create B2B account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: _fd('Email')),
              TextField(controller: nameCtrl, decoration: _fd('Name')),
              TextField(controller: passwordCtrl, decoration: _fd('Password')),
              TextField(controller: phoneCtrl, decoration: _fd('Phone')),
              TextField(controller: hotelCtrl, decoration: _fd('Hotel')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.yellow,
              foregroundColor: _C.charcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _busy = true;
        _message = null;
      });
      try {
        await _api.createAdminAppUser(
          token: t,
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          role: 'b2b',
          displayName: nameCtrl.text.trim().isEmpty
              ? hotelCtrl.text.trim()
              : nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          autoApprove: true,
        );
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    hotelCtrl.dispose();
  }

  Future<void> _editB2bTenant(Map<String, dynamic> row) async {
    final t = _token;
    if (t == null) return;
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return;
    final codeCtrl = TextEditingController(text: (row['code'] ?? '').toString());
    final labelCtrl = TextEditingController(text: (row['label'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (row['contact_name'] ?? '').toString());
    final pinCtrl = TextEditingController(text: (row['pin'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString());
    final hotelCtrl = TextEditingController(text: (row['hotel'] ?? '').toString());
    bool enabled = row['is_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.border)),
          title: const Text('Edit B2B account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: _fd('Code')),
                TextField(controller: labelCtrl, decoration: _fd('Label')),
                TextField(controller: nameCtrl, decoration: _fd('Name')),
                TextField(controller: pinCtrl, decoration: _fd('PIN')),
                TextField(controller: phoneCtrl, decoration: _fd('Phone')),
                TextField(controller: hotelCtrl, decoration: _fd('Hotel')),
                SwitchListTile(
                  dense: true,
                  title: const Text('Enabled'),
                  value: enabled,
                  onChanged: (v) => setSt(() => enabled = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        _busy = true;
        _message = null;
      });
      try {
        await _api.patchAdminB2bTenant(
          token: t,
          tenantId: id,
          payload: {
            'code': codeCtrl.text.trim(),
            'label': labelCtrl.text.trim(),
            'contact_name': nameCtrl.text.trim(),
            'pin': pinCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'hotel': hotelCtrl.text.trim(),
            'is_enabled': enabled,
          },
        );
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    codeCtrl.dispose();
    labelCtrl.dispose();
    nameCtrl.dispose();
    pinCtrl.dispose();
    phoneCtrl.dispose();
    hotelCtrl.dispose();
  }

  Future<void> _setB2bEnabled(Map<String, dynamic> tenant, bool enabled) async {
    final t = _token;
    final id = (tenant['id'] as num?)?.toInt();
    if (t == null || id == null) return;
    try {
      await _api.patchAdminB2bTenant(
        token: t,
        tenantId: id,
        payload: {'is_enabled': enabled},
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    }
  }

  String _arrivalAirportLabel(Map<String, dynamic> row) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') {
      return row['arrival_airport_ar']?.toString() ??
          row['arrival_airport_en']?.toString() ??
          '';
    }
    return row['arrival_airport_en']?.toString() ??
        row['arrival_airport_ar']?.toString() ??
        '';
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

  Widget _buildArrivalsTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _C.charcoal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          onPressed: _busy ? null : _refreshAll,
          child: Text(l.adminLoadRidesBtn),
        ),
        const SizedBox(height: 16),
        _SectionHead(l.operatorTabTodaysArrivals),
        if ((_flightDataSource ?? '').startsWith('demo'))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.yellowSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.yellowDeep.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: _C.charcoal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.flightArrivalsSampleDataBanner,
                      style: const TextStyle(color: _C.textStrong, fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_flightArrivals.isEmpty)
          _Module(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Icon(Icons.flight_land_rounded, size: 40, color: _C.textSoft),
                  const SizedBox(height: 8),
                  Text(l.operatorNoFlightArrivals, style: const TextStyle(color: _C.textSoft)),
                ]),
              ),
            ),
          )
        else
          _Module(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_C.charcoal),
                headingTextStyle: const TextStyle(color: _C.yellow, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
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
                rows: _flightArrivals.map((r) {
                  return DataRow(
                    cells: [
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
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveOrdersTab(AppLocalizations l) {
    final filteredRides = _rideStatusFilter == 'all'
        ? _adminRides
        : _adminRides
            .where((r) => (r['status'] ?? '').toString().trim() == _rideStatusFilter)
            .toList();
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
                      GestureDetector(onTap: () => setState(() => _rideStatusFilter = 'pending'), child: _StatChip(label: _uiText(en: 'Pending', ar: 'قيد الانتظار', fr: 'En attente', es: 'Pendiente', de: 'Ausstehend', it: 'In attesa', ru: 'В ожидании', zh: '待处理'), value: '${_countByStatus('pending')}', icon: Icons.hourglass_top, color: _rideStatusFilter == 'pending' ? _C.yellowDeep : _C.textSoft)),
                      GestureDetector(onTap: () => setState(() => _rideStatusFilter = 'accepted'), child: _StatChip(label: _uiText(en: 'Accepted', ar: 'مقبول', fr: 'Accepte', es: 'Aceptado', de: 'Akzeptiert', it: 'Accettato', ru: 'Принято', zh: '已接受'), value: '${_countByStatus('accepted')}', icon: Icons.local_taxi, color: _rideStatusFilter == 'accepted' ? _C.charcoal : _C.textSoft)),
                      GestureDetector(onTap: () => setState(() => _rideStatusFilter = 'ongoing'), child: _StatChip(label: _uiText(en: 'Ongoing', ar: 'جار', fr: 'En cours', es: 'En curso', de: 'Laufend', it: 'In corso', ru: 'В пути', zh: '进行中'), value: '${_countByStatus('ongoing')}', icon: Icons.route, color: _rideStatusFilter == 'ongoing' ? _C.info : _C.textSoft)),
                      GestureDetector(onTap: () => setState(() => _rideStatusFilter = 'completed'), child: _StatChip(label: _uiText(en: 'Completed', ar: 'مكتمل', fr: 'Termine', es: 'Completado', de: 'Abgeschlossen', it: 'Completato', ru: 'Завершено', zh: '已完成'), value: '${_countByStatus('completed')}', icon: Icons.check_circle, color: _rideStatusFilter == 'completed' ? _C.success : _C.textSoft)),
                      GestureDetector(onTap: () => setState(() => _rideStatusFilter = 'all'), child: _StatChip(label: _uiText(en: 'All', ar: 'الكل', fr: 'Tous', es: 'Todos', de: 'Alle', it: 'Tutti', ru: 'Все', zh: '全部'), value: '${_adminRides.length}', icon: Icons.list_alt, color: _rideStatusFilter == 'all' ? _C.charcoal : _C.textSoft)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('App rides', subtitle: '${filteredRides.length} rides'),
              if (filteredRides.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.adminNoRidesLoaded, style: const TextStyle(color: _C.textSoft)))
              else
                ...filteredRides.take(30).map((r) => Container(
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
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _rideMiniChip(icon: Icons.person_outline, text: (r['driver_name'] ?? r['driver_id'] ?? '-').toString(), color: _C.charcoal),
                          _rideMiniChip(icon: Icons.route, text: '${_rideDistanceKm(r)?.toStringAsFixed(1) ?? '-'} km', color: _C.info),
                          _rideMiniChip(icon: Icons.schedule, text: (r['created_at'] ?? '-').toString()),
                          _rideMiniChip(icon: Icons.payments_outlined, text: _ridePrice(r), color: _C.success),
                        ],
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildB2bTab(AppLocalizations l) {
    Map<String, dynamic>? _tenantForManagedUser(Map<String, dynamic> u) {
      final phone = (u['phone'] ?? '').toString().trim();
      final email = (u['email'] ?? '').toString().trim().toLowerCase();
      if (phone.isNotEmpty) {
        for (final t in _adminB2b) {
          if ((t['phone'] ?? '').toString().trim() == phone) return t;
        }
      }
      if (email.isNotEmpty) {
        for (final t in _adminB2b) {
          final code = (t['code'] ?? '').toString().trim().toLowerCase();
          if (code.isNotEmpty && email.contains(code)) return t;
        }
      }
      return null;
    }

    final filteredB2b = _managedB2bUsers.where(_matchesB2bApprovalFilter).toList();
    final enabled = filteredB2b.where((b) => b['is_enabled'] == true).toList();
    final paused = filteredB2b.where((b) => b['is_enabled'] != true).toList();
    final visibleB2bCount = enabled.length + paused.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead(l.operatorCorporateBookingsSection, subtitle: '${_adminB2bBookings.length} bookings'),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.charcoal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _busy ? null : _refreshAll,
                child: Text(l.operatorRefreshCorporateBookings),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.yellow,
                  foregroundColor: _C.charcoal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _busy ? null : _createB2bTenant,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Create B2B account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Module(
          child: _adminB2bBookings.isEmpty
              ? Text(l.noTripsLoaded, style: const TextStyle(color: _C.textSoft))
              : Column(
                  children: _adminB2bBookings
                      .map(
                        (b) => _rowInfoCard(
                          icon: Icons.hotel_rounded,
                          iconBg: _C.charcoal,
                          iconColor: _C.yellow,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['route']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.adminB2bBookingRowSubtitle(
                                  b['guest_name']?.toString() ?? '',
                                  b['room_number']?.toString() ?? '-',
                                  b['fare']?.toString() ?? '',
                                ),
                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _SectionHead(_uiText(
          en: 'Hostel Accounts (B2B)',
          ar: 'حسابات الفنادق (B2B)',
          fr: 'Comptes hôtels (B2B)',
          es: 'Cuentas de hotel (B2B)',
          de: 'Hotelkonten (B2B)',
          it: 'Account hotel (B2B)',
          ru: 'Аккаунты отелей (B2B)',
          zh: '酒店账户 (B2B)',
        ), subtitle: '$visibleB2bCount accounts'),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _b2bFilterChip(
                label: _uiText(en: 'All', ar: 'الكل', fr: 'Tous', es: 'Todos', de: 'Alle', it: 'Tutti', ru: 'Все', zh: '全部'),
                selected: _b2bApprovalFilter == 'all',
                onTap: () => setState(() => _b2bApprovalFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _b2bFilterChip(
                label: _uiText(en: 'Approved', ar: 'موافق عليه', fr: 'Approuve', es: 'Aprobado', de: 'Genehmigt', it: 'Approvato', ru: 'Одобрено', zh: '已批准'),
                selected: _b2bApprovalFilter == 'approved',
                onTap: () => setState(() => _b2bApprovalFilter = 'approved'),
              ),
              const SizedBox(width: 8),
              _b2bFilterChip(
                label: _uiText(en: 'Pending', ar: 'قيد الانتظار', fr: 'En attente', es: 'Pendiente', de: 'Ausstehend', it: 'In attesa', ru: 'В ожидании', zh: '待处理'),
                selected: _b2bApprovalFilter == 'pending',
                onTap: () => setState(() => _b2bApprovalFilter = 'pending'),
              ),
              const SizedBox(width: 8),
              _b2bFilterChip(
                label: _uiText(en: 'Rejected', ar: 'مرفوض', fr: 'Refuse', es: 'Rechazado', de: 'Abgelehnt', it: 'Rifiutato', ru: 'Отклонено', zh: '已拒绝'),
                selected: _b2bApprovalFilter == 'rejected',
                onTap: () => setState(() => _b2bApprovalFilter = 'rejected'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (visibleB2bCount == 0)
          const Text('No B2B accounts yet', style: TextStyle(color: _C.textSoft))
        else ...[
          if (enabled.isNotEmpty) ...[
            _SectionHead(
              _uiText(
                en: 'Active Hotels',
                ar: 'فنادق نشطة',
                fr: 'Hotels actifs',
                es: 'Hoteles activos',
                de: 'Aktive Hotels',
                it: 'Hotel attivi',
                ru: 'Активные отели',
                zh: '活跃酒店',
              ),
              subtitle: '${enabled.length} ${_uiText(en: 'accounts', ar: 'حسابات', fr: 'comptes', es: 'cuentas', de: 'Konten', it: 'account', ru: 'аккаунтов', zh: '个账户')}',
            ),
            ...enabled.take(80).map((b) {
              final tenant = _tenantForManagedUser(b);
              final label = ((tenant?['label'] ?? b['display_name']) ?? '').toString();
              final code = (tenant?['code'] ?? '').toString();
              final contact = ((tenant?['contact_name'] ?? b['display_name']) ?? '').toString();
              final pin = (tenant?['pin'] ?? '').toString();
              final email = (b['email'] ?? '').toString();
              final phone = ((tenant?['phone'] ?? b['phone']) ?? '').toString();
              final hotel = (tenant?['hotel'] ?? '').toString();
              return _Module(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: _C.charcoal, borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.hotel_rounded, color: _C.yellow, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        const SizedBox(width: 8),
                        _b2bApprovalChip(_b2bApprovalStatus(b)),
                        const SizedBox(width: 8),
                        _b2bStatusPill(enabled: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (code.isNotEmpty) Text('Code: $code', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    if (contact.isNotEmpty || pin.isNotEmpty)
                      Text('Name: ${contact.isEmpty ? '-' : contact} | PIN: ${pin.isEmpty ? '-' : pin}', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Email: $email', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Phone: $phone', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    if (hotel.isNotEmpty) Text('Hotel: $hotel', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.charcoal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => tenant != null ? _editB2bTenant(tenant) : _editManagedB2b(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.dangerBg,
                              foregroundColor: _C.danger,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _setB2bEnabled(tenant, false)
                                    : _api.setAdminUserEnabled(token: _token!, userId: (b['id'] as num).toInt(), isEnabled: false).then((_) => _refreshAll()),
                            child: const Text('Pause'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
          if (paused.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SectionHead(
              _uiText(
                en: 'Paused Hotels',
                ar: 'فنادق متوقفة',
                fr: 'Hotels en pause',
                es: 'Hoteles en pausa',
                de: 'Pausierte Hotels',
                it: 'Hotel in pausa',
                ru: 'Приостановленные отели',
                zh: '暂停酒店',
              ),
              subtitle: '${paused.length} ${_uiText(en: 'accounts', ar: 'حسابات', fr: 'comptes', es: 'cuentas', de: 'Konten', it: 'account', ru: 'аккаунтов', zh: '个账户')}',
            ),
            ...paused.take(80).map((b) {
              final tenant = _tenantForManagedUser(b);
              final label = ((tenant?['label'] ?? b['display_name']) ?? '').toString();
              final code = (tenant?['code'] ?? '').toString();
              final contact = ((tenant?['contact_name'] ?? b['display_name']) ?? '').toString();
              final pin = (tenant?['pin'] ?? '').toString();
              final email = (b['email'] ?? '').toString();
              final phone = ((tenant?['phone'] ?? b['phone']) ?? '').toString();
              final hotel = (tenant?['hotel'] ?? '').toString();
              return _Module(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.border)),
                          child: const Icon(Icons.hotel_rounded, color: _C.charcoal, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        const SizedBox(width: 8),
                        _b2bApprovalChip(_b2bApprovalStatus(b)),
                        const SizedBox(width: 8),
                        _b2bStatusPill(enabled: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (code.isNotEmpty) Text('Code: $code', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    if (contact.isNotEmpty || pin.isNotEmpty)
                      Text('Name: ${contact.isEmpty ? '-' : contact} | PIN: ${pin.isEmpty ? '-' : pin}', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Email: $email', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    Text('Phone: $phone', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    if (hotel.isNotEmpty) Text('Hotel: $hotel', style: const TextStyle(color: _C.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.charcoal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : () => tenant != null ? _editB2bTenant(tenant) : _editManagedB2b(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD4EDDA),
                              foregroundColor: _C.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _setB2bEnabled(tenant, true)
                                    : _api.setAdminUserEnabled(token: _token!, userId: (b['id'] as num).toInt(), isEnabled: true).then((_) => _refreshAll()),
                            child: const Text('Activate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildDriverManagementTab(AppLocalizations l) {
    final visibleRatings = _visibleDriverRatings();
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: () async {
        await _refreshAll();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(
                _uiText(
                  en: 'Driver management',
                  ar: 'إدارة السائقين',
                  fr: 'Gestion des chauffeurs',
                  es: 'Gestion de conductores',
                  de: 'Fahrerverwaltung',
                  it: 'Gestione autisti',
                  ru: 'Управление водителями',
                  zh: '司机管理',
                ),
                subtitle: 'Profiles overview',
                trailing: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _busy ? null : _refreshAll,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(label: 'Profiles', value: '${_driverPinAccounts.length}', icon: Icons.badge_outlined, color: _C.info),
                  _StatChip(label: 'Ratings', value: '${_driverRatings.length}', icon: Icons.star_outline_rounded, color: _C.yellowDeep),
                ],
              ),
              const SizedBox(height: 12),
              _SectionHead('App User Requests', subtitle: '${_pendingApprovals.length} pending'),
              if (_pendingApprovals.isEmpty)
                const Text('No pending Driver/B2B requests.', style: TextStyle(color: _C.textSoft))
              else
                ..._pendingApprovals.map((u) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        '${u['role']} · ${u['email'] ?? ''}\n'
                        'name: ${u['display_name'] ?? ''} | phone: ${u['phone'] ?? ''}'
                        '${(u['car_model'] ?? '').toString().isNotEmpty ? '\ncar: ${u['car_model']} / ${u['car_color'] ?? ''}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Review Request'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Role: ${u['role'] ?? ''}'),
                                      Text('Email: ${u['email'] ?? ''}'),
                                      Text('Name: ${u['display_name'] ?? ''}'),
                                      Text('Phone: ${u['phone'] ?? ''}'),
                                      if ((u['car_model'] ?? '').toString().isNotEmpty) Text('Car type: ${u['car_model']}'),
                                      if ((u['car_color'] ?? '').toString().isNotEmpty) Text('Car color: ${u['car_color']}'),
                                      Text('Created at: ${u['created_at'] ?? ''}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Decline')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept')),
                                  ],
                                ),
                              );
                              if (ok == null) return;
                              await _setApproval(u, ok);
                            },
                      child: const Text('Review'),
                    ),
                  ]),
                )),
              const SizedBox(height: 8),
              _SectionHead('Driver account tools', subtitle: 'Create and manage driver login accounts'),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: _C.yellowSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.yellowDeep)),
                  child: const Icon(Icons.person_add_alt_1_outlined, color: _C.charcoal, size: 18),
                ),
                title: Text(
                  _uiText(
                    en: 'Add driver login account',
                    ar: 'إنشاء حساب سائق',
                    fr: 'Creer un compte chauffeur',
                    es: 'Crear cuenta de conductor',
                    de: 'Fahrerkonto erstellen',
                    it: 'Crea account autista',
                    ru: 'Создать аккаунт водителя',
                    zh: '创建司机账户',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                childrenPadding: const EdgeInsets.only(top: 8),
                children: [
                  TextField(
                    controller: _newDriverEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fd(
                      'Email',
                      suffixIcon: const Icon(Icons.email_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverPhone,
                    keyboardType: TextInputType.phone,
                    decoration: _fd(
                      _uiText(
                        en: 'Phone',
                        ar: 'الهاتف',
                        fr: 'Telephone',
                        es: 'Telefono',
                        de: 'Telefon',
                        it: 'Telefono',
                        ru: 'Телефон',
                        zh: '电话',
                      ),
                      suffixIcon: const Icon(Icons.phone_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverName,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fd(
                      _uiText(
                        en: 'Driver name',
                        ar: 'اسم السائق',
                        fr: 'Nom du chauffeur',
                        es: 'Nombre del conductor',
                        de: 'Fahrername',
                        it: 'Nome autista',
                        ru: 'Имя водителя',
                        zh: '司机姓名',
                      ),
                      suffixIcon: const Icon(Icons.badge_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverPin,
                    obscureText: _obscureNewDriverPin,
                    decoration: _fd(
                      _uiText(
                        en: 'Password',
                        ar: 'كلمة المرور',
                        fr: 'Mot de passe',
                        es: 'Contrasena',
                        de: 'Passwort',
                        it: 'Password',
                        ru: 'Пароль',
                        zh: '密码',
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureNewDriverPin = !_obscureNewDriverPin,
                        ),
                        icon: Icon(
                          _obscureNewDriverPin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverCarModel,
                    decoration: _fd(
                      _uiText(
                        en: 'Car model',
                        ar: 'طراز السيارة',
                        fr: 'Modele de voiture',
                        es: 'Modelo del auto',
                        de: 'Automodell',
                        it: 'Modello auto',
                        ru: 'Модель авто',
                        zh: '车辆型号',
                      ),
                      suffixIcon: const Icon(Icons.directions_car_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newDriverCarColor,
                    decoration: _fd(
                      _uiText(
                        en: 'Car color',
                        ar: 'لون السيارة',
                        fr: 'Couleur de la voiture',
                        es: 'Color del auto',
                        de: 'Autofarbe',
                        it: 'Colore auto',
                        ru: 'Цвет авто',
                        zh: '车辆颜色',
                      ),
                      suffixIcon: const Icon(Icons.palette_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickNewDriverImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      _uiText(
                        en: 'Pick image from gallery',
                        ar: 'اختيار صورة من المعرض',
                        fr: 'Choisir une image depuis la galerie',
                        es: 'Elegir imagen de la galeria',
                        de: 'Bild aus Galerie waehlen',
                        it: 'Scegli immagine dalla galleria',
                        ru: 'Выбрать фото из галереи',
                        zh: '从图库选择图片',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), side: const BorderSide(color: _C.border)),
                  ),
                  if (_newDriverPhotoData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final provider = _imageProviderFromString(_newDriverPhotoData);
                        if (provider == null) return const SizedBox.shrink();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: provider,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.yellow,
                        foregroundColor: _C.charcoal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _busy ? null : _createDriverAccount,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        _uiText(
                          en: 'Create driver login account',
                          ar: 'إنشاء حساب سائق',
                          fr: 'Creer un compte chauffeur',
                          es: 'Crear cuenta de conductor',
                          de: 'Fahrerkonto erstellen',
                          it: 'Crea account autista',
                          ru: 'Создать аккаунт водителя',
                          zh: '创建司机账户',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('${l.roleDriver} (${_managedDriverUsers.length})', subtitle: 'Managed driver accounts'),
              if (_managedDriverUsers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_taxi_outlined,
                          size: 44,
                          color: _C.textSoft.withValues(alpha: 0.65),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l.operatorFillDriverFields,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _C.textSoft,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._managedDriverUsers.take(80).map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _C.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Expanded(child: Text('${d['display_name'] ?? '-'}\n${d['email'] ?? ''}\n${d['phone'] ?? ''}', style: const TextStyle(fontSize: 12))),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => _editManagedDriver(d),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(onPressed: _busy ? null : () => _deleteManagedDriver(d), icon: const Icon(Icons.delete_outline, color: _C.danger)),
                  ]),
                )),
            ]),
          ),
          const SizedBox(height: 4),
          _Module(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(
                _uiText(
                  en: 'Driver ratings',
                  ar: 'تقييمات السائقين',
                  fr: 'Notes des chauffeurs',
                  es: 'Calificaciones de conductores',
                  de: 'Fahrerbewertungen',
                  it: 'Valutazioni autisti',
                  ru: 'Рейтинг водителей',
                  zh: '司机评分',
                ),
                subtitle: '${visibleRatings.length} profiles',
              ),
              if (visibleRatings.isEmpty)
                Text(
                  _uiText(
                    en: 'No ratings yet',
                    ar: 'لا توجد تقييمات بعد',
                    fr: 'Pas encore de notes',
                    es: 'Aun no hay calificaciones',
                    de: 'Noch keine Bewertungen',
                    it: 'Nessuna valutazione ancora',
                    ru: 'Пока нет оценок',
                    zh: '暂无评分',
                  ),
                )
              else
                ...visibleRatings.take(60).map((row) {
                  final managed = _findManagedDriverForRow(
                    name: (row['driver_name'] ?? '').toString(),
                    phone: (row['phone'] ?? '').toString(),
                  );
                  return Container(
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
                    if (managed != null)
                      IconButton(onPressed: _busy ? null : () => _deleteManagedDriver(managed), icon: const Icon(Icons.delete_outline, color: _C.danger)),
                  ]),
                );
                }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead(l.operatorTripVaultHeading, subtitle: '${_trips.length} trips'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _kpiChip(icon: Icons.list_alt, label: l.operatorTripVaultTripsChip(_trips.length)),
            _kpiChip(icon: Icons.payments, label: l.operatorTripVaultRevenueChip(_tripVaultRevenue.toStringAsFixed(3))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.charcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.loginLoadTrips),
          ),
        ),
        const SizedBox(height: 8),
        _Module(
          child: _trips.isEmpty
              ? Text(l.noTripsLoaded, style: const TextStyle(color: _C.textSoft))
              : Column(
                  children: _trips
                      .map(
                        (t) => _rowInfoCard(
                          icon: Icons.receipt_long_rounded,
                          iconBg: _C.charcoal,
                          iconColor: _C.yellow,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t['route']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.operatorTripSubtitle(
                                  t['date'] as String,
                                  t['fare'].toString(),
                                ),
                                style: const TextStyle(color: _C.textSoft, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;
    final isPhone = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _uiText(
            en: 'Operator Control',
            ar: 'لوحة المشغل',
            fr: 'Controle operateur',
            es: 'Control operador',
            de: 'Operator-Zentrale',
            it: 'Controllo operatore',
            ru: 'Панель оператора',
            zh: '运营控制台',
          ),
          style: const TextStyle(color: _C.yellow, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: _C.charcoal,
        foregroundColor: Colors.white,
        actions: [
          LocalePopupMenuButton(authToken: _token, uiRole: AppUiRole.operator),
          if (_token != null)
            IconButton(
              onPressed: _editMyAccount,
              tooltip: 'My account',
              icon: const Icon(Icons.manage_accounts_rounded),
            ),
          if (_token != null)
            IconButton(
              onPressed: () => unawaited(_logout()),
              tooltip: l.logoutApp,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: _token == null
          ? ListView(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              children: [
                _Module(
                  accent: true,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uiText(
                            en: 'Employee password:',
                            ar: 'كلمة مرور الموظف:',
                            fr: 'Mot de passe employe :',
                            es: 'Contrasena del empleado:',
                            de: 'Mitarbeiterpasswort:',
                            it: 'Password dipendente:',
                            ru: 'Пароль сотрудника:',
                            zh: '员工密码：',
                          ),
                          style: _operatorHeadingTextStyle(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _secretController,
                          obscureText: _obscureOperatorPassword,
                          decoration: _fd(
                            _uiText(
                              en: 'Operator code',
                              ar: 'رمز الموظف',
                              fr: 'Code operateur',
                              es: 'Codigo de operador',
                              de: 'Operator-Code',
                              it: 'Codice operatore',
                              ru: 'Код оператора',
                              zh: '调度员代码',
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureOperatorPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() {
                                _obscureOperatorPassword = !_obscureOperatorPassword;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _C.yellow,
                              foregroundColor: _C.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy ? null : _login,
                            child: Text(
                              _uiText(
                                en: 'Login & load trips',
                                ar: 'دخول وتحميل الرحلات',
                                fr: 'Connexion et chargement des courses',
                                es: 'Entrar y cargar viajes',
                                de: 'Anmelden & Fahrten laden',
                                it: 'Accedi e carica corse',
                                ru: 'Войти и загрузить поездки',
                                zh: '登录并加载行程',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(isPhone ? 12 : 16, 12, isPhone ? 12 : 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFC200), Color(0xFFFFD84D)]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.yellowDeep.withOpacity(0.55), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: _C.yellow.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: _C.charcoal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uiText(
                                en: 'Welcome to the operating room.',
                                ar: 'مرحبًا بك في غرفة العمليات.',
                                fr: 'Bienvenue dans la salle des operations.',
                                es: 'Bienvenido a la sala de operaciones.',
                                de: 'Willkommen im Betriebsraum.',
                                it: 'Benvenuto nella sala operativa.',
                                ru: 'Добро пожаловать в диспетчерскую.',
                                zh: '欢迎来到运营控制室。',
                              ),
                              style: const TextStyle(
                                color: _C.charcoal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _C.charcoal,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: tc,
                          isScrollable: true,
                          indicatorColor: _C.yellow,
                          indicatorWeight: 3,
                          labelColor: _C.yellow,
                          unselectedLabelColor: Colors.white38,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.3),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          tabs: [
                            Tab(
                              text: '✈️  ${_uiText(en: "Today's arrivals", ar: "وصولات اليوم", fr: "Arrivees du jour", es: "Llegadas de hoy", de: "Heutige Ankuenfte", it: "Arrivi di oggi", ru: "Прилеты сегодня", zh: "今日到达")}',
                            ),
                            Tab(
                              text: '💸 ${_uiText(en: "Live orders", ar: "طلبات مباشرة", fr: "Commandes en direct", es: "Pedidos en vivo", de: "Live-Auftraege", it: "Ordini live", ru: "Заказы онлайн", zh: "实时订单")}',
                            ),
                            Tab(
                              text: '👤 ${_uiText(en: "Driver management", ar: "إدارة السائقين", fr: "Gestion des chauffeurs", es: "Gestion de conductores", de: "Fahrerverwaltung", it: "Gestione autisti", ru: "Управление водителями", zh: "司机管理")}',
                            ),
                            Tab(
                              text: '🏨 ${_uiText(en: "Hostel Accounts (B2B)", ar: "حسابات الفنادق (B2B)", fr: "Comptes hôtels (B2B)", es: "Cuentas de hotel (B2B)", de: "Hotelkonten (B2B)", it: "Account hotel (B2B)", ru: "Аккаунты отелей (B2B)", zh: "酒店账户 (B2B)")}',
                            ),
                            Tab(
                              text: '🗒️ ${_uiText(en: "Trip history", ar: "سجل الرحلات", fr: "Historique des courses", es: "Historial de viajes", de: "Fahrtenverlauf", it: "Storico viaggi", ru: "История поездок", zh: "行程历史")}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tc,
                        children: [
                          _buildArrivalsTab(l),
                          _buildLiveOrdersTab(l),
                          _buildDriverManagementTab(l),
                          _buildB2bTab(l),
                          _buildTripHistoryTab(l),
                        ],
                      ),
                    ),
                    if (_message != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _C.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_message!, style: const TextStyle(color: _C.danger, fontSize: 13))),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
