import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

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
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.ownerTitle),
        actions: [
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
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: InputDecoration(labelText: l.ownerPassword),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(l.loginLoadDashboard),
          ),
          if (_metrics != null) ...[
            const SizedBox(height: 16),
            Text(l.commissionLabel(_metrics!['total_commission'].toString())),
            Text(l.tripsCount(_metrics!['trip_count'].toString())),
            Text(l.avgRatingLabel(
              _metrics!['rating_average'].toString(),
              _metrics!['rating_count'].toString(),
            )),
          ],
          const Divider(),
          Text(l.tripsHeading,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_trips.isEmpty) Text(l.noTripsYet),
          ..._trips.map(
            (t) => ListTile(
              dense: true,
              title: Text('${t['route']} — ${t['fare']} DT'),
              subtitle: Text(l.tripListSubtitle(
                t['date'] as String,
                t['commission'].toString(),
              )),
            ),
          ),
          if (_token != null) ...[
            const Divider(),
            Text(l.adminOversightHeading,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            FilledButton.tonal(
              onPressed: _busy ? null : _refreshAll,
              child: Text(l.adminLoadOwnerMetricsBtn),
            ),
            if (_adminMetrics != null) ...[
              const SizedBox(height: 8),
              Text(l.commissionLabel(
                  _adminMetrics!['total_commission'].toString())),
              Text(l.tripsCount(_adminMetrics!['trip_count'].toString())),
              Text(l.avgRatingLabel(
                _adminMetrics!['rating_average'].toString(),
                _adminMetrics!['rating_count'].toString(),
              )),
            ],
            const Divider(),
            Text(l.adminRidesHeading,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_adminRides.isEmpty) Text(l.adminNoRidesLoaded),
            ..._adminRides.map(
              (r) => ListTile(
                dense: true,
                title: Text(l.adminRideRow(
                  r['pickup']?.toString() ?? '',
                  r['destination']?.toString() ?? '',
                )),
                subtitle: Text(l.rideStatusFmt(r['status']?.toString() ?? '')),
              ),
            ),
            Text(l.adminDriversHeading,
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
                  '${b['guest_name'] ?? ''} • ${b['room_number'] ?? '-'} • ${b['fare']} DT',
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
