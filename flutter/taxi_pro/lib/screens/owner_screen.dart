import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';

/// Owner HQ — tabs: arrivals (demo), treasury, route & commission settings, B2B.
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen>
    with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _secretController = TextEditingController(text: 'NabeulGold2026');
  TabController? _tabController;

  bool _obscurePassword = true;
  String? _token;
  String? _message;
  bool _busy = false;

  Map<String, dynamic>? _metrics;
  Map<String, dynamic>? _adminMetrics;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  List<Map<String, dynamic>> _fareRoutes = [];
  List<Map<String, dynamic>> _driverPinAccounts = [];
  final Map<int, TextEditingController> _fareCtrls = {};
  double _commissionDemoPercent = 10.0;

  TextStyle _headingStyle() => const TextStyle(
        color: TaxiAppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  void _syncFareControllers(List<Map<String, dynamic>> routes) {
    final ids = <int>{};
    for (final r in routes) {
      final idRaw = r['id'];
      if (idRaw is! num) continue;
      final id = idRaw.toInt();
      ids.add(id);
      final bf = r['base_fare'];
      final text =
          bf is num ? bf.toStringAsFixed(2) : bf?.toString() ?? '0.00';
      if (_fareCtrls.containsKey(id)) {
        _fareCtrls[id]!.text = text;
      } else {
        _fareCtrls[id] = TextEditingController(text: text);
      }
    }
    for (final k in _fareCtrls.keys.toList()) {
      if (!ids.contains(k)) {
        _fareCtrls.remove(k)?.dispose();
      }
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
    return line;
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(
          role: 'owner', secret: _secretController.text.trim());
      _token = r.accessToken;
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
    setState(() => _busy = true);
    try {
      final m = await _api.ownerMetrics(t);
      final trips = await _api.listTrips(t);
      final adminRides = await _api.listAdminRides(t);
      final adminUsers = await _api.listAdminUsers(t);
      final adminB2b = await _api.listAdminB2bTenants(t);
      final adminB2bBookings = await _api.listAdminB2bBookings(t);
      final adminMetrics = await _api.adminOwnerMetrics(t);
      final flights = await _api.listAdminTunisiaFlightArrivals(t);
      final fareRoutes = await _api.listAdminFareRoutes(t);
      final driverPins = await _api.listAdminDriverPinAccounts(t);
      if (!mounted) return;
      setState(() {
        _metrics = m;
        _adminMetrics = adminMetrics;
        _trips = trips
            .map(
              (e) => {
                'id': e.id,
                'date': e.date,
                'route': e.route,
                'fare': e.fare,
                'commission': e.commission,
                'type': e.type,
              },
            )
            .toList();
        _adminRides = adminRides;
        _adminUsers = adminUsers;
        _adminB2b = adminB2b;
        _adminB2bBookings = adminB2bBookings;
        _flightArrivals = flights;
        _fareRoutes = fareRoutes;
        _driverPinAccounts = driverPins;
        _syncFareControllers(fareRoutes);
        _message = null;
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFareRoute(int routeId) async {
    final t = _token;
    final ctrl = _fareCtrls[routeId];
    if (t == null || ctrl == null) return;
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0) {
      setState(() => _message = 'Invalid fare');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.patchAdminFareRoute(
        token: t,
        routeId: routeId,
        baseFare: v,
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final t = _token;
    if (t == null) return;
    final idRaw = user['id'];
    if (idRaw is! num) return;
    final current = (user['is_enabled'] == true);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.setAdminUserEnabled(
        token: t,
        userId: idRaw.toInt(),
        isEnabled: !current,
      );
      await _refreshAll();
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
        token: t,
        tenantId: idRaw.toInt(),
        isEnabled: !current,
      );
      await _refreshAll();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.adminLoadRidesBtn),
          ),
          const SizedBox(height: 12),
          Text(
            l.operatorArrivalsDemoHeading,
            style: _headingStyle(),
          ),
          const SizedBox(height: 10),
          if (_flightArrivals.isEmpty)
            Text(l.operatorNoFlightArrivals)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.blueGrey.shade700),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                border: TableBorder.all(color: Colors.grey.shade400),
                columns: [
                  DataColumn(label: Text(l.operatorColFlightNumber)),
                  DataColumn(label: Text(l.operatorColDepartureAirport)),
                  DataColumn(label: Text(l.operatorColTakeoffTime)),
                  DataColumn(label: Text(l.operatorColExpectedArrival)),
                  DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                ],
                rows: _flightArrivals.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      i.isEven ? Colors.grey.shade50 : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(
                        r['flight_number']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['departure_airport']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['takeoff_time']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        r['expected_arrival']?.toString() ?? '',
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                      DataCell(Text(
                        _arrivalAirportLabel(r),
                        style: const TextStyle(
                            color: TaxiAppColors.textStrong),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTreasuryTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_metrics != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.payments, size: 16),
                  label: Text(
                    l.ownerProfitChip(
                      _metrics!['total_commission']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.route, size: 16),
                  label: Text(
                    l.ownerTripsCountChip(
                      _metrics!['trip_count']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: Text(
                    l.ownerRatingChip(
                      _metrics!['rating_average']?.toString() ?? '0',
                      _metrics!['rating_count']?.toString() ?? '0',
                    ),
                  ),
                ),
              ],
            ),
          if (_adminMetrics != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.payments, size: 16),
                  label: Text(
                    l.ownerCommissionChip(
                      _adminMetrics!['total_commission']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.route, size: 16),
                  label: Text(
                    l.ownerTripsCountChip(
                      _adminMetrics!['trip_count']?.toString() ?? '0',
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: Text(
                    l.ownerRatingChip(
                      _adminMetrics!['rating_average']?.toString() ?? '0',
                      _adminMetrics!['rating_count']?.toString() ?? '0',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.adminLoadOwnerMetricsBtn),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: TaxiAppColors.text,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.ownerDriverPinWalletsHeading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TaxiAppColors.textStrong,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_driverPinAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.ownerDriverPinWalletsEmpty,
                style: const TextStyle(color: TaxiAppColors.textSoft),
              ),
            )
          else
            ..._driverPinAccounts.map(
              (d) => Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x55991B1B)),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.local_taxi_outlined,
                    color: TaxiAppColors.text,
                  ),
                  title: Text(
                    '${d['driver_name'] ?? ''} (${d['phone'] ?? ''})'.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TaxiAppColors.textStrong,
                    ),
                  ),
                  subtitle: Text(
                    _ownerDriverPinSubtitle(l, d),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: TaxiAppColors.textSoft,
                    ),
                  ),
                ),
              ),
            ),
          const Divider(height: 28),
          Text(
            l.ownerVaultHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_trips.isEmpty) Text(l.noTripsYet),
          ..._trips.map(
            (t) => Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0x55991B1B)),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long,
                    color: TaxiAppColors.text),
                title: Text(
                  l.ownerTripRouteFareRow(
                    t['route']?.toString() ?? '',
                    t['fare']?.toString() ?? '',
                  ),
                  style: const TextStyle(
                    color: TaxiAppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l.tripListSubtitle(
                    t['date'] as String,
                    t['commission'].toString(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.adminRidesHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
          ..._adminRides.take(30).map(
                (r) => Card(
                  color: Colors.white,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      localizedRideRouteRow(
                        l,
                        r['pickup']?.toString() ?? '',
                        r['destination']?.toString() ?? '',
                      ),
                    ),
                    subtitle: Text(
                      l.rideStatusFmt(
                        localizedRideStatusLabel(
                          l,
                          r['status']?.toString(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: TaxiAppColors.cardFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: TaxiAppColors.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.percent,
                          color: TaxiAppColors.text, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.ownerSettingsCommissionLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TaxiAppColors.textStrong,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.ownerSettingsCommissionHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TaxiAppColors.textSoft,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _commissionDemoPercent.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: TaxiAppColors.text,
                      ),
                    ),
                  ),
                  Slider(
                    value: _commissionDemoPercent.clamp(0.0, 40.0),
                    min: 0,
                    max: 40,
                    divisions: 400,
                    label: _commissionDemoPercent.toStringAsFixed(1),
                    activeColor: TaxiAppColors.text,
                    inactiveColor: TaxiAppColors.textSoft.withValues(alpha: 0.35),
                    onChanged: _busy
                        ? null
                        : (v) =>
                            setState(() => _commissionDemoPercent = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.ownerSettingsRouteFaresHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (_fareRoutes.isEmpty)
            Text(l.adminNoRidesLoaded)
          else
            ..._fareRoutes.map((r) {
              final id = (r['id'] as num).toInt();
              final label = localizedRideRouteRow(
                l,
                r['start']?.toString() ?? '',
                r['destination']?.toString() ?? '',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0x55991B1B)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TaxiAppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final c = _fareCtrls[id];
                                      if (c == null) return;
                                      final v = double.tryParse(c.text
                                              .replaceAll(',', '.')) ??
                                          0;
                                      c.text = (v > 1 ? v - 1 : 0)
                                          .toStringAsFixed(2);
                                      setState(() {});
                                    },
                              icon: const Icon(Icons.remove_rounded),
                              color: TaxiAppColors.textStrong,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _fareCtrls[id],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.,]')),
                                ],
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final c = _fareCtrls[id];
                                      if (c == null) return;
                                      final v = double.tryParse(c.text
                                              .replaceAll(',', '.')) ??
                                          0;
                                      c.text = (v + 1).toStringAsFixed(2);
                                      setState(() {});
                                    },
                              icon: const Icon(Icons.add_rounded),
                              color: TaxiAppColors.textStrong,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: TaxiAppColors.buttonDark,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _busy ? null : () => _saveFareRoute(id),
                            child: Text(l.ownerSaveRouteFare),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildB2bTab(AppLocalizations l) {
    return RefreshIndicator(
      color: TaxiAppColors.text,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonal(
            onPressed: _busy ? null : _refreshAll,
            child: Text(l.operatorRefreshCorporateBookings),
          ),
          const SizedBox(height: 16),
          Text(
            l.ownerAdminOversightHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          if (_adminB2bBookings.isEmpty) Text(l.noTripsLoaded),
          ..._adminB2bBookings.map(
            (b) => Card(
              color: Colors.white,
              child: ListTile(
                dense: true,
                title: Text(b['route']?.toString() ?? ''),
                subtitle: Text(
                  l.adminB2bBookingRowSubtitle(
                    b['guest_name']?.toString() ?? '',
                    b['room_number']?.toString() ?? '-',
                    b['fare']?.toString() ?? '',
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 28),
          Text(
            l.ownerTabHostelB2b,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          ..._adminB2b.map(
            (b) => SwitchListTile(
              dense: true,
              title: Text(
                  b['label']?.toString() ?? b['code']?.toString() ?? ''),
              subtitle: Text(b['code']?.toString() ?? ''),
              value: b['is_enabled'] == true,
              onChanged: _busy ? null : (_) => _toggleB2b(b),
            ),
          ),
          const Divider(height: 28),
          Text(
            l.operatorUserAccountsHeading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TaxiAppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          ..._adminUsers.map(
            (u) => SwitchListTile(
              dense: true,
              title: Text(u['email']?.toString() ?? ''),
              subtitle: Text(u['role']?.toString() ?? ''),
              value: u['is_enabled'] == true,
              onChanged: _busy ? null : (_) => _toggleUser(u),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.owner);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _secretController.dispose();
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
      appBar: AppBar(
        title: Text(l.ownerAppBarTitle),
        actions: [
          const LocalePopupMenuButton(uiRole: AppUiRole.owner),
          if (_token != null)
            IconButton(
              onPressed: _busy ? null : _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _token == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.ownerPasswordCeoLabel,
                  style: const TextStyle(
                    color: TaxiAppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _secretController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l.ownerPassword,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TaxiAppColors.buttonDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy ? null : _login,
                    child: Text(l.loginLoadDashboard),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            )
          : tc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF34D399)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF065F46)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.ownerWelcomeHq,
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: TaxiAppColors.appBarFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TaxiAppColors.cardBorder),
                        ),
                        child: TabBar(
                          controller: tc,
                          isScrollable: true,
                          indicatorColor: TaxiAppColors.text,
                          indicatorWeight: 3,
                          labelColor: TaxiAppColors.text,
                          unselectedLabelColor: TaxiAppColors.textStrong,
                          tabs: [
                            Tab(text: '✈️  ${l.operatorTabTodaysArrivals}'),
                            Tab(text: '💰 ${l.ownerTabTreasury}'),
                            Tab(text: '⚙️ ${l.ownerTabSettings}'),
                            Tab(text: '🏨 ${l.ownerTabHostelB2b}'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tc,
                        children: [
                          _buildArrivalsTab(l),
                          _buildTreasuryTab(l),
                          _buildSettingsTab(l),
                          _buildB2bTab(l),
                        ],
                      ),
                    ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _message!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
    );
  }
}
