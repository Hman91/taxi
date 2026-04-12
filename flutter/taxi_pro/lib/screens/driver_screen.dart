import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final _api = TaxiAppService();
  final _secretController = TextEditingController(text: 'Driver2026');
  final _routeController = TextEditingController();
  final _fareController = TextEditingController(text: '20');
  static const _payCash = 'كاش / بطاقة';
  static const _payB2b = 'فاتورة شركة (B2B)';
  String _payType = _payCash;
  String? _token;
  String? _message;
  bool _busy = false;

  Future<void> _login() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(role: 'driver', secret: _secretController.text.trim());
      setState(() {
        _token = r.accessToken;
        _message = l.loggedInAs(r.role);
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _submitTrip() async {
    final l = AppLocalizations.of(context)!;
    final t = _token;
    if (t == null) {
      setState(() => _message = l.loginFirst);
      return;
    }
    final fare = double.tryParse(_fareController.text.trim());
    if (fare == null || fare < 0) {
      setState(() => _message = l.invalidFare);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final trip = await _api.createTrip(
        token: t,
        route: _routeController.text.trim(),
        fare: fare,
        type: _payType,
      );
      setState(() => _message = l.tripRecorded(trip.id, trip.commission.toString()));
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _secretController.dispose();
    _routeController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.driverTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: InputDecoration(labelText: l.driverCode),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(l.login),
          ),
          if (_token != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.sessionActive, style: TextStyle(color: Colors.green.shade800)),
            ),
          const Divider(height: 32),
          TextField(
            controller: _routeController,
            decoration: InputDecoration(labelText: l.route),
          ),
          TextField(
            controller: _fareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.fareAmount),
          ),
          InputDecorator(
            decoration: InputDecoration(labelText: l.paymentType),
            child: DropdownButton<String>(
              value: _payType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: _payCash, child: Text(l.cashOrCard)),
                DropdownMenuItem(value: _payB2b, child: Text(l.b2bInvoice)),
              ],
              onChanged: (v) => setState(() => _payType = v ?? _payType),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submitTrip,
            child: Text(l.completeTripCommission),
          ),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
        ],
      ),
    );
  }
}
