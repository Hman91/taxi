import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';
import 'ride_chat_screen.dart';

class AppDriverScreen extends StatefulWidget {
  const AppDriverScreen({super.key});

  @override
  State<AppDriverScreen> createState() => _AppDriverScreenState();
}

class _AppDriverScreenState extends State<AppDriverScreen> {
  final _api = TaxiAppService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _token;
  int? _userId;
  List<Ride> _rides = [];
  String? _message;
  bool _busy = false;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginApp(
        email: _email.text.trim(),
        password: _password.text,
      );
      _token = r.accessToken;
      _userId = r.userId;
      await _refreshRides();
    } on TaxiAccountDisabledException {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _message = l.accountDisabledContactAdmin);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _api.registerAppUser(
        email: _email.text.trim(),
        password: _password.text,
        role: 'driver',
      );
      await _login();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshRides() async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      final list = await _api.listRides(t);
      setState(() {
        _rides = list;
        _message = null;
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.acceptRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.rejectRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.startRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(Ride r) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.completeRide(token: t, rideId: r.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat(Ride ride) async {
    final l = AppLocalizations.of(context)!;
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    setState(() => _busy = true);
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatUnavailable)));
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: info.conversationId,
          ),
        ),
      );
      await _refreshRides();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    setState(() {
      _token = null;
      _userId = null;
      _rides = [];
      _message = null;
    });
  }

  List<Widget> _actionsFor(Ride r) {
    final l10n = AppLocalizations.of(context)!;
    final w = <Widget>[];
    if (r.status == 'pending') {
      w.add(TextButton(onPressed: _busy ? null : () => _accept(r), child: Text(l10n.acceptRide)));
    }
    if (r.status == 'accepted' || r.status == 'ongoing') {
      w.add(TextButton(onPressed: _busy ? null : () => _reject(r), child: Text(l10n.rejectRide)));
    }
    if (r.status == 'accepted') {
      w.add(TextButton(onPressed: _busy ? null : () => _start(r), child: Text(l10n.startRide)));
    }
    if (r.status == 'ongoing') {
      w.add(TextButton(onPressed: _busy ? null : () => _complete(r), child: Text(l10n.completeRide)));
    }
    w.add(TextButton(onPressed: _busy ? null : () => _openChat(r), child: Text(l10n.openChatButton)));
    return w;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appDriverTitle),
        actions: [
          if (_token != null) ...[
            IconButton(onPressed: _busy ? null : _refreshRides, icon: const Icon(Icons.refresh)),
            TextButton(onPressed: _logout, child: Text(l.logoutApp)),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_token == null) ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.emailLabel),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passwordLabel),
            ),
            FilledButton(onPressed: _busy ? null : _login, child: Text(l.signInApp)),
            TextButton(onPressed: _busy ? null : _register, child: Text(l.registerDriverAccount)),
          ] else ...[
            Text(l.driverPendingRides, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_rides.isEmpty) Text(l.noRidesYetApp),
            ..._rides.map(
              (r) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.adminRideRow(r.pickup, r.destination)),
                      Text(l.rideStatusFmt(r.status)),
                      Wrap(spacing: 4, children: _actionsFor(r)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
