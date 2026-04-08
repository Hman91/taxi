import 'package:flutter/material.dart';

import '../api/client.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final _api = TaxiApiClient();
  final _secretController = TextEditingController(text: 'Driver2026');
  final _routeController = TextEditingController();
  final _fareController = TextEditingController(text: '20');
  String _payType = 'كاش / بطاقة';
  String? _token;
  String? _message;
  bool _busy = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.login(role: 'driver', secret: _secretController.text.trim());
      setState(() {
        _token = r.accessToken;
        _message = 'Logged in as ${r.role}';
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _submitTrip() async {
    final t = _token;
    if (t == null) {
      setState(() => _message = 'Login first');
      return;
    }
    final fare = double.tryParse(_fareController.text.trim());
    if (fare == null || fare < 0) {
      setState(() => _message = 'Invalid fare');
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
      setState(() => _message = 'Trip #${trip.id} recorded. Commission ${trip.commission} DT');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Driver code'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: const Text('Login'),
          ),
          if (_token != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Session active', style: TextStyle(color: Colors.green.shade800)),
            ),
          const Divider(height: 32),
          TextField(
            controller: _routeController,
            decoration: const InputDecoration(labelText: 'Route'),
          ),
          TextField(
            controller: _fareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fare (DT)'),
          ),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Payment type'),
            child: DropdownButton<String>(
              value: _payType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'كاش / بطاقة', child: Text('Cash / card')),
                DropdownMenuItem(value: 'فاتورة شركة (B2B)', child: Text('B2B invoice')),
              ],
              onChanged: (v) => setState(() => _payType = v ?? _payType),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submitTrip,
            child: const Text('Complete trip (10% commission)'),
          ),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
        ],
      ),
    );
  }
}
