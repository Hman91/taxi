import 'package:flutter/material.dart';

import '../api/client.dart';

/// Corporate portal: login matches API; booking is UI-only until B2B billing API exists.
class B2bScreen extends StatefulWidget {
  const B2bScreen({super.key});

  @override
  State<B2bScreen> createState() => _B2bScreenState();
}

class _B2bScreenState extends State<B2bScreen> {
  final _api = TaxiApiClient();
  final _secretController = TextEditingController(text: 'Biz2026');
  String? _message;
  bool _busy = false;
  bool _ok = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.login(role: 'b2b', secret: _secretController.text.trim());
      setState(() => _ok = true);
    } catch (e) {
      setState(() {
        _ok = false;
        _message = e.toString();
      });
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
      appBar: AppBar(title: const Text('B2B Corporate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _secretController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Company code'),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: const Text('Verify company code'),
          ),
          if (_ok)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Connected to monthly billing (stub). Ride requests and PDF invoice '
                'can be wired to the API in a follow-up.',
              ),
            ),
          if (_message != null) Text(_message!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
