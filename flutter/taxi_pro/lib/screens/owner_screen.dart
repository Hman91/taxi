// ═══════════════════════════════════════════════════════════════
// owner_screen.dart — TUNISIAN TAXI YELLOW THEME
// Refactored: owner/* widgets · lazy tab hydration · settings place search
// All original logic preserved — only UI/structure improved
// ═══════════════════════════════════════════════════════════════

import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
import '../widgets/locale_popup_menu.dart';
import '../widgets/live_ride_request_summary.dart';
import '../widgets/management_platform_ui.dart';
import '../widgets/todays_flight_arrivals_panel.dart';
import '../widgets/voom_logo.dart';
import 'unified_login_screen.dart';
import 'owner/owner_buttons.dart';
import 'owner/owner_colors.dart';
import 'owner/owner_field_decoration.dart';
import 'owner/owner_layout_widgets.dart';
import 'owner/owner_portal_nav.dart';
import 'owner/owner_settings_tab.dart';

const int _ownerInitialRideRows = 18;
const int _ownerInitialB2bBookingRows = 18;
const int _ownerInitialB2bAccountRows = 16;
const int _ownerListPageStep = 18;
const int _ownerAdminRideLimit = 80;
const int _ownerB2bBookingLimit = 80;
const int _ownerAdminUserLimit = 140;
const int _ownerPendingUserLimit = 80;

Color _ownerRideStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
    case 'scheduled':
    case 'requested':
    case 'pending':
      return OwnerColors.yellowDeep;
    case 'ongoing':
    case 'in_progress':
      return OwnerColors.info;
    case 'completed':
    case 'done':
      return OwnerColors.success;
    case 'refused':
    case 'rejected':
    case 'cancelled':
    case 'canceled':
      return OwnerColors.danger;
    default:
      return OwnerColors.textSoft;
  }
}

IconData _ownerRideStatusIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
    case 'scheduled':
    case 'requested':
      return Icons.verified_rounded;
    case 'pending':
      return Icons.hourglass_top_rounded;
    case 'ongoing':
    case 'in_progress':
      return Icons.route_rounded;
    case 'completed':
    case 'done':
      return Icons.check_circle_rounded;
    case 'refused':
    case 'rejected':
    case 'cancelled':
    case 'canceled':
      return Icons.block_rounded;
    default:
      return Icons.radio_button_checked_rounded;
  }
}

// ── B2B Tenant card ───────────────────────────────────────────
class _B2bCard extends StatelessWidget {
  const _B2bCard(
      {required this.tenant,
      required this.onEdit,
      required this.onToggle,
      required this.busy,
      required this.uiText});
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
        color: OwnerColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: enabled ? OwnerColors.yellowDeep.withOpacity(0.5) : OwnerColors.border),
        boxShadow: [
          BoxShadow(
              color: OwnerColors.charcoal.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? OwnerColors.yellowSoft : OwnerColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: enabled ? OwnerColors.yellowDeep : OwnerColors.border),
              ),
              child: Icon(Icons.hotel_rounded,
                  color: enabled ? OwnerColors.charcoal : OwnerColors.textSoft, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: OwnerColors.textStrong))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: enabled ? OwnerColors.successBg : OwnerColors.dangerBg,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(enabled ? 'Active' : 'Paused',
                          style: TextStyle(
                              color: enabled ? OwnerColors.success : OwnerColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  if (hotel.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: OwnerColors.textSoft),
                      const SizedBox(width: 3),
                      Text(hotel,
                          style: const TextStyle(
                              color: OwnerColors.textSoft, fontSize: 12)),
                    ]),
                ])),
          ]),
          const SizedBox(height: 12),
          // Details grid
          Wrap(spacing: 8, runSpacing: 6, children: [
            _infoTag(Icons.tag_rounded, 'Code: $code'),
            _infoTag(Icons.person_outline_rounded,
                name.isEmpty ? 'No contact' : name),
            _infoTag(Icons.phone_outlined, phone.isEmpty ? 'No phone' : phone),
            _infoTag(Icons.account_balance_wallet_outlined, '$wallet DT'),
            _infoTag(Icons.pin_outlined, pin.isEmpty ? 'No PIN' : '••••'),
          ]),
          const SizedBox(height: 12),
          // Actions
          Row(children: [
            Expanded(
                child: OwnerDarkButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: busy ? null : onEdit,
                    small: true)),
            const SizedBox(width: 8),
            Expanded(
                child: GestureDetector(
              onTap: busy ? null : onToggle,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: enabled ? OwnerColors.dangerBg : OwnerColors.successBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: enabled
                          ? OwnerColors.danger.withOpacity(0.3)
                          : OwnerColors.success.withOpacity(0.3)),
                ),
                child: Center(
                    child: Text(enabled ? 'Pause' : 'Activate',
                        style: TextStyle(
                            color: enabled ? OwnerColors.danger : OwnerColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) => ManagementStatusPill(
        label: text,
        color: OwnerColors.textMid,
        background: OwnerColors.surfaceAlt,
      );
}

// ── Driver wallet card ────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  const _DriverCard(
      {required this.driver,
      required this.onEdit,
      required this.busy,
      required this.subtitle,
      this.onDelete});
  final Map<String, dynamic> driver;
  final VoidCallback onEdit;
  final bool busy;
  final String subtitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = driver['driver_name']?.toString() ?? '';
    final wallet = (driver['wallet_balance'] ?? 0);
    final autoDeduct = driver['auto_deduct_enabled'] == true;

    return ManagementModuleCard(
      padding: 14,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: OwnerColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.border)),
              child: const Icon(Icons.local_taxi_outlined,
                  color: OwnerColors.charcoal, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: OwnerColors.textStrong)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                        color: OwnerColors.yellowSoft,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: OwnerColors.yellowDeep)),
                    child: Text('$wallet DT',
                        style: const TextStyle(
                            color: OwnerColors.charcoal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  if (autoDeduct)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: OwnerColors.successBg,
                          borderRadius: BorderRadius.circular(50)),
                      child: const Text('Auto-deduct',
                          style: TextStyle(
                              color: OwnerColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
              ])),
          IconButton(
            onPressed: busy ? null : onEdit,
            icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: OwnerColors.charcoal, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 15)),
            padding: EdgeInsets.zero,
          ),
          if (onDelete != null)
            IconButton(
              onPressed: busy ? null : onDelete,
              icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: OwnerColors.danger, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 15)),
              padding: EdgeInsets.zero,
            ),
        ]),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: OwnerColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
            child: Text(subtitle,
                style: const TextStyle(
                    color: OwnerColors.textMid, fontSize: 11, height: 1.4)),
          ),
        ],
      ]),
    );
  }
}

class _OwnerRideCard extends StatelessWidget {
  const _OwnerRideCard({
    required this.ride,
    required this.route,
    required this.status,
    required this.statusLabel,
    required this.isB2b,
    required this.distance,
    required this.price,
    required this.timeLabel,
    required this.passengerSectionTitle,
    required this.b2bSectionTitle,
    required this.driverSectionTitle,
  });

  final Map<String, dynamic> ride;
  final String route;
  final String status;
  final String statusLabel;
  final bool isB2b;
  final String distance;
  final String price;
  final String timeLabel;
  final String passengerSectionTitle;
  final String b2bSectionTitle;
  final String driverSectionTitle;

  @override
  Widget build(BuildContext context) {
    final color = _ownerRideStatusColor(status);
    return RepaintBoundary(
      child: ManagementModuleCard(
        padding: 14,
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.16), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.20)),
              ),
              child: Icon(_ownerRideStatusIcon(status), color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ManagementStatusPill(
                        label: statusLabel,
                        color: color,
                        background: color.withOpacity(0.10),
                      ),
                      ManagementStatusPill(
                        label: isB2b ? 'B2B' : passengerSectionTitle,
                        color: isB2b ? OwnerColors.info : OwnerColors.charcoal,
                        background: isB2b ? OwnerColors.infoBg : OwnerColors.yellowSoft,
                      ),
                    ],
                  ),
                  if (route.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      route,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OwnerColors.textSoft,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
          LiveRideRequestSummary(
            ride: ride,
            distanceLabel: distance,
            priceLabel: price,
            timeLabel: timeLabel.isEmpty ? '—' : timeLabel,
            labelColor: OwnerColors.textSoft,
            valueColor: OwnerColors.textStrong,
            borderColor: OwnerColors.border,
            sectionBg: OwnerColors.surfaceAlt.withOpacity(0.55),
            passengerSectionTitle: passengerSectionTitle,
            b2bSectionTitle: b2bSectionTitle,
            driverLabel: driverSectionTitle,
          ),
        ]),
      ),
    );
  }
}

class _B2bBookingCard extends StatelessWidget {
  const _B2bBookingCard({
    required this.route,
    required this.guestName,
    required this.room,
    required this.fare,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.sourceCode,
  });

  final String route;
  final String guestName;
  final String room;
  final String fare;
  final String status;
  final String statusLabel;
  final String createdAt;
  final String sourceCode;

  @override
  Widget build(BuildContext context) {
    final color = _ownerRideStatusColor(status);
    return RepaintBoundary(
      child: ManagementInfoRowCard(
        icon: Icons.hotel_rounded,
        iconBg: color.withOpacity(0.12),
        iconColor: color,
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: OwnerColors.textStrong,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ManagementStatusPill(
              label: statusLabel,
              color: color,
              background: color.withOpacity(0.10),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ManagementStatusPill(
              label: guestName.isEmpty ? '-' : guestName,
              color: OwnerColors.charcoal,
              background: OwnerColors.yellowSoft,
            ),
            ManagementStatusPill(
              label: 'Room ${room.isEmpty ? '-' : room}',
              color: OwnerColors.textMid,
              background: OwnerColors.surfaceAlt,
            ),
            ManagementStatusPill(
              label: '$fare DT',
              color: OwnerColors.success,
              background: OwnerColors.successBg,
            ),
            if (sourceCode.isNotEmpty)
              ManagementStatusPill(
                label: sourceCode,
                color: OwnerColors.info,
                background: OwnerColors.infoBg,
              ),
            if (createdAt.isNotEmpty)
              ManagementStatusPill(
                label: createdAt,
                color: OwnerColors.textSoft,
                background: OwnerColors.surfaceAlt,
              ),
          ]),
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

class _OwnerScreenState extends State<OwnerScreen>
    with SingleTickerProviderStateMixin {
  // ALL ORIGINAL FIELDS (unchanged)
  final _api = TaxiAppService();
  final _imagePicker = ImagePicker();
  final _secretController = TextEditingController(text: 'NabeulGold2026');
  final _newDriverPhone = TextEditingController();
  final _newDriverName = TextEditingController();
  final _newDriverEmail = TextEditingController();
  final _newDriverPin = TextEditingController();
  final _newDriverCarModel = TextEditingController();
  final _newDriverCarColor = TextEditingController();
  String _newDriverPhotoData = '';
  final _topUpAmountController = TextEditingController(text: '10');
  int? _topUpAccountId;
  TabController? _tabController;
  bool _obscurePassword = true;
  bool _obscureNewDriverPin = true;
  String? _token;
  String? _message;
  bool _busy = false;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  String? _flightDataSource;
  List<Map<String, dynamic>> _fareRoutes = [];
  List<Map<String, dynamic>> _driverWalletBreakdown = [];
  List<Map<String, dynamic>> _driverRatings = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _managedDriverUsers = [];
  List<Map<String, dynamic>> _managedB2bUsers = [];
  String _rideStatusFilter = 'all';
  String _b2bApprovalFilter = 'all';
  String _b2bBookingStatusFilter = 'all';
  int _visibleRideRows = _ownerInitialRideRows;
  int _visibleB2bBookingRows = _ownerInitialB2bBookingRows;
  int _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
  int _visibleWalletRows = _ownerListPageStep;
  int _visibleRatingRows = _ownerListPageStep;
  int _visibleManagedDriverRows = _ownerListPageStep;
  bool _refreshingOwnerData = false;
  final Map<int, TextEditingController> _fareCtrls = {};
  double _commissionDemoPercent = 10.0;
  final Set<int> _ownerTabsHydrated = {};
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
              TextField(
                  controller: emailCtrl,
                  decoration:
                      ownerFieldDecoration('New email (optional)', icon: Icons.email_outlined)),
              const SizedBox(height: 8),
              TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: ownerFieldDecoration('New password (optional)',
                      icon: Icons.lock_outline_rounded)),
              const SizedBox(height: 8),
              TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  decoration:
                      ownerFieldDecoration('Current password', icon: Icons.password_rounded)),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
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
                          email: emailCtrl.text.trim().isEmpty
                              ? null
                              : emailCtrl.text.trim(),
                          password: newPasswordCtrl.text.trim().isEmpty
                              ? null
                              : newPasswordCtrl.text,
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

  // ALL ORIGINAL LOGIC (unchanged)
  void _syncFareControllers(List<Map<String, dynamic>> routes) {
    final ids = <int>{};
    for (final r in routes) {
      final idRaw = r['id'];
      if (idRaw is! num) continue;
      final id = idRaw.toInt();
      ids.add(id);
      final bf = r['base_fare'];
      final text = bf is num ? bf.toStringAsFixed(2) : bf?.toString() ?? '0.00';
      if (_fareCtrls.containsKey(id)) {
        _fareCtrls[id]!.text = text;
      } else {
        _fareCtrls[id] = TextEditingController(text: text);
      }
    }
    for (final k in _fareCtrls.keys.toList()) {
      if (!ids.contains(k)) _fareCtrls.remove(k)?.dispose();
    }
  }

  void _onOwnerTabChanged() {
    final c = _tabController;
    if (c == null || c.indexIsChanging) return;
    unawaited(_ensureOwnerTabHydrated(c.index));
  }

  Future<void> _ensureOwnerTabHydrated(int tab) async {
    if (_token == null || _ownerTabsHydrated.contains(tab)) return;
    final ok = await _loadOwnerTabData(tab);
    if (mounted && ok) setState(() => _ownerTabsHydrated.add(tab));
  }

  void _applyManagedUsersFromAppUsers(List<Map<String, dynamic>> appUsers) {
    final appDriverUsers = appUsers
        .where((u) => (u['role'] ?? '') == 'driver')
        .where(_isRealManagedDriver)
        .map((u) => {...u, 'source': 'app_user'})
        .toList();
    _managedDriverUsers = appDriverUsers;
    _managedB2bUsers = appUsers.where((u) => (u['role'] ?? '') == 'b2b').toList();
  }

  void _syncTopUpAccountFromWallets(List<Map<String, dynamic>> driverWallets) {
    final ids = driverWallets
        .map((e) => (e['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
    if (_topUpAccountId != null && !ids.contains(_topUpAccountId)) {
      _topUpAccountId = null;
    }
    _topUpAccountId ??= ids.isEmpty ? null : ids.first;
  }

  /// Loads server data for a single Owner tab (lazy). Returns false on hard failure.
  Future<bool> _loadOwnerTabData(int tab) async {
    final t = _token;
    if (t == null) return false;
    Future<T?> safe<T>(Future<T> r) async {
      try {
        return await r;
      } catch (_) {
        return null;
      }
    }
    if (mounted) setState(() => _busy = true);
    var ok = true;
    try {
      switch (tab) {
        case 0:
          if (mounted) setState(() => _message = null);
          break;
        case 1:
          final rides =
              await safe(_api.listAdminRides(t, limit: _ownerAdminRideLimit));
          if (!mounted) return false;
          if (rides == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _adminRides = rides;
            _visibleRideRows = _ownerInitialRideRows;
            _message = null;
          });
          break;
        case 2:
          final pendingApprovalsFuture =
              safe(_api.listAdminPendingUsers(t, limit: _ownerPendingUserLimit));
          final appUsersFuture =
              safe(_api.listAdminUsers(t, limit: _ownerAdminUserLimit));
          final driverWalletsFuture =
              safe(_api.listAdminDriverWalletBreakdown(t));
          await Future.wait(
              [pendingApprovalsFuture, appUsersFuture, driverWalletsFuture]);
          final pendingApprovals = await pendingApprovalsFuture;
          final appUsers = await appUsersFuture;
          final driverWallets = await driverWalletsFuture;
          if (!mounted) return false;
          if (pendingApprovals == null ||
              appUsers == null ||
              driverWallets == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _pendingApprovals = pendingApprovals;
            _applyManagedUsersFromAppUsers(appUsers);
            _driverWalletBreakdown = driverWallets;
            _syncTopUpAccountFromWallets(driverWallets);
            _visibleManagedDriverRows = _ownerListPageStep;
            _message = null;
          });
          break;
        case 3:
          final driverWalletsFuture =
              safe(_api.listAdminDriverWalletBreakdown(t));
          final appUsersFuture =
              safe(_api.listAdminUsers(t, limit: _ownerAdminUserLimit));
          await Future.wait([driverWalletsFuture, appUsersFuture]);
          final driverWallets = await driverWalletsFuture;
          final appUsers = await appUsersFuture;
          if (!mounted) return false;
          if (driverWallets == null || appUsers == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _driverWalletBreakdown = driverWallets;
            _applyManagedUsersFromAppUsers(appUsers);
            _syncTopUpAccountFromWallets(driverWallets);
            _visibleWalletRows = _ownerListPageStep;
            _message = null;
          });
          break;
        case 4:
          final ratingsFuture = safe(_api.listAdminDriverRatings(t));
          final appUsersFuture =
              safe(_api.listAdminUsers(t, limit: _ownerAdminUserLimit));
          await Future.wait([ratingsFuture, appUsersFuture]);
          final ratings = await ratingsFuture;
          final appUsers = await appUsersFuture;
          if (!mounted) return false;
          if (ratings == null || appUsers == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _driverRatings = ratings;
            _applyManagedUsersFromAppUsers(appUsers);
            _visibleRatingRows = _ownerListPageStep;
            _message = null;
          });
          break;
        case 5:
          final tripsFuture = safe(_api.listTrips(t));
          final trips = await tripsFuture;
          if (!mounted) return false;
          if (trips == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _trips = trips
                .map((e) => {
                      'id': e.id,
                      'date': e.date,
                      'route': e.route,
                      'fare': e.fare,
                      'commission': e.commission,
                      'type': e.type
                    })
                .toList();
            _message = null;
          });
          break;
        case 6:
          final fareRoutes = await safe(_api.listAdminFareRoutes(t));
          if (!mounted) return false;
          if (fareRoutes == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _fareRoutes = fareRoutes;
            _syncFareControllers(fareRoutes);
            _message = null;
          });
          break;
        case 7:
          final fr = await safe(_api.listAdminTunisiaFlightArrivals(t));
          if (!mounted) return false;
          if (fr == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _flightArrivals = fr.flights;
            _flightDataSource = fr.source;
            _message = null;
          });
          break;
        case 8:
          final adminB2bFuture = safe(_api.listAdminB2bTenants(t));
          final adminB2bBookingsFuture =
              safe(_api.listAdminB2bBookings(t, limit: _ownerB2bBookingLimit));
          final appUsersFuture =
              safe(_api.listAdminUsers(t, limit: _ownerAdminUserLimit));
          await Future.wait(
              [adminB2bFuture, adminB2bBookingsFuture, appUsersFuture]);
          final adminB2b = await adminB2bFuture;
          final adminB2bBookings = await adminB2bBookingsFuture;
          final appUsers = await appUsersFuture;
          if (!mounted) return false;
          if (adminB2b == null ||
              adminB2bBookings == null ||
              appUsers == null) {
            setState(() => _message =
                'Cannot reach API server. Check backend IP/network.');
            ok = false;
            break;
          }
          setState(() {
            _adminB2b = adminB2b;
            _adminB2bBookings = adminB2bBookings;
            _visibleB2bBookingRows = _ownerInitialB2bBookingRows;
            _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
            _applyManagedUsersFromAppUsers(appUsers);
            _message = null;
          });
          break;
        default:
          ok = false;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return ok;
  }

  Future<void> _refreshOwnerSettingsData() async {
    final t = _token;
    if (t == null) return;
    try {
      final routes = await _api.listAdminFareRoutes(t);
      if (!mounted) return;
      setState(() {
        _fareRoutes = routes;
        _syncFareControllers(routes);
      });
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    }
  }

  String _ownerDriverPinSubtitle(AppLocalizations l, Map<String, dynamic> d) {
    final walletS = (d['wallet_balance'] ?? 0).toString();
    final ownerS = (d['owner_commission_rate'] ?? 10).toString();
    final b2bS = (d['b2b_commission_rate'] ?? 5).toString();
    var line = l.operatorDriverWalletLine(walletS, ownerS, b2bS);
    final model = (d['car_model'] ?? '').toString().trim();
    final color = (d['car_color'] ?? '').toString().trim();
    if (model.isNotEmpty) line += l.operatorDriverCarLine(model);
    if (color.isNotEmpty) line += l.operatorDriverCarColorAppend(color);
    line +=
        '\n${_uiText(en: 'Simple rides income', ar: 'مداخيل الرحلات العادية', fr: 'Revenus des courses simples', es: 'Ingresos de viajes simples', de: 'Einnahmen aus einfachen Fahrten', it: 'Entrate corse semplici', ru: 'Доход с обычных поездок', zh: '普通行程收入')}: ${(d['gross_normal'] ?? 0).toString()} DT';
    line +=
        ' | ${_uiText(en: 'B2B rides income', ar: 'مداخيل رحلات B2B', fr: 'Revenus des courses B2B', es: 'Ingresos de viajes B2B', de: 'Einnahmen aus B2B-Fahrten', it: 'Entrate corse B2B', ru: 'Доход с B2B поездок', zh: 'B2B行程收入')}: ${(d['gross_b2b'] ?? 0).toString()} DT';
    line +=
        '\n${_uiText(en: 'Deducted from simple rides', ar: 'المخصوم من الرحلات العادية', fr: 'Retenu des courses simples', es: 'Descontado de viajes simples', de: 'Abzug aus einfachen Fahrten', it: 'Detratto da corse semplici', ru: 'Удержано с обычных поездок', zh: '普通行程扣除')}: ${(d['deducted_normal'] ?? 0).toString()} DT';
    line +=
        ' | ${_uiText(en: 'Deducted from B2B rides', ar: 'المخصوم من رحلات B2B', fr: 'Retenu des courses B2B', es: 'Descontado de viajes B2B', de: 'Abzug aus B2B-Fahrten', it: 'Detratto da corse B2B', ru: 'Удержано с B2B поездок', zh: 'B2B行程扣除')}: ${(d['deducted_b2b'] ?? 0).toString()} DT';
    return line;
  }

  String _uiText(
      {required String en,
      required String ar,
      required String fr,
      required String es,
      required String de,
      required String it,
      required String ru,
      required String zh}) {
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
    final q = r['quoted_distance_km'];
    if (q is num) return q.toDouble();
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
    final b2b = r['b2b_fare'];
    if (b2b is num) return '${b2b.toStringAsFixed(2)} DT';
    final quoted = r['quoted_fare_dt'];
    if (quoted is num) return '${quoted.toStringAsFixed(2)} DT';
    final f = r['fare'];
    if (f is num) return '${f.toStringAsFixed(2)} DT';
    return '-';
  }

  String _requestLiveTime(Map<String, dynamic> r) {
    final sched = (r['scheduled_pickup_at'] ?? '').toString().trim();
    if (sched.isNotEmpty) return sched;
    return (r['created_at'] ?? '').toString().trim();
  }

  String _rideStatusBucket(String raw) {
    final status = raw.trim().toLowerCase();
    if (status == 'completed' || status == 'done') return 'completed';
    if (status == 'ongoing' || status == 'in_progress') return 'ongoing';
    if (status == 'refused' ||
        status == 'rejected' ||
        status == 'cancelled' ||
        status == 'canceled') {
      return 'refused';
    }
    return 'accepted';
  }

  String _ownerRideStatusLabel(AppLocalizations l, String raw) {
    final bucket = _rideStatusBucket(raw);
    if (bucket == 'completed') return localizedRideStatusLabel(l, 'completed');
    if (bucket == 'ongoing') return localizedRideStatusLabel(l, 'ongoing');
    if (bucket == 'refused') {
      return _uiText(
          en: 'Refused',
          ar: 'مرفوض',
          fr: 'Refuse',
          es: 'Rechazado',
          de: 'Abgelehnt',
          it: 'Rifiutato',
          ru: 'Отклонено',
          zh: '已拒绝');
    }
    return _uiText(
        en: 'Accepted',
        ar: 'مقبول',
        fr: 'Accepte',
        es: 'Aceptado',
        de: 'Akzeptiert',
        it: 'Accettato',
        ru: 'Принято',
        zh: '已接受');
  }

  bool _matchesRideFilter(Map<String, dynamic> row) {
    if (_rideStatusFilter == 'all') return true;
    return _rideStatusBucket((row['status'] ?? '').toString()) ==
        _rideStatusFilter;
  }

  bool _matchesB2bBookingFilter(Map<String, dynamic> row) {
    if (_b2bBookingStatusFilter == 'all') return true;
    return _rideStatusBucket((row['status'] ?? '').toString()) ==
        _b2bBookingStatusFilter;
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

  Widget _b2bFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _busy ? null : (_) => onTap(),
      selectedColor: OwnerColors.yellowSoft,
      backgroundColor: OwnerColors.surface,
      side: BorderSide(color: selected ? OwnerColors.yellowDeep : OwnerColors.border),
      labelStyle: TextStyle(
        color: selected ? OwnerColors.charcoal : OwnerColors.textStrong,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _bookingStatusChip({
    required String label,
    required String status,
    required int count,
  }) {
    final selected = _b2bBookingStatusFilter == status;
    final color = status == 'all' ? OwnerColors.charcoal : _ownerRideStatusColor(status);
    return ChoiceChip(
      label: Text('$label · $count'),
      selected: selected,
      onSelected: _busy
          ? null
          : (_) => setState(() {
                _b2bBookingStatusFilter = status;
                _visibleB2bBookingRows = _ownerInitialB2bBookingRows;
              }),
      selectedColor: color.withOpacity(0.14),
      backgroundColor: OwnerColors.surface,
      side: BorderSide(color: selected ? color : OwnerColors.border),
      labelStyle: TextStyle(
        color: selected ? color : OwnerColors.textStrong,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _b2bApprovalChip(String status) {
    final approved = status == 'approved';
    final pending = status == 'pending';
    final bg = approved
        ? const Color(0xFFD4EDDA)
        : (pending ? const Color(0xFFFFF3CD) : const Color(0xFFF8D7DA));
    final fg = approved
        ? const Color(0xFF155724)
        : (pending ? const Color(0xFF856404) : const Color(0xFF721C24));
    final label = approved
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
        : (pending
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
    return ManagementStatusPill(label: label, color: fg, background: bg);
  }

  Map<String, dynamic>? _findManagedDriverByWalletRow(
      Map<String, dynamic> row) {
    final phone = (row['phone'] ?? '').toString().trim();
    final name = (row['driver_name'] ?? '').toString().trim().toLowerCase();
    for (final u in _managedDriverUsers) {
      final up = (u['phone'] ?? '').toString().trim();
      final un = (u['display_name'] ?? '').toString().trim().toLowerCase();
      if (phone.isNotEmpty && up == phone) return u;
      if (name.isNotEmpty && un == name) return u;
    }
    return null;
  }

  bool _isWalletVisible(Map<String, dynamic> row) =>
      _findManagedDriverByWalletRow(row) != null;

  bool _isSamiraOrSelima(Map<String, dynamic> row) {
    final name = (row['driver_name'] ?? row['display_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final email = (row['email'] ?? '').toString().trim().toLowerCase();
    return name == 'samira' ||
        name == 'selima' ||
        email.startsWith('samira@') ||
        email.startsWith('selima@');
  }

  bool _isRatingVisible(Map<String, dynamic> row) {
    final phone = (row['phone'] ?? '').toString().trim();
    final name = (row['driver_name'] ?? '').toString().trim().toLowerCase();
    for (final u in _managedDriverUsers) {
      final up = (u['phone'] ?? '').toString().trim();
      final un = (u['display_name'] ?? '').toString().trim().toLowerCase();
      if (phone.isNotEmpty && up == phone) return true;
      if (name.isNotEmpty && un == name) return true;
    }
    return false;
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(
          role: 'owner', secret: _secretController.text.trim());
      if (userChoseLocaleThisSession.value) {
        try {
          await _api.patchPreferredLanguage(
            token: r.accessToken,
            preferredLanguage: appLocale.value.languageCode,
          );
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.owner);
      _token = r.accessToken;
      await SessionStore.saveOwnerToken(r.accessToken);
      _ownerTabsHydrated.clear();
      await _ensureOwnerTabHydrated(0);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshAll() async {
    final t = _token;
    if (t == null) return;
    if (_refreshingOwnerData) return;
    _ownerTabsHydrated.clear();
    _refreshingOwnerData = true;
    if (mounted) setState(() => _busy = true);
    try {
      Future<T?> safe<T>(Future<T> request) async {
        try {
          return await request;
        } catch (_) {
          return null;
        }
      }

      final tripsFuture = safe(_api.listTrips(t));
      final adminRidesFuture =
          safe(_api.listAdminRides(t, limit: _ownerAdminRideLimit));
      final adminB2bFuture = safe(_api.listAdminB2bTenants(t));
      final adminB2bBookingsFuture =
          safe(_api.listAdminB2bBookings(t, limit: _ownerB2bBookingLimit));
      final frFuture = safe(_api.listAdminTunisiaFlightArrivals(t));
      final fareRoutesFuture = safe(_api.listAdminFareRoutes(t));
      final driverWalletsFuture = safe(_api.listAdminDriverWalletBreakdown(t));
      final ratingsFuture = safe(_api.listAdminDriverRatings(t));
      final pendingApprovalsFuture =
          safe(_api.listAdminPendingUsers(t, limit: _ownerPendingUserLimit));
      final appUsersFuture =
          safe(_api.listAdminUsers(t, limit: _ownerAdminUserLimit));

      await Future.wait<Object?>([
        tripsFuture,
        adminRidesFuture,
        adminB2bFuture,
        adminB2bBookingsFuture,
        frFuture,
        fareRoutesFuture,
        driverWalletsFuture,
        ratingsFuture,
        pendingApprovalsFuture,
        appUsersFuture,
      ]);

      final trips = await tripsFuture;
      final adminRides = await adminRidesFuture;
      final adminB2b = await adminB2bFuture;
      final adminB2bBookings = await adminB2bBookingsFuture;
      final fr = await frFuture;
      final fareRoutes = await fareRoutesFuture;
      final driverWallets = await driverWalletsFuture;
      final ratings = await ratingsFuture;
      final pendingApprovals = await pendingApprovalsFuture;
      final appUsers = await appUsersFuture;

      if (trips == null ||
          adminRides == null ||
          adminB2b == null ||
          adminB2bBookings == null ||
          fr == null ||
          fareRoutes == null ||
          driverWallets == null ||
          ratings == null ||
          pendingApprovals == null ||
          appUsers == null) {
        setState(() =>
            _message = 'Cannot reach API server. Check backend IP/network.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _trips = trips
            .map((e) => {
                  'id': e.id,
                  'date': e.date,
                  'route': e.route,
                  'fare': e.fare,
                  'commission': e.commission,
                  'type': e.type
                })
            .toList();
        _adminRides = adminRides;
        _adminB2b = adminB2b;
        _adminB2bBookings = adminB2bBookings;
        _visibleRideRows = _ownerInitialRideRows;
        _visibleB2bBookingRows = _ownerInitialB2bBookingRows;
        _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
        _flightArrivals = fr.flights;
        _flightDataSource = fr.source;
        _fareRoutes = fareRoutes;
        _driverWalletBreakdown = driverWallets;
        _driverRatings = ratings;
        _pendingApprovals = pendingApprovals;
        _applyManagedUsersFromAppUsers(appUsers);
        _syncTopUpAccountFromWallets(driverWallets);
        _visibleWalletRows = _ownerListPageStep;
        _visibleRatingRows = _ownerListPageStep;
        _visibleManagedDriverRows = _ownerListPageStep;
        _syncFareControllers(fareRoutes);
        _message = null;
        _ownerTabsHydrated
          ..clear()
          ..addAll({0, 1, 2, 3, 4, 5, 6, 7, 8});
      });
    } catch (e) {
      final msg = e.toString();
      setState(() => _message = msg.contains('phone_exists_or_invalid')
          ? _uiText(
              en: 'Phone already exists or invalid.',
              ar: 'رقم الهاتف موجود مسبقا أو غير صالح.',
              fr: 'Le numero existe deja ou est invalide.',
              es: 'El telefono ya existe o no es valido.',
              de: 'Telefon existiert bereits oder ist ungueltig.',
              it: 'Il telefono esiste gia o non e valido.',
              ru: 'Телефон уже существует или недействителен.',
              zh: '电话号码已存在或无效。')
          : msg);
    } finally {
      _refreshingOwnerData = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFareRoute(int routeId) async {
    final t = _token;
    final ctrl = _fareCtrls[routeId];
    if (t == null || ctrl == null) return;
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0) {
      setState(() => _message = _uiText(
          en: 'Invalid fare',
          ar: 'تعرفة غير صالحة',
          fr: 'Tarif invalide',
          es: 'Tarifa invalida',
          de: 'Ungueltiger Fahrpreis',
          it: 'Tariffa non valida',
          ru: 'Неверный тариф',
          zh: '无效费用'));
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminFareRoute(token: t, routeId: routeId, baseFare: v);
      await _refreshOwnerSettingsData();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleB2b(Map<String, dynamic> tenant) async {
    final t = _token;
    if (t == null) return;
    final idRaw = tenant['id'];
    if (idRaw is! num) return;
    final current = (tenant['is_enabled'] == true);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.setAdminB2bEnabled(
          token: t, tenantId: idRaw.toInt(), isEnabled: !current);
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickNewDriverImage() async {
    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
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
    if (email.isEmpty ||
        phone.isEmpty ||
        name.isEmpty ||
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
        title: const Text('Delete account?'),
        content: Text(
            'This will permanently remove ${(row['display_name'] ?? row['email'] ?? 'this account').toString()}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: OwnerColors.danger),
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
    final emailCtrl =
        TextEditingController(text: (row['email'] ?? '').toString());
    final nameCtrl =
        TextEditingController(text: (row['display_name'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (row['phone'] ?? '').toString());
    final passCtrl = TextEditingController();
    final modelCtrl =
        TextEditingController(text: (row['car_model'] ?? '').toString());
    final colorCtrl =
        TextEditingController(text: (row['car_color'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Driver'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: emailCtrl,
                decoration: ownerFieldDecoration('Email', icon: Icons.email_outlined)),
            TextField(
              controller: passCtrl,
              decoration:
                  ownerFieldDecoration('Password (optional)', icon: Icons.lock_outline_rounded),
            ),
            TextField(
                controller: nameCtrl,
                decoration: ownerFieldDecoration('Name', icon: Icons.badge_outlined)),
            TextField(
                controller: phoneCtrl,
                decoration: ownerFieldDecoration('Phone', icon: Icons.phone_outlined)),
            TextField(
                controller: modelCtrl,
                decoration:
                    ownerFieldDecoration('Car type', icon: Icons.directions_car_outlined)),
            TextField(
                controller: colorCtrl,
                decoration: ownerFieldDecoration('Car color', icon: Icons.palette_outlined)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
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
    final emailCtrl =
        TextEditingController(text: (row['email'] ?? '').toString());
    final nameCtrl =
        TextEditingController(text: (row['display_name'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (row['phone'] ?? '').toString());
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit B2B Account'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: emailCtrl,
                decoration: ownerFieldDecoration('Email', icon: Icons.email_outlined)),
            TextField(
                controller: passCtrl,
                decoration: ownerFieldDecoration('Password (optional)',
                    icon: Icons.lock_outline_rounded)),
            TextField(
                controller: nameCtrl,
                decoration: ownerFieldDecoration('Name', icon: Icons.badge_outlined)),
            TextField(
                controller: phoneCtrl,
                decoration: ownerFieldDecoration('Phone', icon: Icons.phone_outlined)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
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
    if (id == null || id <= 0) {
      setState(() => _message = _uiText(
            en: 'This driver has no wallet account to edit.',
            ar: 'هذا السائق لا يملك حساب محفظة للتعديل.',
            fr: 'Ce chauffeur n’a pas de compte portefeuille a modifier.',
            es: 'Este conductor no tiene cuenta de cartera para editar.',
            de: 'Dieser Fahrer hat kein Wallet-Konto zum Bearbeiten.',
            it: 'Questo autista non ha un account wallet da modificare.',
            ru: 'У этого водителя нет кошелька для редактирования.',
            zh: '该司机没有可编辑的钱包账户。',
          ));
      return;
    }
    final walletCtrl =
        TextEditingController(text: (row['wallet_balance'] ?? 0).toString());
    final ownerRateCtrl = TextEditingController(
        text: (row['owner_commission_rate'] ?? 10).toString());
    final b2bRateCtrl = TextEditingController(
        text: (row['b2b_commission_rate'] ?? 5).toString());
    final modelCtrl =
        TextEditingController(text: row['car_model']?.toString() ?? '');
    final colorCtrl =
        TextEditingController(text: row['car_color']?.toString() ?? '');
    bool autoDeduct = row['auto_deduct_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: OwnerColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: OwnerColors.yellowSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OwnerColors.yellowDeep)),
                child: const Icon(Icons.local_taxi_outlined,
                    color: OwnerColors.charcoal, size: 18)),
            const SizedBox(width: 10),
            Expanded(
                child: Text((row['driver_name'] ?? 'Driver').toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            TextField(
                controller: walletCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: ownerFieldDecoration(
                    AppLocalizations.of(ctx)!.operatorWalletBalanceLabel,
                    icon: Icons.account_balance_wallet_outlined,
                    suffix: 'DT')),
            const SizedBox(height: 10),
            TextField(
                controller: ownerRateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: ownerFieldDecoration(
                    AppLocalizations.of(ctx)!.operatorOwnerCommissionLabel,
                    icon: Icons.percent_rounded,
                    suffix: '%')),
            const SizedBox(height: 10),
            TextField(
                controller: b2bRateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: ownerFieldDecoration(
                    AppLocalizations.of(ctx)!.operatorB2bCommissionLabel,
                    icon: Icons.business_center_outlined,
                    suffix: '%')),
            const SizedBox(height: 10),
            TextField(
                controller: modelCtrl,
                decoration: ownerFieldDecoration(AppLocalizations.of(ctx)!.operatorCarModelLabel,
                    icon: Icons.directions_car_outlined)),
            const SizedBox(height: 10),
            TextField(
                controller: colorCtrl,
                decoration: ownerFieldDecoration(AppLocalizations.of(ctx)!.operatorCarColorLabel,
                    icon: Icons.palette_outlined)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: OwnerColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.border)),
              child: SwitchListTile(
                dense: true,
                title: Text(AppLocalizations.of(ctx)!.operatorAutoDeductEnabled,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                value: autoDeduct,
                onChanged: (v) => setSt(() => autoDeduct = v),
                activeColor: OwnerColors.yellow,
              ),
            ),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('Cancel', style: TextStyle(color: OwnerColors.textMid))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.yellow,
                  foregroundColor: OwnerColors.charcoal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w800)),
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
        await _api
            .patchAdminDriverPinAccount(token: t, accountId: id, payload: {
          'wallet_balance':
              double.tryParse(walletCtrl.text.trim().replaceAll(',', '.')) ??
                  (row['wallet_balance'] as num?)?.toDouble() ??
                  0.0,
          'owner_commission_rate':
              double.tryParse(ownerRateCtrl.text.trim().replaceAll(',', '.')) ??
                  (row['owner_commission_rate'] as num?)?.toDouble() ??
                  10.0,
          'b2b_commission_rate':
              double.tryParse(b2bRateCtrl.text.trim().replaceAll(',', '.')) ??
                  (row['b2b_commission_rate'] as num?)?.toDouble() ??
                  5.0,
          'auto_deduct_enabled': autoDeduct,
          'car_model': modelCtrl.text.trim(),
          'car_color': colorCtrl.text.trim(),
        });
        await _refreshAll();
      } catch (e) {
        setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    walletCtrl.dispose();
    ownerRateCtrl.dispose();
    b2bRateCtrl.dispose();
    modelCtrl.dispose();
    colorCtrl.dispose();
  }

  Future<void> _rechargeDriverWallet() async {
    final t = _token;
    final id = _topUpAccountId;
    if (t == null || id == null) return;
    if (id <= 0) {
      setState(() => _message =
          'Recharge is only available for drivers with wallet accounts.');
      return;
    }
    final amount = double.tryParse(
            _topUpAmountController.text.trim().replaceAll(',', '.')) ??
        0.0;
    if (amount <= 0) {
      setState(() => _message = _uiText(
          en: 'Invalid recharge amount',
          ar: 'مبلغ الشحن غير صالح',
          fr: 'Montant de recharge invalide',
          es: 'Importe de recarga invalido',
          de: 'Ungueltiger Aufladebetrag',
          it: 'Importo ricarica non valido',
          ru: 'Неверная сумма пополнения',
          zh: '充值金额无效'));
      return;
    }
    int? _toIntId(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    final row = _driverWalletBreakdown.firstWhere(
        (e) => _toIntId(e['id']) == id,
        orElse: () => const <String, dynamic>{});
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
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminDriverPinAccount(
          token: t,
          accountId: id,
          payload: {'wallet_balance': current + amount});
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
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        backgroundColor: OwnerColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: OwnerColors.yellowSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OwnerColors.yellowDeep)),
              child: const Icon(Icons.add_business_rounded,
                  color: OwnerColors.charcoal, size: 18)),
          const SizedBox(width: 10),
          const Text('Create B2B Account',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          TextField(
              controller: hotelCtrl,
              decoration: ownerFieldDecoration('Hotel / Company', icon: Icons.hotel_rounded)),
          const SizedBox(height: 10),
          TextField(
              controller: emailCtrl,
              decoration: ownerFieldDecoration('Email', icon: Icons.email_outlined)),
          const SizedBox(height: 10),
          TextField(
              controller: nameCtrl,
              decoration:
                  ownerFieldDecoration('Contact Name', icon: Icons.person_outline_rounded)),
          const SizedBox(height: 10),
          TextField(
              controller: phoneCtrl,
              decoration: ownerFieldDecoration('Phone', icon: Icons.phone_outlined)),
          const SizedBox(height: 10),
          TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: ownerFieldDecoration('Password', icon: Icons.lock_outline_rounded)),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: OwnerColors.textMid))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.yellow,
                  foregroundColor: OwnerColors.charcoal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create',
                  style: TextStyle(fontWeight: FontWeight.w800))),
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
    final codeCtrl =
        TextEditingController(text: (row['code'] ?? '').toString());
    final labelCtrl =
        TextEditingController(text: (row['label'] ?? '').toString());
    final nameCtrl =
        TextEditingController(text: (row['contact_name'] ?? '').toString());
    final pinCtrl = TextEditingController(text: (row['pin'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (row['phone'] ?? '').toString());
    final hotelCtrl =
        TextEditingController(text: (row['hotel'] ?? '').toString());
    bool enabled = row['is_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: OwnerColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit B2B Account',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            TextField(
                controller: hotelCtrl,
                decoration: ownerFieldDecoration('Hotel / Company', icon: Icons.hotel_rounded)),
            const SizedBox(height: 10),
            TextField(
                controller: codeCtrl,
                decoration: ownerFieldDecoration('Code', icon: Icons.tag_rounded)),
            const SizedBox(height: 10),
            TextField(
                controller: labelCtrl,
                decoration: ownerFieldDecoration('Label', icon: Icons.label_outline_rounded)),
            const SizedBox(height: 10),
            TextField(
                controller: nameCtrl,
                decoration:
                    ownerFieldDecoration('Contact Name', icon: Icons.person_outline_rounded)),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                decoration: ownerFieldDecoration('Phone', icon: Icons.phone_outlined)),
            const SizedBox(height: 10),
            TextField(
                controller: pinCtrl,
                obscureText: true,
                decoration: ownerFieldDecoration('PIN', icon: Icons.pin_outlined)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: OwnerColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.border)),
              child: SwitchListTile(
                  dense: true,
                  title: const Text('Active',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: enabled,
                  onChanged: (v) => setSt(() => enabled = v),
                  activeColor: OwnerColors.yellow),
            ),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('Cancel', style: TextStyle(color: OwnerColors.textMid))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: OwnerColors.yellow,
                    foregroundColor: OwnerColors.charcoal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    elevation: 0),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w800))),
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
        await _api.patchAdminB2bTenant(token: t, tenantId: id, payload: {
          'code': codeCtrl.text.trim(),
          'label': labelCtrl.text.trim(),
          'contact_name': nameCtrl.text.trim(),
          'pin': pinCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'hotel': hotelCtrl.text.trim(),
          'is_enabled': enabled
        });
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

  // ══ TAB BUILDERS ══════════════════════════════════════════

  void _jumpOwnerTab(int index) {
    final c = _tabController;
    if (c == null || index < 0 || index >= c.length) return;
    c.animateTo(index);
  }

  Widget _ownerNavQuickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int tabIndex,
    required List<Color> gradient,
  }) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _jumpOwnerTab(tabIndex),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(
                  color: OwnerColors.charcoal.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: OwnerColors.charcoal.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: OwnerColors.charcoal.withValues(alpha: 0.06)),
                    ),
                    child: Icon(icon, color: OwnerColors.charcoal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: OwnerColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: OwnerColors.charcoal.withValues(alpha: 0.52),
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: OwnerColors.charcoal.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final cross = wide ? 2 : 1;
          final tiles = <Widget>[
            _ownerNavQuickTile(
              icon: Icons.bolt_rounded,
              title: _uiText(
                en: 'Live operations',
                ar: 'العمليات المباشرة',
                fr: 'Operations live',
                es: 'Operaciones en vivo',
                de: 'Live-Betrieb',
                it: 'Operazioni live',
                ru: 'Онлайн-операции',
                zh: '实时运营',
              ),
              subtitle: _uiText(
                en: 'Dispatch, ride pipeline, filters',
                ar: 'الإرسال وحالة الطلبات',
                fr: 'Dispatch et file des courses',
                es: 'Despacho y cola de pedidos',
                de: 'Dispatch und Auftragsliste',
                it: 'Dispatch e coda corse',
                ru: 'Диспетчер и очередь',
                zh: '调度与订单流',
              ),
              tabIndex: 1,
              gradient: const [Color(0xFFFFF6D5), Color(0xFFFFE08A)],
            ),
            _ownerNavQuickTile(
              icon: Icons.groups_rounded,
              title: _uiText(
                en: 'Fleet & access',
                ar: 'الأسطول والوصول',
                fr: 'Flotte et acces',
                es: 'Flota y accesos',
                de: 'Flotte und Zugang',
                it: 'Flotta e accessi',
                ru: 'Автопарк и доступ',
                zh: '车队与账号',
              ),
              subtitle: _uiText(
                en: 'Approvals, driver accounts, top-up',
                ar: 'الموافقات وحسابات السائقين',
                fr: 'Validations comptes chauffeurs',
                es: 'Aprobaciones y cuentas',
                de: 'Freigaben und Konten',
                it: 'Approvazioni e conti',
                ru: 'Заявки и аккаунты',
                zh: '审批与充值',
              ),
              tabIndex: 2,
              gradient: const [Color(0xFFE8F4FF), Color(0xFFD0E8FF)],
            ),
            _ownerNavQuickTile(
              icon: Icons.account_balance_wallet_rounded,
              title: _uiText(
                en: 'Wallets',
                ar: 'المحافظ',
                fr: 'Portefeuilles',
                es: 'Carteras',
                de: 'Wallets',
                it: 'Portafogli',
                ru: 'Кошельки',
                zh: '钱包',
              ),
              subtitle: _uiText(
                en: 'Balances, commissions, income',
                ar: 'الأرصدة والعمولات',
                fr: 'Soldes et commissions',
                es: 'Saldos y comisiones',
                de: 'Salden und Provisionen',
                it: 'Saldi e commissioni',
                ru: 'Балансы и комиссии',
                zh: '余额与分成',
              ),
              tabIndex: 3,
              gradient: const [Color(0xFFF3E8FF), Color(0xFFE8D5FF)],
            ),
            _ownerNavQuickTile(
              icon: Icons.star_rate_rounded,
              title: _uiText(
                en: 'Ratings',
                ar: 'التقييمات',
                fr: 'Notes',
                es: 'Valoraciones',
                de: 'Bewertungen',
                it: 'Valutazioni',
                ru: 'Рейтинги',
                zh: '评分',
              ),
              subtitle: _uiText(
                en: 'Quality signals per driver',
                ar: 'جودة الأداء لكل سائق',
                fr: 'Qualite par chauffeur',
                es: 'Calidad por conductor',
                de: 'Qualitaet pro Fahrer',
                it: 'Qualita per autista',
                ru: 'Качество по водителю',
                zh: '按司机质量',
              ),
              tabIndex: 4,
              gradient: const [Color(0xFFFFF9E6), Color(0xFFFFEFC2)],
            ),
            _ownerNavQuickTile(
              icon: Icons.insights_rounded,
              title: _uiText(
                en: 'Analytics',
                ar: 'التحليلات',
                fr: 'Analytique',
                es: 'Analitica',
                de: 'Analytik',
                it: 'Analitica',
                ru: 'Аналитика',
                zh: '分析',
              ),
              subtitle: _uiText(
                en: 'Trip ledger',
                ar: 'سجل الرحلات',
                fr: 'Journal des courses',
                es: 'Libro de viajes',
                de: 'Fahrtenbuch',
                it: 'Registro viaggi',
                ru: 'Журнал поездок',
                zh: '行程账',
              ),
              tabIndex: 5,
              gradient: const [Color(0xFFEFFAF3), Color(0xFFD8F5E5)],
            ),
            _ownerNavQuickTile(
              icon: Icons.tune_rounded,
              title: l.ownerTabSettings,
              subtitle: _uiText(
                en: 'Pricing, commission, routes',
                ar: 'التسعير والعمولة',
                fr: 'Tarifs et commission',
                es: 'Tarifas y comision',
                de: 'Preise und Provision',
                it: 'Prezzi e commissioni',
                ru: 'Цены и комиссия',
                zh: '定价与抽成',
              ),
              tabIndex: 6,
              gradient: const [Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
            ),
            _ownerNavQuickTile(
              icon: Icons.flight_land_rounded,
              title: l.operatorTabTodaysArrivals,
              subtitle: _uiText(
                en: 'Tunisia inbound board',
                ar: 'لوحة الوصول',
                fr: 'Tableau des arrivees',
                es: 'Panel de llegadas',
                de: 'Ankunftstafel',
                it: 'Tabellone arrivi',
                ru: 'Табло прилета',
                zh: '进港看板',
              ),
              tabIndex: 7,
              gradient: const [Color(0xFFE6F7FF), Color(0xFFD0EFFF)],
            ),
            _ownerNavQuickTile(
              icon: Icons.apartment_rounded,
              title: l.ownerTabHostelB2b,
              subtitle: _uiText(
                en: 'Tenants, bookings, hotel ops',
                ar: 'الشركاء والحجوزات',
                fr: 'Locataires et reservations',
                es: 'Inquilinos y reservas',
                de: 'Mieter und Buchungen',
                it: 'Tenant e prenotazioni',
                ru: 'B2B и брони',
                zh: 'B2B与预订',
              ),
              tabIndex: 8,
              gradient: const [Color(0xFFFFF0F0), Color(0xFFFFE4E4)],
            ),
          ];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              OwnerModule(
                accent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OwnerSectionHead(
                      _uiText(
                        en: 'Command center',
                        ar: 'مركز القيادة',
                        fr: 'Poste de commande',
                        es: 'Centro de mando',
                        de: 'Kommandozentrale',
                        it: 'Centro comando',
                        ru: 'Командный центр',
                        zh: '指挥中心',
                      ),
                      subtitle: _uiText(
                        en: 'Jump to any module — each section loads on demand.',
                        ar: 'انتقل لأي قسم — يُحمّل عند الطلب',
                        fr: 'Acces modulaire — chargement a la demande',
                        es: 'Saltos modulares — carga bajo demanda',
                        de: 'Springe zu Modulen — Laden bei Bedarf',
                        it: 'Vai ai moduli — caricamento on demand',
                        ru: 'Переход по модулям — загрузка по запросу',
                        zh: '按需加载各模块',
                      ),
                      trailing: OwnerDarkButton(
                        label: l.adminLoadRidesBtn,
                        icon: Icons.refresh_rounded,
                        onPressed: _busy ? null : _refreshAll,
                        small: true,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OwnerSectionHead(
                _uiText(
                  en: 'Navigate',
                  ar: 'تنقّل',
                  fr: 'Navigation',
                  es: 'Navegar',
                  de: 'Navigation',
                  it: 'Naviga',
                  ru: 'Разделы',
                  zh: '导航',
                ),
                subtitle: _uiText(
                  en: 'No long scroll — pick a surface',
                  ar: 'بدون تمرير طويل',
                  fr: 'Sans defilement infini',
                  es: 'Sin scroll infinito',
                  de: 'Ohne Endlos-Scroll',
                  it: 'Senza scroll infinito',
                  ru: 'Без бесконечной прокрутки',
                  zh: '告别长列表',
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: wide ? 2.25 : 1.85,
                children: tiles,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriversTab(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          RepaintBoundary(child: _buildDriverManagementModule(l)),
        ],
      ),
    );
  }

  Widget _buildWalletsTabOnly(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          RepaintBoundary(child: _buildDriverWalletsModule(l)),
        ],
      ),
    );
  }

  Widget _buildRatingsTabOnly(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          RepaintBoundary(child: _buildDriverRatingsModule(l)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          RepaintBoundary(child: _buildTripLedgerModule(l)),
        ],
      ),
    );
  }

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          OwnerDarkButton(
              label: l.adminLoadRidesBtn,
              icon: Icons.refresh_rounded,
              onPressed: _busy ? null : _refreshAll),
          const SizedBox(height: 16),
          OwnerSectionHead(l.operatorTabTodaysArrivals),
          if ((_flightDataSource ?? '').startsWith('demo'))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OwnerColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.yellowDeep.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: OwnerColors.charcoal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.flightArrivalsSampleDataBanner,
                        style: const TextStyle(
                            color: OwnerColors.textStrong, fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_flightArrivals.isEmpty)
            OwnerModule(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Icon(Icons.flight_land_rounded,
                    size: 40, color: OwnerColors.textSoft),
                const SizedBox(height: 8),
                Text(l.operatorNoFlightArrivals,
                    style: const TextStyle(color: OwnerColors.textSoft)),
              ]),
            )))
          else
            OwnerModule(
                padding: 12,
                child: TodaysFlightArrivalsCardList(
                  rows: _flightArrivals,
                  theme: FlightArrivalsVisualTokens.owner(),
                ))
        ],
      ),
    );
  }

  // ══ LIVE ORDERS TAB ════════════════════════════════════════
  Widget _buildLiveOrdersTab(AppLocalizations l) {
    int countByStatus(String status) => _adminRides
        .where(
            (r) => _rideStatusBucket((r['status'] ?? '').toString()) == status)
        .length;
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          OwnerModule(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OwnerSectionHead('Dispatch & monitoring',
                      subtitle: 'Live operational overview'),
                  Text(
                    _adminRides.any((r) =>
                            _rideStatusBucket((r['status'] ?? '').toString()) ==
                            'accepted')
                        ? 'Accepted requests are ready for dispatch monitoring.'
                        : 'No accepted requests right now.',
                    style: const TextStyle(color: OwnerColors.textSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                          onTap: () => setState(() {
                                _rideStatusFilter = 'accepted';
                                _visibleRideRows = _ownerInitialRideRows;
                              }),
                          child: OwnerStatChip(
                              label: _uiText(
                                  en: 'Accepted',
                                  ar: 'مقبول',
                                  fr: 'Accepte',
                                  es: 'Aceptado',
                                  de: 'Akzeptiert',
                                  it: 'Accettato',
                                  ru: 'Принято',
                                  zh: '已接受'),
                              value: '${countByStatus('accepted')}',
                              icon: Icons.verified_rounded,
                              color: _rideStatusFilter == 'accepted'
                                  ? OwnerColors.yellowDeep
                                  : OwnerColors.textSoft)),
                      GestureDetector(
                          onTap: () => setState(() {
                                _rideStatusFilter = 'refused';
                                _visibleRideRows = _ownerInitialRideRows;
                              }),
                          child: OwnerStatChip(
                              label: _uiText(
                                  en: 'Refused',
                                  ar: 'مرفوض',
                                  fr: 'Refuse',
                                  es: 'Rechazado',
                                  de: 'Abgelehnt',
                                  it: 'Rifiutato',
                                  ru: 'Отклонено',
                                  zh: '已拒绝'),
                              value: '${countByStatus('refused')}',
                              icon: Icons.block_rounded,
                              color: _rideStatusFilter == 'refused'
                                  ? OwnerColors.danger
                                  : OwnerColors.textSoft)),
                      GestureDetector(
                          onTap: () => setState(() {
                                _rideStatusFilter = 'ongoing';
                                _visibleRideRows = _ownerInitialRideRows;
                              }),
                          child: OwnerStatChip(
                              label: _uiText(
                                  en: 'Ongoing',
                                  ar: 'جار',
                                  fr: 'En cours',
                                  es: 'En curso',
                                  de: 'Laufend',
                                  it: 'In corso',
                                  ru: 'В пути',
                                  zh: '进行中'),
                              value: '${countByStatus('ongoing')}',
                              icon: Icons.route,
                              color: _rideStatusFilter == 'ongoing'
                                  ? OwnerColors.info
                                  : OwnerColors.textSoft)),
                      GestureDetector(
                          onTap: () => setState(() {
                                _rideStatusFilter = 'completed';
                                _visibleRideRows = _ownerInitialRideRows;
                              }),
                          child: OwnerStatChip(
                              label: _uiText(
                                  en: 'Completed',
                                  ar: 'مكتمل',
                                  fr: 'Termine',
                                  es: 'Completado',
                                  de: 'Abgeschlossen',
                                  it: 'Completato',
                                  ru: 'Завершено',
                                  zh: '已完成'),
                              value: '${countByStatus('completed')}',
                              icon: Icons.check_circle,
                              color: _rideStatusFilter == 'completed'
                                  ? OwnerColors.success
                                  : OwnerColors.textSoft)),
                      GestureDetector(
                          onTap: () => setState(() {
                                _rideStatusFilter = 'all';
                                _visibleRideRows = _ownerInitialRideRows;
                              }),
                          child: OwnerStatChip(
                              label: _uiText(
                                  en: 'All',
                                  ar: 'الكل',
                                  fr: 'Tous',
                                  es: 'Todos',
                                  de: 'Alle',
                                  it: 'Tutti',
                                  ru: 'Все',
                                  zh: '全部'),
                              value: '${_adminRides.length}',
                              icon: Icons.list_alt,
                              color: _rideStatusFilter == 'all'
                                  ? OwnerColors.charcoal
                                  : OwnerColors.textSoft)),
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

  // ① Driver management (approvals + accounts; wallet recharge lives under Wallets tab)
  Widget _buildDriverManagementModule(AppLocalizations l) {
    return OwnerModule(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OwnerSectionHead('App User Requests',
            subtitle: '${_pendingApprovals.length} pending'),
        if (_pendingApprovals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('No pending Driver/B2B requests.',
                style: TextStyle(color: OwnerColors.textSoft)),
          )
        else
          ..._pendingApprovals.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: OwnerColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwnerColors.border)),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      '${u['role']} · ${u['email'] ?? ''}\n'
                      'name: ${u['display_name'] ?? ''} | phone: ${u['phone'] ?? ''}'
                      '${(u['car_model'] ?? '').toString().isNotEmpty ? '\ncar: ${u['car_model']} / ${u['car_color'] ?? ''}' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12),
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
                                    if ((u['car_model'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text('Car type: ${u['car_model']}'),
                                    if ((u['car_color'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text('Car color: ${u['car_color']}'),
                                    Text(
                                        'Created at: ${u['created_at'] ?? ''}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Decline')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Accept')),
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
        const Divider(height: 24, color: OwnerColors.border),
        const Divider(height: 24, color: OwnerColors.border),
        const SizedBox(height: 8),
        OwnerSectionHead('Driver account tools',
            subtitle: 'Create and manage driver login accounts'),
        // Legacy create driver (PIN-based)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: OwnerColors.yellowSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OwnerColors.yellowDeep)),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  color: OwnerColors.charcoal, size: 18)),
          title: const Text('Add Driver Login Account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          childrenPadding: const EdgeInsets.only(top: 8),
          children: [
            TextField(
                controller: _newDriverPhone,
                keyboardType: TextInputType.phone,
                decoration: ownerFieldDecoration('Phone', icon: Icons.phone_outlined)),
            const SizedBox(height: 8),
            TextField(
                controller: _newDriverEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: ownerFieldDecoration('Email', icon: Icons.email_outlined)),
            const SizedBox(height: 8),
            TextField(
                controller: _newDriverName,
                decoration:
                    ownerFieldDecoration(l.operatorDriverNameLabel, icon: Icons.badge_outlined)),
            const SizedBox(height: 8),
            TextField(
              controller: _newDriverPin,
              obscureText: _obscureNewDriverPin,
              decoration:
                  ownerFieldDecoration('Password', icon: Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(
                      () => _obscureNewDriverPin = !_obscureNewDriverPin),
                  icon: Icon(
                    _obscureNewDriverPin
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: OwnerColors.textSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _newDriverCarModel,
                decoration: ownerFieldDecoration(l.operatorCarModelLabel,
                    icon: Icons.directions_car_outlined)),
            const SizedBox(height: 8),
            TextField(
                controller: _newDriverCarColor,
                decoration:
                    ownerFieldDecoration(l.operatorCarColorLabel, icon: Icons.palette_outlined)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
                onPressed: _busy ? null : _pickNewDriverImage,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(l.operatorPickFromGallery),
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    side: const BorderSide(color: OwnerColors.border))),
            const SizedBox(height: 12),
            OwnerYellowButton(
                label: _uiText(
                    en: 'Create Driver Login Account',
                    ar: 'إنشاء حساب دخول سائق',
                    fr: 'Créer un compte de connexion chauffeur',
                    es: 'Crear cuenta de acceso de conductor',
                    de: 'Fahrer-Loginkonto erstellen',
                    it: 'Crea account di accesso autista',
                    ru: 'Создать аккаунт входа водителя',
                    zh: '创建司机登录账户'),
                icon: Icons.add_rounded,
                onPressed: _busy ? null : _createDriverAccount),
          ],
        ),
        const SizedBox(height: 12),
        OwnerSectionHead('Managed driver accounts',
            subtitle:
                '${_managedDriverUsers.length} drivers · showing ${math.min(_visibleManagedDriverRows, _managedDriverUsers.length)}'),
        ..._managedDriverUsers.take(_visibleManagedDriverRows).map((u) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: OwnerColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.border)),
              child: Row(children: [
                Expanded(
                  child: Text(
                    '${u['display_name'] ?? '-'}\n${u['email'] ?? ''}\n${u['phone'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => _editManagedDriver(u),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                    onPressed: _busy ? null : () => _deleteManagedDriver(u),
                    icon: const Icon(Icons.delete_outline, color: OwnerColors.danger)),
              ]),
            )),
        if (_managedDriverUsers.length > _visibleManagedDriverRows)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: OwnerDarkButton(
                label: _uiText(
                  en: 'Show more drivers',
                  ar: 'عرض المزيد من السائقين',
                  fr: 'Afficher plus de chauffeurs',
                  es: 'Mostrar mas conductores',
                  de: 'Mehr Fahrer anzeigen',
                  it: 'Mostra piu autisti',
                  ru: 'Еще водители',
                  zh: '加载更多司机',
                ),
                icon: Icons.expand_more_rounded,
                small: true,
                fullWidth: false,
                onPressed: () => setState(() {
                  _visibleManagedDriverRows += _ownerListPageStep;
                }),
              ),
            ),
          ),
      ]),
    );
  }

  // ③ Driver wallets (+ recharge controls)
  Widget _buildDriverWalletsModule(AppLocalizations l) {
    final visibleWallets = _driverWalletBreakdown
        .where(_isWalletVisible)
        .where((row) => ((row['id'] as num?)?.toInt() ?? 0) > 0)
        .toList();
    final uniqueWalletsById = <int, Map<String, dynamic>>{};
    for (final row in visibleWallets) {
      final id = (row['id'] as num?)?.toInt();
      if (id == null) continue;
      uniqueWalletsById.putIfAbsent(id, () => row);
    }
    final rechargeWallets = uniqueWalletsById.values.toList();
    final selectedTopUpId = rechargeWallets.any(
      (row) => (row['id'] as num?)?.toInt() == _topUpAccountId,
    )
        ? _topUpAccountId
        : null;

    final visibleWalletsAll =
        _driverWalletBreakdown.where(_isWalletVisible).toList();
    final slice = visibleWalletsAll.take(_visibleWalletRows).toList();
    return OwnerModule(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OwnerSectionHead(
          _uiText(
            en: 'Wallet recharge',
            ar: 'شحن المحفظة',
            fr: 'Recharge portefeuille',
            es: 'Recarga de cartera',
            de: 'Wallet-Aufladung',
            it: 'Ricarica wallet',
            ru: 'Пополнение кошелька',
            zh: '钱包充值',
          ),
          subtitle: _uiText(
            en: 'Add balance to a driver wallet',
            ar: 'إضافة رصيد لمحفظة السائق',
            fr: 'Ajouter du solde au chauffeur',
            es: 'Anadir saldo al conductor',
            de: 'Guthaben fuer Fahrer',
            it: 'Aggiungi saldo autista',
            ru: 'Пополнить баланс водителя',
            zh: '为司机钱包充值',
          ),
        ),
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: OwnerColors.infoBg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.savings_outlined,
                  color: OwnerColors.info, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _uiText(
                en: 'Select driver and amount',
                ar: 'اختر السائق والمبلغ',
                fr: 'Chauffeur et montant',
                es: 'Conductor e importe',
                de: 'Fahrer und Betrag',
                it: 'Autista e importo',
                ru: 'Водитель и сумма',
                zh: '选择司机与金额',
              ),
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: OwnerColors.textStrong),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: DropdownButtonFormField<int>(
            value: selectedTopUpId,
            decoration: ownerFieldDecoration(l.operatorDriverNameLabel,
                icon: Icons.person_outline_rounded),
            dropdownColor: OwnerColors.surface,
            items: rechargeWallets
                .map((d) => DropdownMenuItem<int>(
                    value: (d['id'] as num?)?.toInt(),
                    child: Text('${d['driver_name'] ?? ''}',
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged:
                _busy ? null : (v) => setState(() => _topUpAccountId = v),
          )),
          const SizedBox(width: 8),
          SizedBox(
              width: 100,
              child: TextField(
                  controller: _topUpAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: ownerFieldDecoration('Amount', suffix: 'DT'))),
        ]),
        const SizedBox(height: 12),
        OwnerDarkButton(
            label: _uiText(
                en: 'Recharge Balance',
                ar: 'شحن الرصيد',
                fr: 'Recharger le solde',
                es: 'Recargar saldo',
                de: 'Guthaben aufladen',
                it: 'Ricarica saldo',
                ru: 'Пополнить баланс',
                zh: '充值余额'),
            icon: Icons.bolt_rounded,
            onPressed: _busy || _topUpAccountId == null
                ? null
                : _rechargeDriverWallet),
        const Divider(height: 28, color: OwnerColors.border),
        OwnerSectionHead(l.ownerDriverPinWalletsHeading,
            subtitle:
                '${visibleWalletsAll.length} drivers · showing ${slice.length}'),
        if (visibleWalletsAll.isEmpty)
          Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 36, color: OwnerColors.textSoft),
                    const SizedBox(height: 8),
                    Text(l.ownerDriverPinWalletsEmpty,
                        style: const TextStyle(color: OwnerColors.textSoft)),
                  ])))
        else
          ...slice.map((d) {
            final managed = _findManagedDriverByWalletRow(d);
            return _DriverCard(
              driver: d,
              onEdit: () => _editDriverAccount(d),
              busy: _busy,
              subtitle: _ownerDriverPinSubtitle(l, d),
              onDelete:
                  managed != null ? () => _deleteManagedDriver(managed) : null,
            );
          }),
        if (visibleWalletsAll.length > _visibleWalletRows)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: OwnerDarkButton(
                label: _uiText(
                  en: 'Show more wallets',
                  ar: 'عرض المزيد من المحافظ',
                  fr: 'Afficher plus de portefeuilles',
                  es: 'Mostrar mas carteras',
                  de: 'Mehr Wallets anzeigen',
                  it: 'Mostra piu portafogli',
                  ru: 'Еще кошельки',
                  zh: '加载更多钱包',
                ),
                icon: Icons.expand_more_rounded,
                small: true,
                fullWidth: false,
                onPressed: () => setState(() {
                  _visibleWalletRows += _ownerListPageStep;
                }),
              ),
            ),
          ),
      ]),
    );
  }

  // ④ Driver ratings
  Widget _buildDriverRatingsModule(AppLocalizations l) {
    final visibleRatings = _driverRatings.where(_isRatingVisible).toList();
    final slice = visibleRatings.take(_visibleRatingRows).toList();
    return OwnerModule(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OwnerSectionHead(_uiText(
            en: 'Driver Ratings',
            ar: 'تقييمات السائقين',
            fr: 'Notes des chauffeurs',
            es: 'Calificaciones',
            de: 'Fahrerbewertungen',
            it: 'Valutazioni',
            ru: 'Рейтинг',
            zh: '司机评分'),
            subtitle:
                '${visibleRatings.length} drivers · showing ${slice.length}'),
        if (visibleRatings.isEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  _uiText(
                      en: 'No ratings yet',
                      ar: 'لا توجد تقييمات بعد',
                      fr: 'Pas encore de notes',
                      es: 'Sin calificaciones',
                      de: 'Keine Bewertungen',
                      it: 'Nessuna valutazione',
                      ru: 'Нет оценок',
                      zh: '暂无评分'),
                  style: const TextStyle(color: OwnerColors.textSoft)))
        else
          ...slice.map((row) {
            Map<String, dynamic>? managed;
            final phone = (row['phone'] ?? '').toString().trim();
            final name =
                (row['driver_name'] ?? '').toString().trim().toLowerCase();
            for (final u in _managedDriverUsers) {
              final up = (u['phone'] ?? '').toString().trim();
              final un =
                  (u['display_name'] ?? '').toString().trim().toLowerCase();
              if ((phone.isNotEmpty && up == phone) ||
                  (name.isNotEmpty && un == name)) {
                managed = u;
                break;
              }
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: OwnerColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.border)),
              child: Row(children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: OwnerColors.yellowSoft,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: OwnerColors.yellowDeep)),
                    child: const Center(
                        child: Icon(Icons.star_rounded,
                            color: OwnerColors.charcoal, size: 18))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text((row['driver_name'] ?? '').toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${row['rating_average']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: OwnerColors.charcoal)),
                  Text(
                      '${row['rating_count']} ${_uiText(en: 'ratings', ar: 'تقييمات', fr: 'notes', es: 'califs.', de: 'Bewert.', it: 'valut.', ru: 'оценок', zh: '评分')}',
                      style: const TextStyle(color: OwnerColors.textSoft, fontSize: 10)),
                ]),
                if (managed != null)
                  IconButton(
                      onPressed:
                          _busy ? null : () => _deleteManagedDriver(managed!),
                      icon: const Icon(Icons.delete_outline, color: OwnerColors.danger)),
              ]),
            );
          }),
        if (visibleRatings.length > _visibleRatingRows)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: OwnerDarkButton(
                label: _uiText(
                  en: 'Show more ratings',
                  ar: 'عرض المزيد من التقييمات',
                  fr: 'Afficher plus de notes',
                  es: 'Mostrar mas valoraciones',
                  de: 'Mehr Bewertungen',
                  it: 'Mostra piu valutazioni',
                  ru: 'Еще оценки',
                  zh: '加载更多评分',
                ),
                icon: Icons.expand_more_rounded,
                small: true,
                fullWidth: false,
                onPressed: () => setState(() {
                  _visibleRatingRows += _ownerListPageStep;
                }),
              ),
            ),
          ),
      ]),
    );
  }

  // ⑤ Trip ledger
  Widget _buildTripLedgerModule(AppLocalizations l) {
    return OwnerModule(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OwnerSectionHead(l.ownerVaultHeading, subtitle: '${_trips.length} trips'),
        if (_trips.isEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l.noTripsYet,
                  style: const TextStyle(color: OwnerColors.textSoft)))
        else
          ..._trips.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: OwnerColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwnerColors.border)),
                child: Row(children: [
                  Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: OwnerColors.charcoal,
                          borderRadius: BorderRadius.circular(9)),
                      child: const Center(
                          child: Icon(Icons.receipt_long_rounded,
                              color: OwnerColors.yellow, size: 16))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            l.ownerTripRouteFareRow(
                                t['route']?.toString() ?? '',
                                t['fare']?.toString() ?? ''),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                            l.tripListSubtitle(t['date'] as String,
                                t['commission'].toString()),
                            style: const TextStyle(
                                color: OwnerColors.textSoft, fontSize: 11)),
                      ])),
                ]),
              )),
      ]),
    );
  }

  // ⑥ Rides log
  Widget _buildRidesLogModule(AppLocalizations l) {
    final filteredRides = _adminRides.where(_matchesRideFilter).toList();
    final visibleRides = filteredRides.take(_visibleRideRows).toList();
    return OwnerModule(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OwnerSectionHead(
          'Live ride stream',
          subtitle:
              '${visibleRides.length}/${filteredRides.length} rides loaded',
        ),
        if (filteredRides.isEmpty)
          ManagementEmptyState(
            message: l.adminNoRidesLoaded,
            icon: Icons.local_taxi_outlined,
          )
        else
          ...visibleRides.map((r) {
            final isB2b = r['is_b2b'] == true;
            final status = (r['status'] ?? '').toString();
            return _OwnerRideCard(
              ride: r,
              route: localizedRideRouteRow(
                l,
                r['pickup']?.toString() ?? '',
                r['destination']?.toString() ?? '',
              ),
              status: status,
              statusLabel: _ownerRideStatusLabel(l, status),
              isB2b: isB2b,
              distance: '${_rideDistanceKm(r)?.toStringAsFixed(1) ?? '-'} km',
              price: _ridePrice(r),
              timeLabel: _requestLiveTime(r),
              passengerSectionTitle: l.rolePassenger,
              b2bSectionTitle: l.roleB2b,
              driverSectionTitle: _uiText(
                  en: 'Driver',
                  ar: 'السائق',
                  fr: 'Chauffeur',
                  es: 'Conductor',
                  de: 'Fahrer',
                  it: 'Autista',
                  ru: 'Водитель',
                  zh: '司机'),
            );
          }),
        if (visibleRides.length < filteredRides.length)
          Center(
            child: OwnerDarkButton(
              label: _uiText(
                  en: 'Show more rides',
                  ar: 'عرض رحلات أكثر',
                  fr: 'Afficher plus de courses',
                  es: 'Mostrar mas viajes',
                  de: 'Mehr Fahrten anzeigen',
                  it: 'Mostra piu corse',
                  ru: 'Показать больше поездок',
                  zh: '显示更多行程'),
              icon: Icons.expand_more_rounded,
              small: true,
              fullWidth: false,
              onPressed: () => setState(() {
                _visibleRideRows += _ownerListPageStep;
              }),
            ),
          ),
      ]),
    );
  }

  // ══ SETTINGS TAB ══════════════════════════════════════════
  Widget _buildSettingsTab(AppLocalizations l) {
    return OwnerSettingsTab(
      l: l,
      busy: _busy,
      commissionPercent: _commissionDemoPercent,
      onCommissionChanged: (v) => setState(() => _commissionDemoPercent = v),
      fareRoutes: _fareRoutes,
      fareControllers: _fareCtrls,
      onSaveFare: _saveFareRoute,
      onPullRefresh: _refreshAll,
      searchHint: _uiText(
        en:
            'Search by place, airport, or route — Maps suggestions refine the fare list.',
        ar: 'ابحث عن مكان أو مطار أو مسار — اقتراحات الخرائط تصفّي قائمة الأسعار.',
        fr:
            'Recherchez un lieu, un aeroport ou un trajet — les suggestions Maps filtrent les tarifs.',
        es:
            'Busque lugar, aeropuerto o ruta — las sugerencias de Maps filtran tarifas.',
        de:
            'Ort, Flughafen oder Route suchen — Maps-Vorschlaege filtern die Tarifliste.',
        it:
            'Cerca luogo, aeroporto o percorso — i suggerimenti Maps filtrano le tariffe.',
        ru:
            'Ищите место, аэропорт или маршрут — подсказки Maps фильтруют тарифы.',
        zh: '按地点、机场或路线搜索 — 地图建议会筛选运价列表。',
      ),
    );
  }

  // ══ B2B HOTEL TAB ════════════════════════════════════════
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

    Widget _statusPill(bool enabled) => ManagementStatusPill(
          label: enabled
              ? _uiText(
                  en: 'Active',
                  ar: 'نشط',
                  fr: 'Actif',
                  es: 'Activo',
                  de: 'Aktiv',
                  it: 'Attivo',
                  ru: 'Активен',
                  zh: '活跃',
                )
              : _uiText(
                  en: 'Paused',
                  ar: 'متوقف',
                  fr: 'En pause',
                  es: 'En pausa',
                  de: 'Pausiert',
                  it: 'In pausa',
                  ru: 'Приостановлен',
                  zh: '暂停',
                ),
          color: enabled ? OwnerColors.charcoal : OwnerColors.textSoft,
          background: enabled ? OwnerColors.yellowSoft : OwnerColors.surfaceAlt,
        );

    final filteredB2b =
        _managedB2bUsers.where(_matchesB2bApprovalFilter).toList();
    final enabled = filteredB2b.where((b) => b['is_enabled'] == true).toList();
    final paused = filteredB2b.where((b) => b['is_enabled'] != true).toList();
    final filteredBookings =
        _adminB2bBookings.where(_matchesB2bBookingFilter).toList();
    final visibleBookings =
        filteredBookings.take(_visibleB2bBookingRows).toList();
    final visibleEnabled = enabled.take(_visibleB2bAccountRows).toList();
    final visiblePaused = paused.take(_visibleB2bAccountRows).toList();

    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Action buttons
          Row(children: [
            Expanded(
                child: OwnerDarkButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPressed: _busy ? null : _refreshAll,
                    small: true)),
            const SizedBox(width: 8),
            Expanded(
                child: OwnerYellowButton(
                    label: 'New B2B Account',
                    icon: Icons.add_business_rounded,
                    onPressed: _busy ? null : _createB2bTenant,
                    small: true)),
          ]),
          const SizedBox(height: 16),

          // B2B Bookings module
          OwnerModule(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OwnerSectionHead(
                l.ownerAdminOversightHeading,
                subtitle:
                    '${visibleBookings.length}/${filteredBookings.length} bookings',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _bookingStatusChip(
                    label: _uiText(
                        en: 'All',
                        ar: 'الكل',
                        fr: 'Tous',
                        es: 'Todos',
                        de: 'Alle',
                        it: 'Tutti',
                        ru: 'Все',
                        zh: '全部'),
                    status: 'all',
                    count: _adminB2bBookings.length,
                  ),
                  const SizedBox(width: 8),
                  _bookingStatusChip(
                    label: _uiText(
                        en: 'Accepted',
                        ar: 'مقبول',
                        fr: 'Accepte',
                        es: 'Aceptado',
                        de: 'Akzeptiert',
                        it: 'Accettato',
                        ru: 'Принято',
                        zh: '已接受'),
                    status: 'accepted',
                    count: _adminB2bBookings
                        .where((b) =>
                            _rideStatusBucket((b['status'] ?? '').toString()) ==
                            'accepted')
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _bookingStatusChip(
                    label: _uiText(
                        en: 'Refused',
                        ar: 'مرفوض',
                        fr: 'Refuse',
                        es: 'Rechazado',
                        de: 'Abgelehnt',
                        it: 'Rifiutato',
                        ru: 'Отклонено',
                        zh: '已拒绝'),
                    status: 'refused',
                    count: _adminB2bBookings
                        .where((b) =>
                            _rideStatusBucket((b['status'] ?? '').toString()) ==
                            'refused')
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _bookingStatusChip(
                    label: _uiText(
                        en: 'Ongoing',
                        ar: 'جار',
                        fr: 'En cours',
                        es: 'En curso',
                        de: 'Laufend',
                        it: 'In corso',
                        ru: 'В пути',
                        zh: '进行中'),
                    status: 'ongoing',
                    count: _adminB2bBookings
                        .where((b) =>
                            _rideStatusBucket((b['status'] ?? '').toString()) ==
                            'ongoing')
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _bookingStatusChip(
                    label: _uiText(
                        en: 'Completed',
                        ar: 'مكتمل',
                        fr: 'Termine',
                        es: 'Completado',
                        de: 'Abgeschlossen',
                        it: 'Completato',
                        ru: 'Завершено',
                        zh: '已完成'),
                    status: 'completed',
                    count: _adminB2bBookings
                        .where((b) =>
                            _rideStatusBucket((b['status'] ?? '').toString()) ==
                            'completed')
                        .length,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (filteredBookings.isEmpty)
                ManagementEmptyState(
                  message: l.noTripsLoaded,
                  icon: Icons.book_outlined,
                )
              else
                ...visibleBookings.map((b) {
                  final status = (b['status'] ?? '').toString();
                  return _B2bBookingCard(
                    route: (b['route'] ?? '').toString(),
                    guestName: (b['guest_name'] ?? '').toString(),
                    room: (b['room_number'] ?? '').toString(),
                    fare: (b['fare'] ?? '').toString(),
                    status: status,
                    statusLabel: _ownerRideStatusLabel(l, status),
                    createdAt: (b['created_at'] ?? '').toString(),
                    sourceCode: (b['source_code'] ?? '').toString(),
                  );
                }),
              if (visibleBookings.length < filteredBookings.length)
                Center(
                  child: OwnerDarkButton(
                    label: _uiText(
                        en: 'Show more orders',
                        ar: 'عرض طلبات أكثر',
                        fr: 'Afficher plus de commandes',
                        es: 'Mostrar mas pedidos',
                        de: 'Mehr Auftraege anzeigen',
                        it: 'Mostra piu ordini',
                        ru: 'Показать больше заказов',
                        zh: '显示更多订单'),
                    icon: Icons.expand_more_rounded,
                    small: true,
                    fullWidth: false,
                    onPressed: () => setState(() {
                      _visibleB2bBookingRows += _ownerListPageStep;
                    }),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          OwnerSectionHead(
            _uiText(
              en: 'Hostel Accounts (B2B)',
              ar: 'حسابات الفنادق (B2B)',
              fr: 'Comptes hotels (B2B)',
              es: 'Cuentas de hotel (B2B)',
              de: 'Hotelkonten (B2B)',
              it: 'Account hotel (B2B)',
              ru: 'Аккаунты отелей (B2B)',
              zh: '酒店账户 (B2B)',
            ),
            subtitle:
                '${filteredB2b.length} ${_uiText(en: 'accounts', ar: 'حسابات', fr: 'comptes', es: 'cuentas', de: 'Konten', it: 'account', ru: 'аккаунтов', zh: '个账户')}',
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _b2bFilterChip(
                  label: _uiText(
                      en: 'All',
                      ar: 'الكل',
                      fr: 'Tous',
                      es: 'Todos',
                      de: 'Alle',
                      it: 'Tutti',
                      ru: 'Все',
                      zh: '全部'),
                  selected: _b2bApprovalFilter == 'all',
                  onTap: () => setState(() {
                    _b2bApprovalFilter = 'all';
                    _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
                  }),
                ),
                const SizedBox(width: 8),
                _b2bFilterChip(
                  label: _uiText(
                      en: 'Approved',
                      ar: 'موافق عليه',
                      fr: 'Approuve',
                      es: 'Aprobado',
                      de: 'Genehmigt',
                      it: 'Approvato',
                      ru: 'Одобрено',
                      zh: '已批准'),
                  selected: _b2bApprovalFilter == 'approved',
                  onTap: () => setState(() {
                    _b2bApprovalFilter = 'approved';
                    _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
                  }),
                ),
                const SizedBox(width: 8),
                _b2bFilterChip(
                  label: _uiText(
                      en: 'Pending',
                      ar: 'قيد الانتظار',
                      fr: 'En attente',
                      es: 'Pendiente',
                      de: 'Ausstehend',
                      it: 'In attesa',
                      ru: 'В ожидании',
                      zh: '待处理'),
                  selected: _b2bApprovalFilter == 'pending',
                  onTap: () => setState(() {
                    _b2bApprovalFilter = 'pending';
                    _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
                  }),
                ),
                const SizedBox(width: 8),
                _b2bFilterChip(
                  label: _uiText(
                      en: 'Rejected',
                      ar: 'مرفوض',
                      fr: 'Refuse',
                      es: 'Rechazado',
                      de: 'Abgelehnt',
                      it: 'Rifiutato',
                      ru: 'Отклонено',
                      zh: '已拒绝'),
                  selected: _b2bApprovalFilter == 'rejected',
                  onTap: () => setState(() {
                    _b2bApprovalFilter = 'rejected';
                    _visibleB2bAccountRows = _ownerInitialB2bAccountRows;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (filteredB2b.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('No B2B accounts yet',
                  style: TextStyle(color: OwnerColors.textSoft)),
            ),

          // Active hotels (restored card design)
          if (enabled.isNotEmpty) ...[
            OwnerSectionHead(
              _uiText(
                en: 'Active B2B Accounts',
                ar: 'حسابات B2B النشطة',
                fr: 'Comptes B2B actifs',
                es: 'Cuentas B2B activas',
                de: 'Aktive B2B-Konten',
                it: 'Account B2B attivi',
                ru: 'Активные B2B аккаунты',
                zh: '活跃B2B账户',
              ),
              subtitle:
                  '${enabled.length} ${_uiText(en: 'accounts', ar: 'حسابات', fr: 'comptes', es: 'cuentas', de: 'Konten', it: 'account', ru: 'аккаунтов', zh: '个账户')}',
            ),
            ...visibleEnabled.map((b) {
              final tenant = _tenantForManagedUser(b);
              final label =
                  ((tenant?['label'] ?? b['display_name']) ?? '').toString();
              final contact =
                  ((tenant?['contact_name'] ?? b['display_name']) ?? '')
                      .toString();
              final pin = (tenant?['pin'] ?? '').toString();
              final email = (b['email'] ?? '').toString();
              final phone = ((tenant?['phone'] ?? b['phone']) ?? '').toString();
              final hotel = (tenant?['hotel'] ?? '').toString();
              return OwnerModule(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: OwnerColors.charcoal,
                              borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.hotel_rounded,
                              color: OwnerColors.yellow, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14))),
                        const SizedBox(width: 8),
                        _b2bApprovalChip(_b2bApprovalStatus(b)),
                        const SizedBox(width: 8),
                        _statusPill(true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Name: ${contact.isEmpty ? '-' : contact} | PIN: ${pin.isEmpty ? '-' : pin}',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    Text('Email: $email',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    Text('Phone: $phone',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    if (hotel.isNotEmpty)
                      Text('Hotel: $hotel',
                          style: const TextStyle(
                              color: OwnerColors.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: OwnerColors.yellow,
                              foregroundColor: OwnerColors.charcoal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _editB2bTenant(tenant)
                                    : _editManagedB2b(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: OwnerColors.dangerBg,
                              foregroundColor: OwnerColors.danger,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _toggleB2b(tenant)
                                    : _api
                                        .setAdminUserEnabled(
                                          token: _token!,
                                          userId: (b['id'] as num).toInt(),
                                          isEnabled: false,
                                        )
                                        .then((_) => _refreshAll()),
                            child: const Text('Pause'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (visibleEnabled.length < enabled.length)
              Center(
                child: OwnerDarkButton(
                  label: _uiText(
                      en: 'Show more active accounts',
                      ar: 'عرض حسابات نشطة أكثر',
                      fr: 'Afficher plus de comptes actifs',
                      es: 'Mostrar mas cuentas activas',
                      de: 'Mehr aktive Konten anzeigen',
                      it: 'Mostra piu account attivi',
                      ru: 'Показать больше активных аккаунтов',
                      zh: '显示更多活跃账户'),
                  icon: Icons.expand_more_rounded,
                  small: true,
                  fullWidth: false,
                  onPressed: () => setState(() {
                    _visibleB2bAccountRows += _ownerListPageStep;
                  }),
                ),
              ),
          ],

          // Paused hotels (restored card design)
          if (paused.isNotEmpty) ...[
            const SizedBox(height: 4),
            OwnerSectionHead(
              _uiText(
                en: 'Paused B2B Accounts',
                ar: 'حسابات B2B المتوقفة',
                fr: 'Comptes B2B en pause',
                es: 'Cuentas B2B en pausa',
                de: 'Pausierte B2B-Konten',
                it: 'Account B2B in pausa',
                ru: 'Приостановленные B2B аккаунты',
                zh: '暂停的B2B账户',
              ),
              subtitle:
                  '${paused.length} ${_uiText(en: 'accounts', ar: 'حسابات', fr: 'comptes', es: 'cuentas', de: 'Konten', it: 'account', ru: 'аккаунтов', zh: '个账户')}',
            ),
            ...visiblePaused.map((b) {
              final tenant = _tenantForManagedUser(b);
              final label =
                  ((tenant?['label'] ?? b['display_name']) ?? '').toString();
              final contact =
                  ((tenant?['contact_name'] ?? b['display_name']) ?? '')
                      .toString();
              final pin = (tenant?['pin'] ?? '').toString();
              final email = (b['email'] ?? '').toString();
              final phone = ((tenant?['phone'] ?? b['phone']) ?? '').toString();
              final hotel = (tenant?['hotel'] ?? '').toString();
              return OwnerModule(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: OwnerColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: OwnerColors.border)),
                          child: const Icon(Icons.hotel_rounded,
                              color: OwnerColors.charcoal, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14))),
                        const SizedBox(width: 8),
                        _b2bApprovalChip(_b2bApprovalStatus(b)),
                        const SizedBox(width: 8),
                        _statusPill(false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Name: ${contact.isEmpty ? '-' : contact} | PIN: ${pin.isEmpty ? '-' : pin}',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    Text('Email: $email',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    Text('Phone: $phone',
                        style:
                            const TextStyle(color: OwnerColors.textSoft, fontSize: 11)),
                    if (hotel.isNotEmpty)
                      Text('Hotel: $hotel',
                          style: const TextStyle(
                              color: OwnerColors.textSoft, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: OwnerColors.yellow,
                              foregroundColor: OwnerColors.charcoal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _editB2bTenant(tenant)
                                    : _editManagedB2b(b),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD4EDDA),
                              foregroundColor: OwnerColors.charcoal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => tenant != null
                                    ? _toggleB2b(tenant)
                                    : _api
                                        .setAdminUserEnabled(
                                          token: _token!,
                                          userId: (b['id'] as num).toInt(),
                                          isEnabled: true,
                                        )
                                        .then((_) => _refreshAll()),
                            child: const Text('Activate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (visiblePaused.length < paused.length)
              Center(
                child: OwnerDarkButton(
                  label: _uiText(
                      en: 'Show more paused accounts',
                      ar: 'عرض حسابات متوقفة أكثر',
                      fr: 'Afficher plus de comptes en pause',
                      es: 'Mostrar mas cuentas pausadas',
                      de: 'Mehr pausierte Konten anzeigen',
                      it: 'Mostra piu account in pausa',
                      ru: 'Показать больше приостановленных аккаунтов',
                      zh: '显示更多暂停账户'),
                  icon: Icons.expand_more_rounded,
                  small: true,
                  fullWidth: false,
                  onPressed: () => setState(() {
                    _visibleB2bAccountRows += _ownerListPageStep;
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kOwnerPortalTabCount, vsync: this);
    _tabController!.addListener(_onOwnerTabChanged);
    final t = widget.initialToken;
    if (t != null && t.isNotEmpty) {
      _token = t;
      unawaited(SessionStore.saveOwnerToken(t));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ownerTabsHydrated.clear();
        unawaited(_ensureOwnerTabHydrated(0));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.owner);
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onOwnerTabChanged);
    _tabController?.dispose();
    _secretController.dispose();
    _newDriverPhone.dispose();
    _newDriverName.dispose();
    _newDriverEmail.dispose();
    _newDriverPin.dispose();
    _newDriverCarModel.dispose();
    _newDriverCarColor.dispose();
    _topUpAmountController.dispose();
    for (final c in _fareCtrls.values) {
      c.dispose();
    }
    _fareCtrls.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tc = _tabController;

    return Scaffold(
      backgroundColor: OwnerColors.bgWarm,
      appBar: AppBar(
        backgroundColor: OwnerColors.yellow,
        foregroundColor: OwnerColors.charcoal,
        centerTitle: true,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, color: OwnerColors.charcoal),
        ),
        title: Text(
          _uiText(
            en: 'Owner HQ',
            ar: 'مركز المالك',
            fr: 'Quartier general proprietaire',
            es: 'Centro propietario',
            de: 'Owner-Zentrale',
            it: 'Sede proprietario',
            ru: 'Панель владельца',
            zh: '老板控制台',
          ),
          style: const TextStyle(
              color: OwnerColors.charcoal, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.owner,
            foregroundColor: OwnerColors.charcoal,
          ),
          if (_token != null)
            IconButton(
              onPressed: _editMyAccount,
              tooltip: 'My account',
              icon:
                  const Icon(Icons.manage_accounts_rounded, color: OwnerColors.charcoal),
            ),
          if (_token != null)
            IconButton(
              onPressed: () => unawaited(_logout()),
              tooltip: l.logoutApp,
              icon: const Icon(Icons.logout_rounded, color: OwnerColors.charcoal),
            ),
          if (_token != null)
            IconButton(
                onPressed: _busy ? null : _refreshAll,
                icon: const Icon(Icons.refresh_rounded, color: OwnerColors.charcoal)),
        ],
      ),
      body: _token == null
          // ── Login ──────────────────────────────────────────
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 92,
                    height: 72,
                    decoration: BoxDecoration(
                        color: OwnerColors.yellow,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: OwnerColors.yellow.withOpacity(0.45),
                              blurRadius: 20)
                        ]),
                    child: const VoomLogo(height: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text('Owner HQ',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: OwnerColors.textStrong)),
                  const SizedBox(height: 4),
                  Text(l.ownerPasswordCeoLabel,
                      style: const TextStyle(color: OwnerColors.textSoft, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                        color: OwnerColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: OwnerColors.border),
                        boxShadow: [
                          BoxShadow(
                              color: OwnerColors.charcoal.withOpacity(0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      TextField(
                        controller: _secretController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l.ownerPassword,
                          labelStyle:
                              const TextStyle(color: OwnerColors.textMid, fontSize: 13),
                          prefixIcon: const Icon(Icons.vpn_key_outlined,
                              color: OwnerColors.charcoal, size: 18),
                          filled: true,
                          fillColor: OwnerColors.surfaceAlt,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: OwnerColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: OwnerColors.yellow, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: OwnerColors.textSoft),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OwnerYellowButton(
                          label: l.loginLoadDashboard,
                          icon: Icons.login_rounded,
                          onPressed: _busy ? null : _login),
                    ]),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: OwnerColors.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: OwnerColors.danger.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: OwnerColors.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_message!,
                                  style: const TextStyle(
                                      color: OwnerColors.danger, fontSize: 13)))
                        ])),
                  ],
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                        color: OwnerColors.yellow, strokeWidth: 2.5)
                  ],
                ]),
              ),
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator(color: OwnerColors.yellow))
              // ── Dashboard ──────────────────────────────────
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // Welcome banner
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFFC200), Color(0xFFFFD84D)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: OwnerColors.yellow.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: OwnerColors.charcoal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(l.ownerWelcomeHq,
                                  style: const TextStyle(
                                      color: OwnerColors.charcoal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 960;
                            final destinations = <NavigationRailDestination>[
                              NavigationRailDestination(
                                icon: const Icon(Icons.dashboard_customize_outlined),
                                selectedIcon:
                                    const Icon(Icons.dashboard_customize_rounded),
                                label: Text(_uiText(
                                  en: 'Home',
                                  ar: 'الرئيسية',
                                  fr: 'Accueil',
                                  es: 'Inicio',
                                  de: 'Home',
                                  it: 'Home',
                                  ru: 'Главная',
                                  zh: '首页',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.bolt_outlined),
                                selectedIcon: const Icon(Icons.bolt_rounded),
                                label: Text(_uiText(
                                  en: 'Live',
                                  ar: 'مباشر',
                                  fr: 'Live',
                                  es: 'Live',
                                  de: 'Live',
                                  it: 'Live',
                                  ru: 'Онлайн',
                                  zh: '实时',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.groups_outlined),
                                selectedIcon: const Icon(Icons.groups_rounded),
                                label: Text(_uiText(
                                  en: 'Fleet',
                                  ar: 'الأسطول',
                                  fr: 'Flotte',
                                  es: 'Flota',
                                  de: 'Flotte',
                                  it: 'Flotta',
                                  ru: 'Флот',
                                  zh: '车队',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.account_balance_wallet_outlined),
                                selectedIcon:
                                    const Icon(Icons.account_balance_wallet_rounded),
                                label: Text(_uiText(
                                  en: 'Wallets',
                                  ar: 'محافظ',
                                  fr: 'Wallets',
                                  es: 'Carteras',
                                  de: 'Wallets',
                                  it: 'Wallet',
                                  ru: 'Кошельки',
                                  zh: '钱包',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.star_outline_rounded),
                                selectedIcon: const Icon(Icons.star_rate_rounded),
                                label: Text(_uiText(
                                  en: 'Stars',
                                  ar: 'نجوم',
                                  fr: 'Notes',
                                  es: 'Estrellas',
                                  de: 'Stars',
                                  it: 'Stelle',
                                  ru: 'Звезды',
                                  zh: '评分',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.insights_outlined),
                                selectedIcon: const Icon(Icons.insights_rounded),
                                label: Text(_uiText(
                                  en: 'Stats',
                                  ar: 'إحصاء',
                                  fr: 'Stats',
                                  es: 'Stats',
                                  de: 'Stats',
                                  it: 'Stats',
                                  ru: 'Стат',
                                  zh: '统计',
                                )),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.tune_outlined),
                                selectedIcon: const Icon(Icons.tune_rounded),
                                label: Text(l.ownerTabSettings),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.flight_land_outlined),
                                selectedIcon: const Icon(Icons.flight_land_rounded),
                                label: Text(l.operatorTabTodaysArrivals),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(Icons.apartment_outlined),
                                selectedIcon: const Icon(Icons.apartment_rounded),
                                label: Text(l.ownerTabHostelB2b),
                              ),
                            ];
                            final tabView = TabBarView(
                              controller: tc,
                              children: [
                                RepaintBoundary(child: _buildDashboardTab(l)),
                                RepaintBoundary(child: _buildLiveOrdersTab(l)),
                                RepaintBoundary(child: _buildDriversTab(l)),
                                RepaintBoundary(child: _buildWalletsTabOnly(l)),
                                RepaintBoundary(child: _buildRatingsTabOnly(l)),
                                RepaintBoundary(child: _buildAnalyticsTab(l)),
                                RepaintBoundary(child: _buildSettingsTab(l)),
                                RepaintBoundary(child: _buildArrivalsTab(l)),
                                RepaintBoundary(child: _buildB2bTab(l)),
                              ],
                            );
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OwnerNavigationRail(
                                    controller: tc,
                                    destinations: destinations,
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: OwnerColors.border,
                                  ),
                                  Expanded(child: tabView),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: OwnerColors.charcoal,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: TabBar(
                                    controller: tc,
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    indicatorColor: OwnerColors.yellow,
                                    indicatorWeight: 3,
                                    labelColor: OwnerColors.yellow,
                                    unselectedLabelColor: Colors.white38,
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.2,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                    tabs: [
                                      Tab(
                                        text: _uiText(
                                          en: 'Home',
                                          ar: 'رئيسية',
                                          fr: 'Accueil',
                                          es: 'Inicio',
                                          de: 'Home',
                                          it: 'Home',
                                          ru: 'Главная',
                                          zh: '首页',
                                        ),
                                      ),
                                      Tab(
                                        text: _uiText(
                                          en: 'Live',
                                          ar: 'مباشر',
                                          fr: 'Live',
                                          es: 'Live',
                                          de: 'Live',
                                          it: 'Live',
                                          ru: 'Онлайн',
                                          zh: '实时',
                                        ),
                                      ),
                                      Tab(
                                        text: _uiText(
                                          en: 'Fleet',
                                          ar: 'أسطول',
                                          fr: 'Flotte',
                                          es: 'Flota',
                                          de: 'Flotte',
                                          it: 'Flotta',
                                          ru: 'Флот',
                                          zh: '车队',
                                        ),
                                      ),
                                      Tab(
                                        text: _uiText(
                                          en: 'Wallets',
                                          ar: 'محافظ',
                                          fr: 'Wallets',
                                          es: 'Carteras',
                                          de: 'Wallets',
                                          it: 'Wallet',
                                          ru: 'Кошельки',
                                          zh: '钱包',
                                        ),
                                      ),
                                      Tab(
                                        text: _uiText(
                                          en: 'Ratings',
                                          ar: 'تقييم',
                                          fr: 'Notes',
                                          es: 'Notas',
                                          de: 'Rating',
                                          it: 'Voti',
                                          ru: 'Рейтинг',
                                          zh: '评分',
                                        ),
                                      ),
                                      Tab(
                                        text: _uiText(
                                          en: 'Stats',
                                          ar: 'إحصاء',
                                          fr: 'Stats',
                                          es: 'Stats',
                                          de: 'Stats',
                                          it: 'Stats',
                                          ru: 'Аналит',
                                          zh: '统计',
                                        ),
                                      ),
                                      Tab(text: l.ownerTabSettings),
                                      Tab(text: l.operatorTabTodaysArrivals),
                                      Tab(text: l.ownerTabHostelB2b),
                                    ],
                                  ),
                                ),
                                Expanded(child: tabView),
                              ],
                            );
                          },
                        ),
                      ),
                      if (_message != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: OwnerColors.dangerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: OwnerColors.danger.withOpacity(0.3))),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: OwnerColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_message!,
                                    style: const TextStyle(
                                        color: OwnerColors.danger, fontSize: 13)))
                          ]),
                        ),
                    ]),
    );
  }
}
