import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/taxi_app_service.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _api = TaxiAppService();
  Map<String, double> _fares = {};
  String? _routeKey;
  String? _start;
  String? _end;
  Map<String, dynamic>? _airportQuote;
  Map<String, dynamic>? _gpsQuote;
  final _distController = TextEditingController();
  bool _loading = true;
  String? _error;
  int _rating = 0;
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFares();
  }

  Future<void> _loadFares() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fares = await _api.getAirportFares();
      setState(() {
        _fares = fares;
        _routeKey = fares.keys.isNotEmpty ? fares.keys.first : null;
        final starts = _starts();
        _start = starts.isNotEmpty ? starts.first : null;
        final ends = _start == null ? <String>[] : _endsForStart(_start!);
        _end = ends.isNotEmpty ? ends.first : null;
        _syncRouteSelection();
        _loading = false;
      });
      if (_routeKey != null) {
        await _quoteAirport();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _quoteAirport() async {
    final key = _routeKey;
    if (key == null) return;
    try {
      final promo = _promoController.text.trim();
      if (promo == 'WELCOME26') {
        final base = _fares[key] ?? 0;
        final q = await _api.quoteAirport(key);
        final discounted = (base * 0.8);
        final night = q['is_night'] == true;
        final finalFare = night ? discounted * 1.5 : discounted;
        setState(() => _airportQuote = {
          ...q,
          'base_fare': base,
          'promo_applied': true,
          'final_fare': finalFare.toStringAsFixed(3),
        });
        return;
      }
      final q = await _api.quoteAirport(key);
      setState(() => _airportQuote = q);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _quoteGps() async {
    double? d;
    final t = _distController.text.trim();
    if (t.isNotEmpty) {
      d = double.tryParse(t);
    }
    try {
      final q = await _api.quoteGps(distanceKm: d);
      setState(() {
        _gpsQuote = q;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
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
      setState(() => _rating = 0);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _distController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  List<String> _starts() {
    final out = <String>{};
    for (final k in _fares.keys) {
      final parts = k.split('➡️');
      if (parts.isNotEmpty) out.add(parts.first.trim());
    }
    return out.toList()..sort();
  }

  List<String> _endsForStart(String start) {
    final out = <String>{};
    for (final k in _fares.keys) {
      final parts = k.split('➡️');
      if (parts.length < 2) continue;
      if (parts.first.trim() == start.trim()) out.add(parts[1].trim());
    }
    return out.toList()..sort();
  }

  void _syncRouteSelection() {
    if (_start == null || _end == null) {
      _routeKey = null;
      return;
    }
    final candidate = '${_start!.trim()} ➡️ ${_end!.trim()}';
    _routeKey = _fares.containsKey(candidate) ? candidate : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.passengerTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabAirport),
              Tab(text: l.tabGps),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _airportTab(context, l),
                  _gpsTab(context, l),
                ],
              ),
      ),
    );
  }

  Widget _airportTab(BuildContext context, AppLocalizations l) {
    if (_error != null && _fares.isEmpty) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    final q = _airportQuote;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_fares.isNotEmpty) ...[
          InputDecorator(
            decoration: const InputDecoration(labelText: '📍 نقطة الانطلاق'),
            child: DropdownButton<String>(
              value: _start,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _starts()
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _start = v;
                  final ends = v == null ? <String>[] : _endsForStart(v);
                  _end = ends.isNotEmpty ? ends.first : null;
                  _syncRouteSelection();
                });
                _quoteAirport();
              },
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: '🏁 الوجهة'),
            child: DropdownButton<String>(
              value: _end,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: (_start == null ? <String>[] : _endsForStart(_start!))
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _end = v;
                  _syncRouteSelection();
                });
                _quoteAirport();
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promoController,
            decoration: const InputDecoration(labelText: 'كود التخفيض (WELCOME26)'),
            onChanged: (_) => _quoteAirport(),
          ),
        ],
        const SizedBox(height: 16),
        if (q != null) ...[
          Text(
            '${q['final_fare']} DT',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (q['promo_applied'] == true)
            const Text('🎉 تم تفعيل التخفيض بنسبة 20%', style: TextStyle(color: Colors.green)),
          if (q['is_night'] == true)
            Text(l.nightFare50, style: const TextStyle(color: Colors.deepOrange)),
        ],
        const SizedBox(height: 24),
        Text(l.rateYourLastRide, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      ],
    );
  }

  Widget _gpsTab(BuildContext context, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _distController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l.distanceKmOptional,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _quoteGps,
          child: Text(l.getEstimate),
        ),
        if (_gpsQuote != null) ...[
          const SizedBox(height: 16),
          Text(l.distanceKm(_gpsQuote!['distance_km'].toString())),
          Text(l.fareDt(_gpsQuote!['final_fare'].toString())),
        ],
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }
}
