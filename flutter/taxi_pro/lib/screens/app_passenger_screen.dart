import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';
import 'ride_chat_screen.dart';

class AppPassengerScreen extends StatefulWidget {
  const AppPassengerScreen({super.key});

  @override
  State<AppPassengerScreen> createState() => _AppPassengerScreenState();
}

class _AppPassengerScreenState extends State<AppPassengerScreen> {
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
        role: 'user',
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

  Future<void> _requestRide() async {
    final l = AppLocalizations.of(context)!;
    final pickup = TextEditingController();
    final dest = TextEditingController();
    String? pu;
    String? de;
    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.requestRideButton),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pickup,
                decoration: InputDecoration(labelText: l.ridePickupLabel),
              ),
              TextField(
                controller: dest,
                decoration: InputDecoration(labelText: l.rideDestinationLabel),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.genericCancel)),
            FilledButton(
              onPressed: () {
                pu = pickup.text.trim();
                de = dest.text.trim();
                Navigator.pop(ctx, true);
              },
              child: Text(l.requestRideButton),
            ),
          ],
        ),
      );
    } finally {
      pickup.dispose();
      dest.dispose();
    }
    if (ok != true || !mounted) return;
    final t = _token;
    if (t == null || pu == null || de == null) return;
    setState(() => _busy = true);
    try {
      await _api.createRide(token: t, pickup: pu!, destination: de!);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.cancelRide(token: t, rideId: ride.id);
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
        title: Text(l.appPassengerTitle),
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
            FilledButton(
              onPressed: _busy ? null : _login,
              child: Text(l.signInApp),
            ),
            TextButton(
              onPressed: _busy ? null : _register,
              child: Text(l.registerAppAccount),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _busy ? null : _requestRide,
              icon: const Icon(Icons.add_road),
              label: Text(l.requestRideButton),
            ),
            const SizedBox(height: 16),
            Text(l.myRidesHeading, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_rides.isEmpty) Text(l.noRidesYetApp),
            ..._rides.map(
              (r) => Card(
                child: ListTile(
                  title: Text(l.adminRideRow(r.pickup, r.destination)),
                  subtitle: Text(l.rideStatusFmt(r.status)),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (r.status != 'completed' && r.status != 'cancelled')
                        TextButton(
                          onPressed: _busy ? null : () => _cancelRide(r),
                          child: Text(l.cancelRidePassenger),
                        ),
                      TextButton(
                        onPressed: _busy ? null : () => _openChat(r),
                        child: Text(l.openChatButton),
                      ),
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
