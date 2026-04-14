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
  Map<String, dynamic>? _adminMetrics;
  String? _message;
  bool _busy = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(role: 'owner', secret: _secretController.text.trim());
      _token = r.accessToken;
      await _refresh();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      final m = await _api.ownerMetrics(t);
      final trips = await _api.listTrips(t);
      setState(() {
        _metrics = m;
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
        _message = null;
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadAdminRides() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.listAdminRides(t);
      setState(() => _adminRides = r);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadAdminDrivers() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.listAdminDriverLocations(t);
      setState(() => _adminDrivers = r);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadAdminMetrics() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final m = await _api.adminOwnerMetrics(t);
      setState(() => _adminMetrics = m);
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
              onPressed: _busy ? null : _refresh,
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
          Text(l.tripsHeading, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(l.adminOversightHeading, style: const TextStyle(fontWeight: FontWeight.bold)),
            FilledButton.tonal(
              onPressed: _busy ? null : _loadAdminMetrics,
              child: Text(l.adminLoadOwnerMetricsBtn),
            ),
            if (_adminMetrics != null) ...[
              const SizedBox(height: 8),
              Text(l.commissionLabel(_adminMetrics!['total_commission'].toString())),
              Text(l.tripsCount(_adminMetrics!['trip_count'].toString())),
              Text(l.avgRatingLabel(
                _adminMetrics!['rating_average'].toString(),
                _adminMetrics!['rating_count'].toString(),
              )),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy ? null : _loadAdminRides,
                    child: Text(l.adminLoadRidesBtn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy ? null : _loadAdminDrivers,
                    child: Text(l.adminLoadDriversBtn),
                  ),
                ),
              ],
            ),
            Text(l.adminRidesHeading, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            Text(l.adminDriversHeading, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          ],
          if (_message != null) Text(_message!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
