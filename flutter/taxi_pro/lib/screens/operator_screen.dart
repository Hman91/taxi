import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  final _api = TaxiAppService();
  final _secretController = TextEditingController(text: 'Op2026');
  String? _token;
  String? _message;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _adminRides = [];
  List<Map<String, dynamic>> _adminDrivers = [];
  bool _busy = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(role: 'operator', secret: _secretController.text.trim());
      _token = r.accessToken;
      final trips = await _api.listTrips(_token!);
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

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.operatorTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: InputDecoration(labelText: l.operatorCode),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(l.loginLoadTrips),
          ),
          const Divider(),
          if (_trips.isEmpty) Text(l.noTripsLoaded),
          ..._trips.map(
            (t) => ListTile(
              title: Text('${t['route']}'),
              subtitle: Text(l.operatorTripSubtitle(
                t['date'] as String,
                t['fare'].toString(),
              )),
            ),
          ),
          if (_token != null) ...[
            const Divider(),
            Text(l.adminOversightHeading, style: const TextStyle(fontWeight: FontWeight.bold)),
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
