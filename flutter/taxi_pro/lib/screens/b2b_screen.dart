import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

/// Corporate portal: login matches API; booking is UI-only until B2B billing API exists.
class B2bScreen extends StatefulWidget {
  const B2bScreen({super.key});

  @override
  State<B2bScreen> createState() => _B2bScreenState();
}

class _B2bScreenState extends State<B2bScreen> {
  final _api = TaxiAppService();
  final _secretController = TextEditingController(text: 'Biz2026');
  final _guestController = TextEditingController();
  final _roomController = TextEditingController();
  Map<String, double> _fares = {};
  String? _routeKey;
  String? _token;
  String? _message;
  bool _busy = false;
  bool _ok = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth =
          await _api.login(role: 'b2b', secret: _secretController.text.trim());
      final fares = await _api.getAirportFares();
      setState(() {
        _ok = true;
        _token = auth.accessToken;
        _fares = fares;
        _routeKey = fares.keys.isNotEmpty ? fares.keys.first : null;
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _message = e.toString();
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  void _bookGuest() {
    final l = AppLocalizations.of(context)!;
    final guest = _guestController.text.trim();
    final route = _routeKey;
    final token = _token;
    if (guest.isEmpty || route == null || token == null) {
      setState(() => _message = l.loginFirst);
      return;
    }
    final room = _roomController.text.trim();
    final fare = (_fares[route] ?? 0).toDouble();
    _api
        .createB2bBooking(
      token: token,
      route: route,
      guestName: guest,
      roomNumber: room,
      fare: fare,
      sourceCode: _secretController.text.trim(),
    )
        .then((booking) {
      if (!mounted) return;
      setState(() {
        _message =
            '${l.requestRideButton}: #${booking['id']} • $guest • $route';
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    _guestController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.b2bTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: InputDecoration(labelText: l.companyCode),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(l.verifyCompanyCode),
          ),
          if (_ok)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.b2bConnectedStub),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _guestController,
                    decoration: InputDecoration(labelText: l.ridePickupLabel),
                  ),
                  TextField(
                    controller: _roomController,
                    decoration:
                        InputDecoration(labelText: l.rideDestinationLabel),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(labelText: l.route),
                    child: DropdownButton<String>(
                      value: _routeKey,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _fares.keys
                          .map(
                              (k) => DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (v) => setState(() => _routeKey = v),
                    ),
                  ),
                  if (_routeKey != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${l.fareDt((_fares[_routeKey] ?? 0).toStringAsFixed(2))} • 5%',
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _busy ? null : _bookGuest,
                    child: Text(l.requestRideButton),
                  ),
                ],
              ),
            ),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
