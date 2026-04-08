import 'package:flutter/material.dart';

import '../api/client.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  final _api = TaxiApiClient();
  final _secretController = TextEditingController(text: 'Operator2026');
  String? _token;
  String? _message;
  List<Map<String, dynamic>> _trips = [];
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

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator / Dispatch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Operator code'),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: const Text('Login & load trips'),
          ),
          const Divider(),
          if (_trips.isEmpty)
            const Text('No trips loaded'),
          ..._trips.map(
            (t) => ListTile(
              title: Text('${t['route']}'),
              subtitle: Text('${t['date']} · ${t['fare']} DT'),
            ),
          ),
          if (_message != null) Text(_message!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
