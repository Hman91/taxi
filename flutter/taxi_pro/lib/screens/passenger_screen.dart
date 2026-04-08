import 'package:flutter/material.dart';

import '../api/client.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _api = TaxiApiClient();
  Map<String, double> _fares = {};
  String? _routeKey;
  Map<String, dynamic>? _airportQuote;
  Map<String, dynamic>? _gpsQuote;
  final _distController = TextEditingController();
  bool _loading = true;
  String? _error;
  int _rating = 0;

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
    try {
      await _api.submitRating(_rating);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      setState(() => _rating = 0);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _distController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passenger'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Airport'),
              Tab(text: 'GPS'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _airportTab(),
                  _gpsTab(),
                ],
              ),
      ),
    );
  }

  Widget _airportTab() {
    if (_error != null && _fares.isEmpty) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    final q = _airportQuote;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_fares.isNotEmpty)
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Route'),
            child: DropdownButton<String>(
              value: _routeKey,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _fares.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                setState(() => _routeKey = v);
                _quoteAirport();
              },
            ),
          ),
        const SizedBox(height: 16),
        if (q != null) ...[
          Text(
            '${q['final_fare']} DT',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (q['is_night'] == true)
            const Text('+50% night fare', style: TextStyle(color: Colors.deepOrange)),
        ],
        const SizedBox(height: 24),
        const Text('Rate your last ride', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: const Text('Submit rating'),
        ),
      ],
    );
  }

  Widget _gpsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _distController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Distance km (optional — stub if empty)',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _quoteGps,
          child: const Text('Get estimate'),
        ),
        if (_gpsQuote != null) ...[
          const SizedBox(height: 16),
          Text('Distance: ${_gpsQuote!['distance_km']} km'),
          Text('Fare: ${_gpsQuote!['final_fare']} DT'),
        ],
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }
}
