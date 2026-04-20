import 'package:flutter/material.dart';

import '../app_locale.dart' show AppUiRole, restoreUiRoleLocale;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../services/taxi_app_service.dart';
import '../widgets/locale_popup_menu.dart';

class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  final _api = TaxiAppService();
  final _secretController = TextEditingController(text: 'NabeulGold2026');
  String? _token;
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminDrivers = [];
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _adminB2b = [];
  List<Map<String, dynamic>> _adminB2bBookings = [];
  Map<String, dynamic>? _adminMetrics;
  String? _message;
  bool _busy = false;

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
      final adminDrivers = await _api.listAdminDriverLocations(t);
      final adminUsers = await _api.listAdminUsers(t);
      final adminB2b = await _api.listAdminB2bTenants(t);
      final adminB2bBookings = await _api.listAdminB2bBookings(t);
      final adminMetrics = await _api.adminOwnerMetrics(t);
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
        _adminDrivers = adminDrivers;
        _adminUsers = adminUsers;
        _adminB2b = adminB2b;
        _adminB2bBookings = adminB2bBookings;
        _message = null;
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
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
      setState(() => _busy = false);
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
      setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.owner);
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.ownerHqPortalHeading,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _secretController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l.ownerPassword),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Text(l.loginLoadDashboard),
                  ),
                ],
              ),
            ),
          ),
          if (_metrics != null) ...[
            const SizedBox(height: 16),
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
          ],
          const Divider(),
          Text(
            l.ownerVaultHeading,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_trips.isEmpty) Text(l.noTripsYet),
          ..._trips.map(
            (t) => Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long),
                title: Text(
                  l.ownerTripRouteFareRow(
                    t['route']?.toString() ?? '',
                    t['fare']?.toString() ?? '',
                  ),
                ),
                subtitle: Text(l.tripListSubtitle(
                  t['date'] as String,
                  t['commission'].toString(),
                )),
              ),
            ),
          ),
          if (_token != null) ...[
            const Divider(),
            Text(
              l.ownerAdminOversightHeading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            FilledButton.tonal(
              onPressed: _busy ? null : _refreshAll,
              child: Text(l.adminLoadOwnerMetricsBtn),
            ),
            if (_adminMetrics != null) ...[
              const SizedBox(height: 8),
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
            const Divider(),
            Text('🎧 ${l.adminRidesHeading}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
            ..._adminRides.map(
              (r) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(localizedRideRouteRow(
                    l,
                    r['pickup']?.toString() ?? '',
                    r['destination']?.toString() ?? '',
                  )),
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
            Text('👥 ${l.adminDriversHeading}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_adminDrivers.isEmpty) Text(l.adminNoDriversData),
            ..._adminDrivers.map(
              (d) => ListTile(
                dense: true,
                title: Text(d['email']?.toString() ?? ''),
                subtitle: Text(
                  l.driverLocationRow(
                    d['last_lat']?.toString() ?? '—',
                    d['last_lng']?.toString() ?? '—',
                  ),
                ),
              ),
            ),
            const Divider(),
            ..._adminUsers.map(
              (u) => SwitchListTile(
                dense: true,
                title: Text(u['email']?.toString() ?? ''),
                subtitle: Text(u['role']?.toString() ?? ''),
                value: u['is_enabled'] == true,
                onChanged: _busy ? null : (_) => _toggleUser(u),
              ),
            ),
            const Divider(),
            ..._adminB2bBookings.map(
              (b) => ListTile(
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
            const Divider(),
            ..._adminB2b.map(
              (b) => SwitchListTile(
                dense: true,
                title:
                    Text(b['label']?.toString() ?? b['code']?.toString() ?? ''),
                subtitle: Text(b['code']?.toString() ?? ''),
                value: b['is_enabled'] == true,
                onChanged: _busy ? null : (_) => _toggleB2b(b),
              ),
            ),
          ],
          if (_message != null)
            Text(_message!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
