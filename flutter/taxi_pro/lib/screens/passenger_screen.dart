import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../services/local_notification_service.dart';
import '../services/taxi_app_service.dart';
import 'ride_chat_screen.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _api = TaxiAppService();
  Map<String, double> _fares = {};
  String? _selectedStart;
  String? _selectedEnd;
  Map<String, dynamic>? _airportQuote;
  final _promoController = TextEditingController();
  final _chatController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _locationText;
  String? _locationPlaceName;
  String? _locationError;
  bool _locating = false;
  bool _isDisposed = false;
  int _rating = 0;
  _PassengerRequest? _activeRequest;
  String? _guestToken;
  int? _guestUserId;
  final List<Map<String, String>> _chatHistory = [];
  static String? _sessionGuestToken;
  static int? _sessionGuestUserId;
  static _PassengerRequest? _sessionActiveRequest;
  static const _taxiPhone = '+21600000000';
  static const Map<String, _ZoneCoord> _zoneCoords = {
    'مطار قرطاج': _ZoneCoord(36.8508, 10.2272),
    'مطار النفيضة': _ZoneCoord(36.0758, 10.4386),
    'مطار المنستير': _ZoneCoord(35.7581, 10.7547),
    'وسط سوسة': _ZoneCoord(35.8256, 10.63699),
    'الحمامات': _ZoneCoord(36.4000, 10.6167),
    'نابل': _ZoneCoord(36.4561, 10.7376),
    'القنطاوي': _ZoneCoord(35.8920, 10.5950),
  };

  @override
  void initState() {
    super.initState();
    _detectPassengerLocation();
    _restoreGuestSession();
    _loadFares();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (_isDisposed || !mounted) return;
    try {
      setState(fn);
    } catch (_) {
      // A late async callback can race with widget teardown on web.
      // Ignore state updates once the element is no longer active.
    }
  }

  Future<void> _detectPassengerLocation() async {
    _setStateIfMounted(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setStateIfMounted(() => _locationError = 'Location service is disabled.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStateIfMounted(() => _locationError = 'Location permission denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final nearestZone =
          _nearestZoneFor(position.latitude, position.longitude);
      _setStateIfMounted(() {
        _locationText =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _locationPlaceName = nearestZone;
        if (nearestZone != null &&
            _fares.isNotEmpty &&
            _startsFromFares(_fares).contains(nearestZone)) {
          _selectedStart = nearestZone;
          final ends = _endsForStart(_fares, nearestZone);
          _selectedEnd = ends.isNotEmpty ? ends.first : null;
          _airportQuote = null;
        }
      });
      await _quoteAirport();
    } catch (e) {
      _setStateIfMounted(() => _locationError = e.toString());
    } finally {
      _setStateIfMounted(() => _locating = false);
    }
  }

  Future<void> _loadFares() async {
    _setStateIfMounted(() {
      _loading = true;
      _error = null;
    });
    try {
      final fares = await _api.getAirportFares();
      final starts = _startsFromFares(fares);
      final start = starts.isNotEmpty ? starts.first : null;
      final ends =
          start == null ? const <String>[] : _endsForStart(fares, start);
      final end = ends.isNotEmpty ? ends.first : null;
      _setStateIfMounted(() {
        _fares = fares;
        _selectedStart = start;
        _selectedEnd = end;
        _loading = false;
      });
      if (_selectedStart != null && _selectedEnd != null) {
        await _quoteAirport();
      }
    } catch (e) {
      _setStateIfMounted(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _quoteAirport() async {
    final key = _routeKey;
    if (key == null) return;
    try {
      final q = await _api.quoteAirport(key);
      final promoCode = _promoController.text.trim();
      final baseFare = (q['base_fare'] as num).toDouble();
      final isNight = _isNightNow();
      var finalFare = baseFare;
      if (promoCode == 'WELCOME26') {
        finalFare = finalFare * 0.8;
      }
      if (isNight) {
        finalFare = finalFare * 1.5;
      }
      _setStateIfMounted(() => _airportQuote = q);
      if (_airportQuote == null) return;
      _airportQuote!['promo_code'] = promoCode;
      _airportQuote!['is_promo_applied'] = promoCode == 'WELCOME26';
      _airportQuote!['is_night'] = isNight;
      _airportQuote!['final_fare'] = double.parse(finalFare.toStringAsFixed(3));
    } catch (e) {
      _setStateIfMounted(() => _error = e.toString());
    }
  }

  Future<void> _submitRating() async {
    if (_rating < 1 || _rating > 5) return;
    final l = AppLocalizations.of(context)!;
    try {
      await _api.submitRating(_rating);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.thankYouFeedback)),
      );
      _setStateIfMounted(() => _rating = 0);
    } catch (e) {
      _setStateIfMounted(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _promoController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.passengerTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.requestRideButton),
              Tab(text: l.openChatButton),
              Tab(text: l.language),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _airportTab(context, l),
                  _chatTab(context, l),
                  _settingsTab(context, l),
                ],
              ),
      ),
    );
  }

  Widget _airportTab(BuildContext context, AppLocalizations l) {
    if (_error != null && _fares.isEmpty) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    final starts = _startsFromFares(_fares);
    final selectedStart =
        _selectedStart ?? (starts.isNotEmpty ? starts.first : null);
    final ends = selectedStart == null
        ? const <String>[]
        : _endsForStart(_fares, selectedStart);
    final selectedEnd = _selectedEnd ?? (ends.isNotEmpty ? ends.first : null);
    final q = _airportQuote;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.my_location),
            title: Text(_locationPlaceName ?? 'Your current location'),
            subtitle: Text(
              _locationPlaceName != null
                  ? '($_locationText)'
                  : (_locationText ??
                      (_locating
                          ? 'Detecting location...'
                          : (_locationError ?? 'Location unavailable'))),
            ),
            trailing: IconButton(
              tooltip: 'Refresh location',
              onPressed: _locating ? null : _detectPassengerLocation,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_fares.isNotEmpty && starts.isNotEmpty) ...[
          InputDecorator(
            decoration: InputDecoration(labelText: l.ridePickupLabel),
            child: DropdownButton<String>(
              value: selectedStart,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: starts
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final nextEnds = _endsForStart(_fares, v);
                setState(() {
                  _selectedStart = v;
                  _selectedEnd = nextEnds.isNotEmpty ? nextEnds.first : null;
                  _airportQuote = null;
                });
                _quoteAirport();
              },
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(labelText: l.rideDestinationLabel),
            child: DropdownButton<String>(
              value: selectedEnd,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: ends
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedEnd = v;
                  _airportQuote = null;
                });
                _quoteAirport();
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _promoController,
          decoration: const InputDecoration(labelText: 'WELCOME26'),
          onChanged: (_) => _quoteAirport(),
        ),
        const SizedBox(height: 16),
        if (q != null) ...[
          if (q['distance_km'] != null)
            Text(
              l.distanceKm((q['distance_km'] as num).toStringAsFixed(1)),
              textAlign: TextAlign.center,
            )
          else
            Text(
              l.distanceKm(_estimatedRouteKm(_routeKey).toStringAsFixed(1)),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 6),
          Text(
            '${q['final_fare']} DT',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (q['is_promo_applied'] == true)
            Text(
              'WELCOME26 -20%',
              style: TextStyle(
                  color: Colors.green.shade700, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          if (q['is_night'] == true)
            Text(l.nightFare50,
                style: const TextStyle(color: Colors.deepOrange)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _activeRequest == null ? () => _requestRide() : null,
            icon: const Icon(Icons.local_taxi),
            label: Text(l.requestRideButton),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callTaxi,
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
        if (_activeRequest != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(_activeRequest!.routeKey),
              subtitle: Text([
                l.rideStatusFmt(_activeRequest!.status),
                if ((_activeRequest!.driverName ?? '').isNotEmpty)
                  'Driver: ${_activeRequest!.driverName}',
                if ((_activeRequest!.driverPhone ?? '').isNotEmpty)
                  'Phone: ${_activeRequest!.driverPhone}',
              ].join('\n')),
              trailing: Text('${_activeRequest!.price.toStringAsFixed(3)} DT'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Searching nearby drivers...',
            style: const TextStyle(color: Colors.deepOrange),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _cancelRequest(),
            child: Text(l.cancelRidePassenger),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _openRideChat(),
            child: Text(l.openChatButton),
          ),
        ],
      ],
    );
  }

  Widget _chatTab(BuildContext context, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeRequest != null) ...[
          Text(
            l.rideStatusFmt(_activeRequest!.status),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _openRideChat(),
            child: Text(l.openChatButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _syncActiveRequestFromBackend(),
            child: const Text('Refresh ride status'),
          ),
          const Divider(height: 24),
        ],
        if (_chatHistory.isEmpty) Text(l.chatUnavailable),
        ..._chatHistory.map(
          (m) => ListTile(
            dense: true,
            title: Text(m['role'] ?? ''),
            subtitle: Text(m['text'] ?? ''),
          ),
        ),
        TextField(
          controller: _chatController,
          decoration: InputDecoration(labelText: l.messageFieldHint),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            final t = _chatController.text.trim();
            if (t.isEmpty) return;
            setState(() {
              _chatHistory.add({"role": "Passenger", "text": t});
              _chatController.clear();
            });
          },
          child: Text(l.sendChatMessage),
        ),
      ],
    );
  }

  Widget _settingsTab(BuildContext context, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _callTaxi,
          icon: const Icon(Icons.emergency),
          label: const Text('Emergency Call'),
        ),
        const SizedBox(height: 16),
        Text(l.rateYourLastRide,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return IconButton(
              icon: Icon(
                _rating >= star ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => _rating = star),
            );
          }),
        ),
        FilledButton(
          onPressed: _rating > 0 ? _submitRating : null,
          child: Text(l.submitRating),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }

  String? get _routeKey {
    final s = _selectedStart;
    final e = _selectedEnd;
    if (s == null || e == null) return null;
    final direct = '$s ➡️ $e';
    if (_fares.containsKey(direct)) return direct;
    for (final k in _fares.keys) {
      final parts = k.split('➡️');
      if (parts.length != 2) continue;
      if (parts[0].trim() == s && parts[1].trim() == e) return k;
    }
    return null;
  }

  List<String> _startsFromFares(Map<String, double> fares) {
    final starts = <String>{};
    for (final key in fares.keys) {
      final parts = key.split('➡️');
      if (parts.isNotEmpty) starts.add(parts.first.trim());
    }
    final list = starts.toList()..sort();
    return list;
  }

  List<String> _endsForStart(Map<String, double> fares, String start) {
    final ends = <String>{};
    for (final key in fares.keys) {
      final parts = key.split('➡️');
      if (parts.length != 2) continue;
      if (parts[0].trim() == start) {
        ends.add(parts[1].trim());
      }
    }
    final list = ends.toList()..sort();
    return list;
  }

  double _estimatedRouteKm(String? routeKey) {
    // Streamlit demo uses table values; use a stable estimate from fare if not exposed by API.
    if (routeKey == null) return 0;
    final fare = _fares[routeKey];
    if (fare == null) return 0;
    return (fare / 1.45).clamp(5, 180);
  }

  bool _isNightNow() {
    final h = DateTime.now().hour;
    return h >= 21 || h < 5;
  }

  Future<void> _requestRide() async {
    final key = _routeKey;
    final q = _airportQuote;
    if (key == null || q == null) return;
    final parts = key.split('➡️');
    final pickup = parts.isNotEmpty ? parts.first.trim() : '';
    final destination = parts.length > 1 ? parts[1].trim() : '';
    if (pickup.isEmpty || destination.isEmpty) return;
    _setStateIfMounted(() {
      _error = null;
      _loading = true;
    });
    try {
      final created = await _api.createGuestRide(
        pickup: pickup,
        destination: destination,
      );
      _setStateIfMounted(() {
        _guestToken = created.accessToken;
        _guestUserId = created.userId;
        _activeRequest = _PassengerRequest(
          rideId: created.ride.id,
          routeKey: key,
          price: (q['final_fare'] as num).toDouble(),
          status: 'pending',
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent. Waiting for drivers...')),
        );
        LocalNotificationService.instance.show(
          title: 'Request sent',
          body: 'Waiting for nearby drivers to accept your ride.',
        );
      }
      await _saveGuestSession();
    } catch (e) {
      _setStateIfMounted(() => _error = e.toString());
    } finally {
      _setStateIfMounted(() => _loading = false);
    }
  }

  Future<void> _cancelRequest() async {
    final req = _activeRequest;
    if (req == null) return;
    _setStateIfMounted(() => _loading = true);
    try {
      await _api.cancelGuestRide(rideId: req.rideId);
      _setStateIfMounted(() {
        _activeRequest = req.copyWith(status: 'cancelled');
        _guestToken = null;
        _guestUserId = null;
      });
      await _clearGuestSession();
    } catch (e) {
      _setStateIfMounted(() => _error = e.toString());
    } finally {
      _setStateIfMounted(() => _loading = false);
    }
  }

  Future<void> _openRideChat() async {
    final req = _activeRequest;
    final token = _guestToken;
    final uid = _guestUserId;
    if (req == null || token == null || uid == null || uid <= 0) return;
    try {
      await _syncActiveRequestFromBackend();
      final info = await _api.getRideConversation(
        token: token,
        rideId: req.rideId,
      );
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat opens after driver accepts')),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: token,
            myUserId: uid,
            rideId: req.rideId,
            conversationId: info.conversationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _syncActiveRequestFromBackend() async {
    final req = _activeRequest;
    final token = _guestToken;
    if (req == null || token == null) return;
    try {
      final rides = await _api.listRides(token);
      Ride? row;
      for (final r in rides) {
        if (r.id == req.rideId) {
          row = r;
          break;
        }
      }
      if (row == null) return;
      final previous = req.status;
      _setStateIfMounted(() {
        _activeRequest = req.copyWith(
          status: row!.status,
          driverName: row.driverName,
          driverPhone: row.driverPhone,
        );
      });
      if (!mounted) return;
      if (previous == 'pending' && row.status == 'accepted') {
        final driver = row.driverName ?? 'Driver';
        final phone =
            (row.driverPhone != null && row.driverPhone!.isNotEmpty) ? ' (${row.driverPhone})' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver accepted: $driver$phone')),
        );
        LocalNotificationService.instance.show(
          title: 'Driver accepted',
          body: '$driver$phone accepted your request.',
        );
      }
      if (row.status == 'accepted' &&
          (row.driverCurrentZone ?? '').trim().isNotEmpty &&
          row.driverCurrentZone!.trim() == row.pickup.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver is near your pickup point.')),
        );
        LocalNotificationService.instance.show(
          title: 'Driver near pickup',
          body: 'Your driver is near pickup in ${row.pickup}.',
        );
      }
      await _saveGuestSession();
    } catch (_) {
      // Keep UI usable even if sync fails.
    }
  }

  Future<void> _restoreGuestSession() async {
    _setStateIfMounted(() {
      _guestToken = _sessionGuestToken;
      _guestUserId = _sessionGuestUserId;
      _activeRequest = _sessionActiveRequest;
    });
    await _syncActiveRequestFromBackend();
  }

  Future<void> _saveGuestSession() async {
    _sessionGuestToken = _guestToken;
    _sessionGuestUserId = _guestUserId;
    _sessionActiveRequest = _activeRequest;
  }

  Future<void> _clearGuestSession() async {
    _sessionGuestToken = null;
    _sessionGuestUserId = null;
    _sessionActiveRequest = null;
  }

  Future<void> _callTaxi() async {
    final uri = Uri.parse('tel:$_taxiPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final route = _routeKey ?? '';
    final fare = _airportQuote?['final_fare'] ?? '';
    final text = Uri.encodeComponent('Taxi Pro: $route | $fare DT');
    final uri =
        Uri.parse('https://wa.me/${_taxiPhone.replaceAll('+', '')}?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _nearestZoneFor(double lat, double lng) {
    String? bestZone;
    double? bestDistance;
    for (final entry in _zoneCoords.entries) {
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        entry.value.lat,
        entry.value.lng,
      );
      if (bestDistance == null || d < bestDistance) {
        bestDistance = d;
        bestZone = entry.key;
      }
    }
    return bestZone;
  }
}

class _PassengerRequest {
  const _PassengerRequest({
    required this.rideId,
    required this.routeKey,
    required this.price,
    required this.status,
    this.driverName,
    this.driverPhone,
  });

  final int rideId;
  final String routeKey;
  final double price;
  final String status;
  final String? driverName;
  final String? driverPhone;

  _PassengerRequest copyWith({String? status, String? driverName, String? driverPhone}) {
    return _PassengerRequest(
      rideId: rideId,
      routeKey: routeKey,
      price: price,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
    );
  }

}

class _ZoneCoord {
  const _ZoneCoord(this.lat, this.lng);
  final double lat;
  final double lng;
}
