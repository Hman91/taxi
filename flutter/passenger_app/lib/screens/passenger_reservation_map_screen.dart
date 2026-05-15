import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../maps/light_elegant_map_style.dart';
import '../maps/reservation_bubble_marker.dart';
import '../maps/tunisia_tourist_restaurants.dart';
import '../maps/tunisia_zone_coordinates.dart';
import '../services/google_directions_service.dart';
import '../services/google_geocoding_service.dart';
import '../services/google_places_service.dart';
import '../services/taxi_app_service.dart';
import '../utils/airport_place_heuristics.dart';
import '../widgets/night_fare_breakdown.dart';
import '../widgets/ride_address_summary_card.dart';

enum _MapMarkerCategory { airports, zones, restaurants }

/// Prefix for destination picker results that represent a curated restaurant pin.
const String _kRestaurantPickPrefix = '__rp:';

/// Catalog or Places destination pick (zone key is always set for pricing).
class _DestinationPick {
  const _DestinationPick({
    required this.zoneKey,
    this.placeTitle,
    this.formattedAddress,
    this.exact,
  });

  final String zoneKey;
  final String? placeTitle;
  final String? formattedAddress;
  final LatLng? exact;
}

/// Returned when the user confirms the reservation from the map flow.
class PassengerReservationMapResult {
  const PassengerReservationMapResult({
    required this.routeKey,
    required this.promoCode,
    required this.scheduleLater,
    required this.finalFare,
    this.scheduledPickupAt,
    this.pickupAddress,
    this.pickupDisplayName,
    this.destinationAddress,
    this.destinationDisplayName,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  final String routeKey;
  final String promoCode;
  final bool scheduleLater;
  final double finalFare;
  final DateTime? scheduledPickupAt;
  final String? pickupAddress;
  final String? pickupDisplayName;
  final String? destinationAddress;
  final String? destinationDisplayName;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
}

class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textSoft = Color(0xFF5C5C5C);
  static const textMid = Color(0xFF3F3F3F);
  static const success = Color(0xFF1A7A4A);
}

InputDecoration _fd(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textSoft, fontSize: 12, fontWeight: FontWeight.w700),
      prefixIcon: icon != null ? Icon(icon, color: _C.textMid, size: 18) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _C.yellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );

/// Full-screen reservation: **map on top**, premium **draggable sheet** with live route metrics.
class PassengerReservationMapScreen extends StatefulWidget {
  const PassengerReservationMapScreen({
    super.key,
    required this.api,
    required this.l,
    required this.allRouteKeys,
    required this.fares,
    required this.initialPickupZone,
    this.passengerGps,
    required this.tx,
    required this.formatScheduledDateTime,
  });

  final TaxiAppService api;
  final AppLocalizations l;
  final List<String> allRouteKeys;
  final Map<String, double> fares;
  final String initialPickupZone;
  final LatLng? passengerGps;
  final String Function(String key, [Object? value]) tx;
  final String Function(DateTime dt) formatScheduledDateTime;

  @override
  State<PassengerReservationMapScreen> createState() =>
      _PassengerReservationMapScreenState();
}

class _PassengerReservationMapScreenState extends State<PassengerReservationMapScreen>
    with SingleTickerProviderStateMixin {
  final _directions = GoogleDirectionsService();
  final _geocode = GoogleGeocodingService();
  final _places = GooglePlacesService();
  final _promoCtrl = TextEditingController();
  final _destSearchCtrl = TextEditingController();
  GoogleMapController? _map;

  late String _selectedFrom;
  String? _selectedTo;
  String? _selectedRouteKey;
  Map<String, dynamic>? _quote;
  String _promoCode = '';

  LatLng? _userGps;
  StreamSubscription<Position>? _posSub;
  bool _followUser = true;
  bool _locationDenied = false;
  Timer? _geoDeb;
  String? _pickupGeoLine;
  _MapMarkerCategory _markerCategory = _MapMarkerCategory.zones;
  String? _focusedRestaurantId;
  Map<String, BitmapDescriptor> _destIcons = {};
  Map<String, BitmapDescriptor> _restaurantIcons = {};

  /// Places primary label or other passenger-facing destination title (optional).
  String? _destinationPlaceTitle;
  String? _destinationAddressLine;
  LatLng? _destinationExact;

  bool _scheduleLater = false;
  DateTime? _scheduledPickupAt;

  DirectionsRouteResult? _route;
  bool _routeLoading = false;
  String? _routeError;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _selectedFrom = widget.initialPickupZone.trim();
    _userGps = widget.passengerGps;
    if (_userGps != null) {
      unawaited(_syncOriginFromGps(_userGps!));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_recalcQuote());
      unawaited(_startGpsTracking());
    });
  }

  @override
  void dispose() {
    _geoDeb?.cancel();
    _posSub?.cancel();
    _pulse.dispose();
    _promoCtrl.dispose();
    _destSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startGpsTracking() async {
    if (!mounted) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationDenied = true;
          _userGps ??= widget.passengerGps ?? TunisiaZoneCoordinates.lookupOrOverview(_selectedFrom);
        });
        if (_userGps != null) await _syncOriginFromGps(_userGps!);
        await _refreshDestMarkerBitmaps();
        _schedulePickupAddressLookup();
      }
      return;
    }
    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final ll = LatLng(first.latitude, first.longitude);
        setState(() {
          _locationDenied = false;
          _userGps = ll;
        });
        await _syncOriginFromGps(ll);
        await _loadRoute(fitCamera: _selectedTo != null);
        _schedulePickupAddressLookup();
        if (_followUser && _map != null) {
          unawaited(_map!.moveCamera(CameraUpdate.newLatLngZoom(ll, 12)));
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userGps ??= widget.passengerGps ?? TunisiaZoneCoordinates.lookupOrOverview(_selectedFrom);
      });
      if (_userGps != null) await _syncOriginFromGps(_userGps!);
    }

    if (!mounted) return;
    await _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _userGps = ll);
      unawaited(_syncOriginFromGps(ll));
      _schedulePickupAddressLookup();
      if (_followUser && _map != null) {
        unawaited(_map!.moveCamera(CameraUpdate.newLatLng(ll)));
      }
      unawaited(_loadRoute(fitCamera: false));
    });
  }

  Future<void> _syncOriginFromGps(LatLng p) async {
    if (!mounted) return;
    final nz = _nearestCatalogOrigin(p);
    if (nz == null) return;
    if (nz != _selectedFrom) {
      final dests = _destinationsFor(nz);
      final lostDest = _selectedTo != null && !dests.contains(_selectedTo!);
      setState(() {
        _selectedFrom = nz;
        if (lostDest) {
          _selectedTo = null;
          _selectedRouteKey = null;
        } else {
          _selectedRouteKey = _findRouteKey(_selectedFrom, _selectedTo);
        }
      });
      await _recalcQuote();
      await _refreshDestMarkerBitmaps();
    } else {
      _selectedRouteKey = _findRouteKey(_selectedFrom, _selectedTo);
    }
  }

  Set<String> _catalogOriginZones() {
    final s = <String>{};
    for (final k in widget.allRouteKeys) {
      final parts = k.split(airportRouteKeySeparator);
      if (parts.length >= 2) s.add(parts.first.trim());
    }
    return s;
  }

  String? _nearestCatalogOrigin(LatLng p) {
    final allowed = _catalogOriginZones();
    String? best;
    var bestM = double.infinity;
    for (final z in TunisiaZoneCoordinates.registeredZoneKeys) {
      if (!allowed.contains(z)) continue;
      final c = TunisiaZoneCoordinates.lookup(z);
      if (c == null) continue;
      final m = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        c.latitude,
        c.longitude,
      );
      if (m < bestM) {
        bestM = m;
        best = z;
      }
    }
    return best;
  }

  /// Maps a GPS point from Places (or elsewhere) to the nearest catalog destination
  /// for the current fare origin, within [maxMeters].
  String? _nearestCatalogDestinationForPlace(LatLng p, {double maxMeters = 120000}) {
    final candidates = _destinationsFor(_selectedFrom);
    if (candidates.isEmpty) return null;
    String? best;
    var bestM = double.infinity;
    for (final d in candidates) {
      final c = TunisiaZoneCoordinates.lookup(d);
      if (c == null) continue;
      final m = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        c.latitude,
        c.longitude,
      );
      if (m < bestM) {
        bestM = m;
        best = d;
      }
    }
    if (best == null || bestM > maxMeters) return null;
    return best;
  }

  List<String> _visibleCatalogDestinationKeys() {
    final all = _destinationsFor(_selectedFrom);
    final sel = _selectedTo;
    if (_markerCategory == _MapMarkerCategory.restaurants) {
      return const [];
    }
    bool pass(String d) {
      final ap = AirportPlaceHeuristics.zoneKeyLooksLikeAirport(d);
      if (_markerCategory == _MapMarkerCategory.airports) return ap;
      return !ap;
    }
    final out = <String>[];
    for (final d in all) {
      if (pass(d)) out.add(d);
    }
    if (sel != null && all.contains(sel) && !out.contains(sel)) out.add(sel);
    out.sort((a, b) => localizedPlaceName(widget.l, a).compareTo(localizedPlaceName(widget.l, b)));
    return out;
  }

  void _schedulePickupAddressLookup() {
    _geoDeb?.cancel();
    if (!_geocode.isConfigured) return;
    _geoDeb = Timer(const Duration(milliseconds: 420), () {
      unawaited(_fetchPickupAddressLine());
    });
  }

  Future<void> _fetchPickupAddressLine() async {
    if (!mounted) return;
    final g = _userGps;
    if (g == null) return;
    final line = await _geocode.reverseFormattedAddress(g);
    if (!mounted) return;
    setState(() => _pickupGeoLine = line);
  }

  Future<void> _refreshDestMarkerBitmaps() async {
    if ((_selectedTo ?? '').trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _destIcons = {};
        _restaurantIcons = {};
      });
      return;
    }
    final nextDest = <String, BitmapDescriptor>{};
    for (final d in _visibleCatalogDestinationKeys()) {
      final ap = AirportPlaceHeuristics.zoneKeyLooksLikeAirport(d);
      final sel = d == _selectedTo;
      final badge = localizedPlaceName(widget.l, d);
      final icon = await ReservationBubbleMarker.build(
        cacheKey: 'c4|$d|${ap ? 'a' : 'z'}|$sel',
        markerKind: ap ? ReservationMarkerKind.airport : ReservationMarkerKind.zone,
        badge: badge,
        selected: sel,
      );
      nextDest[d] = icon;
    }

    final nextRp = <String, BitmapDescriptor>{};
    if (_markerCategory == _MapMarkerCategory.restaurants) {
      for (final r in TunisiaTouristRestaurants.all) {
        final sel = r.id == _focusedRestaurantId;
        nextRp[r.id] = await ReservationBubbleMarker.build(
          cacheKey: 'rp4|${r.id}|$sel',
          markerKind: ReservationMarkerKind.restaurant,
          badge: r.name,
          selected: sel,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _destIcons = nextDest;
      _restaurantIcons = nextRp;
    });
  }

  Future<void> _loadDestinationAddressFromZone(String zoneKey) async {
    if (!mounted || !_geocode.isConfigured) return;
    final ll = TunisiaZoneCoordinates.lookup(zoneKey.trim());
    if (ll == null) return;
    final line = await _geocode.reverseFormattedAddress(ll);
    if (!mounted) return;
    final t = (line ?? '').trim();
    setState(() => _destinationAddressLine = t.isEmpty ? null : t);
  }

  Future<void> _reverseGeocodeDestinationPin() async {
    final ll = _destinationExact;
    if (!mounted || ll == null || !_geocode.isConfigured) return;
    final line = await _geocode.reverseFormattedAddress(ll);
    if (!mounted) return;
    final t = (line ?? '').trim();
    setState(() => _destinationAddressLine = t.isEmpty ? null : t);
  }

  bool get _hasRouteDestination => (_selectedTo ?? '').trim().isNotEmpty;

  LatLng? _effectiveDestinationLatLng() {
    final to = _selectedTo;
    if ((to ?? '').trim().isEmpty) return null;
    final x = _destinationExact;
    if (x != null) return x;
    return TunisiaZoneCoordinates.lookup(to!.trim());
  }

  List<String> _destinationsFor(String origin) {
    final o = origin.trim();
    if (o.isEmpty) return const [];
    return widget.allRouteKeys
        .where((k) {
          final parts = k.split(airportRouteKeySeparator);
          if (parts.length < 2) return false;
          return parts.first.trim() == o;
        })
        .map((k) => k.split(airportRouteKeySeparator)[1].trim())
        .toSet()
        .toList()
      ..sort((a, b) => localizedPlaceName(widget.l, a)
          .compareTo(localizedPlaceName(widget.l, b)));
  }

  String? _findRouteKey(String? from, String? to) {
    if ((from ?? '').isEmpty || (to ?? '').isEmpty) return null;
    for (final key in widget.allRouteKeys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.length < 2) continue;
      if (parts.first.trim() == from!.trim() && parts[1].trim() == to!.trim()) {
        return key;
      }
    }
    return null;
  }

  Future<void> _selectDestinationFromMap(String zoneKey) async {
    final d = zoneKey.trim();
    if (d.isEmpty || !mounted) return;
    setState(() {
      _selectedTo = d;
      _selectedRouteKey = _findRouteKey(_selectedFrom, _selectedTo);
      _focusedRestaurantId = null;
      _destinationPlaceTitle = null;
      _destinationExact = null;
      _destinationAddressLine = null;
    });
    unawaited(_loadDestinationAddressFromZone(d));
    await _recalcQuote();
    await _loadRoute(fitCamera: true);
    await _refreshDestMarkerBitmaps();
  }

  Future<void> _recalcQuote() async {
    final key = _selectedRouteKey;
    if (key == null) {
      setState(() => _quote = null);
      return;
    }
    try {
      final DateTime pricingTime = _scheduleLater &&
              _scheduledPickupAt != null
          ? _scheduledPickupAt!.toUtc()
          : DateTime.now().toUtc();
      final q = await widget.api.quoteAirport(key, pricingTime: pricingTime);
      if (!mounted) return;
      final merged = Map<String, dynamic>.from(q);
      var finalFare =
          (merged['final_fare'] as num?)?.toDouble() ?? (widget.fares[key] ?? 0);
      if (_promoCtrl.text.trim().toUpperCase() == 'WELCOME26') {
        finalFare *= 0.8;
      }
      merged['final_fare'] = double.parse(finalFare.toStringAsFixed(3));
      merged['route_key'] = key;
      setState(() => _quote = merged);
    } catch (_) {
      if (mounted) setState(() => _quote = null);
    }
  }

  Future<void> _loadRoute({bool fitCamera = false}) async {
    final from = _selectedFrom.trim();
    final to = (_selectedTo ?? '').trim();
    if (from.isEmpty || to.isEmpty) {
      setState(() {
        _route = null;
        _routeError = null;
      });
      return;
    }
    final a = _userGps;
    if (a == null) {
      setState(() {
        _route = null;
        _routeError = null;
      });
      return;
    }
    final b = _destinationExact ?? TunisiaZoneCoordinates.lookup(to);
    if (b == null) {
      setState(() {
        _route = null;
        _routeError = 'Zone coordinates missing';
      });
      return;
    }
    if (!_directions.isConfigured) {
      setState(() {
        _route = null;
        _routeError = null;
      });
      return;
    }
    setState(() {
      _routeLoading = true;
      _routeError = null;
    });
    try {
      final r = await _directions.fetchRoute(a, b);
      if (!mounted) return;
      setState(() {
        _route = r;
        _routeLoading = false;
        if (r == null) _routeError = 'Directions unavailable';
      });
      if (fitCamera) await _fitCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _routeError = e.toString();
      });
    }
  }

  Future<void> _fitCamera() async {
    final c = _map;
    if (c == null) return;
    final to = (_selectedTo ?? '').trim();
    final u = _userGps;
    if (u == null) return;
    final pts = <LatLng>[u];
    final r = _route;
    if (r != null && r.points.length >= 2) {
      pts.addAll(r.points);
    } else if (to.isNotEmpty) {
      pts.add(TunisiaZoneCoordinates.lookupOrOverview(to));
    }
    if (pts.length < 2) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          pts.isEmpty ? TunisiaZoneCoordinates.tunisOverview : pts.first,
          11,
        ),
      );
      return;
    }
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts.skip(1)) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100,
        ),
      );
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 10.5));
    }
  }

  Set<Marker> _markers() {
    final out = <Marker>{};
    final u = _userGps;
    final dest = _effectiveDestinationLatLng();
    if (_hasRouteDestination && dest != null) {
      if (u != null) {
        out.add(
          Marker(
            markerId: const MarkerId('focus_pickup'),
            position: u,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            anchor: const Offset(0.5, 1.0),
            zIndexInt: 3,
            infoWindow: InfoWindow.noText,
          ),
        );
      }
      out.add(
        Marker(
          markerId: const MarkerId('focus_dest'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 1.0),
          zIndexInt: 4,
          infoWindow: InfoWindow.noText,
        ),
      );
      return out;
    }
    if (_markerCategory == _MapMarkerCategory.restaurants) {
      for (final r in TunisiaTouristRestaurants.all) {
        final icon = _restaurantIcons[r.id] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        final sel = r.id == _focusedRestaurantId;
        out.add(
          Marker(
            markerId: MarkerId('rp_${r.id}'),
            position: r.position,
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            zIndexInt: sel ? 5 : 2,
            infoWindow: InfoWindow.noText,
            consumeTapEvents: true,
            onTap: () => unawaited(_onRestaurantMarkerTap(r)),
          ),
        );
      }
      return out;
    }
    for (final d in _visibleCatalogDestinationKeys()) {
      final pos = TunisiaZoneCoordinates.lookup(d);
      if (pos == null) continue;
      final ap = AirportPlaceHeuristics.zoneKeyLooksLikeAirport(d);
      final icon = _destIcons[d] ??
          BitmapDescriptor.defaultMarkerWithHue(ap ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueOrange);
      out.add(
        Marker(
          markerId: MarkerId('d_${d.hashCode}'),
          position: pos,
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          zIndexInt: d == _selectedTo ? 4 : 2,
          infoWindow: InfoWindow.noText,
          consumeTapEvents: true,
          onTap: () => unawaited(_selectDestinationFromMap(d)),
        ),
      );
    }
    return out;
  }

  Set<Polyline> _polylines() {
    final r = _route;
    if (r == null || r.points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('dir'),
        color: const Color(0xE6FFC200),
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        points: r.points,
      ),
    };
  }

  String _durationLabel(int seconds) {
    if (seconds < 3600) return '${(seconds / 60).ceil()} min';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '$h h ${m.toString().padLeft(2, '0')} min';
  }

  /// Instant filter for saved / catalog destinations (airports, zones, cities).
  List<String> _rankedDestinationCatalogMatches(String rawQuery, List<String> base) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return List<String>.from(base.take(28));
    }
    final scored = <({String d, int score})>[];
    for (final d in base) {
      final label = localizedPlaceName(widget.l, d).trim();
      final l = label.toLowerCase();
      final k = d.toLowerCase();
      if (!l.contains(q) && !k.contains(q)) continue;
      var score = 1000;
      if (l.startsWith(q) || k.startsWith(q)) score -= 400;
      final li = l.indexOf(q);
      if (li >= 0) {
        score += li;
      } else {
        score += 40 + k.indexOf(q);
      }
      if (l == q || k == q) score -= 200;
      scored.add((d: d, score: score));
    }
    scored.sort((a, b) => a.score.compareTo(b.score));
    return scored.map((e) => e.d).take(60).toList();
  }

  List<TunisiaTouristRestaurant> _rankedRestaurantMatches(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return List<TunisiaTouristRestaurant>.from(TunisiaTouristRestaurants.all);
    }
    final scored = <({TunisiaTouristRestaurant r, int score})>[];
    for (final r in TunisiaTouristRestaurants.all) {
      final name = r.name.toLowerCase();
      final id = r.id.toLowerCase();
      if (!name.contains(q) && !id.contains(q)) continue;
      var score = 1000;
      if (name.startsWith(q) || id.startsWith(q)) score -= 400;
      final ni = name.indexOf(q);
      if (ni >= 0) {
        score += ni;
      } else {
        score += 40 + id.indexOf(q);
      }
      if (name == q || id == q) score -= 200;
      scored.add((r: r, score: score));
    }
    scored.sort((a, b) => a.score.compareTo(b.score));
    return scored.map((e) => e.r).take(60).toList();
  }

  Future<void> _onRestaurantMarkerTap(TunisiaTouristRestaurant r) async {
    if (!mounted) return;
    setState(() => _focusedRestaurantId = r.id);
    unawaited(_refreshDestMarkerBitmaps());
    final c = _map;
    if (c != null && mounted) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(r.position, 13.8));
    }
    if (!mounted) return;
    await _applyRestaurantSelection(r);
  }

  /// Picks the nearest catalog destination for pricing, sets the restaurant pin
  /// for route distance/ETA, and refreshes quote — no extra confirmation sheet.
  Future<void> _applyRestaurantSelection(TunisiaTouristRestaurant r) async {
    if (!mounted) return;
    final nearest = _nearestCatalogDestinationForPlace(r.position);
    if (nearest == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.tx('noRoutesFromYourArea'))),
      );
      return;
    }
    setState(() {
      _markerCategory = _MapMarkerCategory.zones;
      _focusedRestaurantId = null;
      _selectedTo = nearest;
      _selectedRouteKey = _findRouteKey(_selectedFrom, _selectedTo);
      _destinationPlaceTitle = r.name;
      _destinationExact = r.position;
      _destinationAddressLine = null;
    });
    unawaited(_reverseGeocodeDestinationPin());
    await _recalcQuote();
    await _loadRoute(fitCamera: true);
    await _refreshDestMarkerBitmaps();
  }

  Widget _highlightQueryInDestination(String displayName, String query) {
    final q = query.trim();
    const baseStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 14,
      color: _C.charcoal,
      height: 1.25,
    );
    const hiStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 14,
      height: 1.25,
      color: _C.yellowDeep,
      backgroundColor: _C.yellowSoft,
    );
    if (q.isEmpty) {
      return Text(displayName, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final lower = displayName.toLowerCase();
    final needle = q.toLowerCase();
    final i = lower.indexOf(needle);
    if (i < 0 || needle.isEmpty) {
      return Text(displayName, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final end = math.min(i + needle.length, displayName.length);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (i > 0) TextSpan(text: displayName.substring(0, i)),
          TextSpan(style: hiStyle, text: displayName.substring(i, end)),
          if (end < displayName.length) TextSpan(text: displayName.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _pickDestination() async {
    final base = _destinationsFor(_selectedFrom);
    if (base.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.tx('noRoutesFromYourArea'))),
        );
      }
      return;
    }
    _destSearchCtrl.clear();
    var query = '';
    var localMatches = _rankedDestinationCatalogMatches('', base);
    var restaurantMatches = _rankedRestaurantMatches('');
    var sug = <PlaceAutocompleteItem>[];
    var loading = false;
    String? err;
    Timer? debounce;

    Future<void> runPlacesSearch(StateSetter ss, BuildContext sheetCtx, String raw) async {
      final v = raw.trim();
      if (v.isEmpty) {
        ss(() {
          sug = [];
          loading = false;
          err = null;
        });
        return;
      }
      if (!_places.isConfigured) {
        ss(() {
          sug = [];
          loading = false;
          err = null;
        });
        return;
      }
      ss(() {
        loading = true;
        err = null;
      });
      try {
        final bias = _userGps ?? TunisiaZoneCoordinates.lookupOrOverview(_selectedFrom);
        final list = await _places.autocomplete(v, biasCenter: bias);
        if (!sheetCtx.mounted) return;
        ss(() {
          sug = list;
          loading = false;
        });
      } catch (e) {
        if (!sheetCtx.mounted) return;
        ss(() {
          loading = false;
          err = e.toString();
        });
      }
    }

    final picked = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(sheetCtx).top + 8),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.42,
            maxChildSize: 0.94,
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (ctx, ss) {
                    final hasWeb = sug.isNotEmpty;
                    final hasLocal = localMatches.isNotEmpty;
                    final hasRestaurants = restaurantMatches.isNotEmpty;
                    final showEmpty = query.trim().isNotEmpty &&
                        !hasLocal &&
                        !hasWeb &&
                        !hasRestaurants &&
                        !loading;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        10,
                        18,
                        14 + MediaQuery.viewInsetsOf(sheetCtx).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: _C.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Text(
                            widget.tx('selectDestination'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: _C.charcoal,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.tx('destSearchTypeHint'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _C.textSoft.withValues(alpha: 0.92),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _destSearchCtrl,
                            autofocus: true,
                            decoration: _fd(
                              widget.tx('destSearchAutocompleteHint'),
                              icon: Icons.search_rounded,
                            ),
                            onChanged: (v) {
                              ss(() {
                                query = v;
                                localMatches = _rankedDestinationCatalogMatches(v, base);
                                restaurantMatches = _rankedRestaurantMatches(v);
                              });
                              debounce?.cancel();
                              final t = v.trim();
                              if (t.isEmpty) {
                                ss(() {
                                  sug = [];
                                  loading = false;
                                  err = null;
                                });
                              } else {
                                debounce = Timer(
                                  const Duration(milliseconds: 200),
                                  () => runPlacesSearch(ss, sheetCtx, v),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: loading ? 3 : 0,
                            child: loading
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      color: _C.yellowDeep,
                                      backgroundColor: _C.yellowSoft,
                                    ),
                                  )
                                : null,
                          ),
                          if (err != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                err!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: DecoratedBox(
                                key: ValueKey<String>('$query|${sug.length}|$loading|${restaurantMatches.length}'),
                                decoration: BoxDecoration(
                                  color: _C.surfaceAlt.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _C.border.withValues(alpha: 0.75)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _C.yellow.withValues(alpha: 0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ListView(
                                    controller: scrollCtrl,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
                                    children: [
                                      if (showEmpty)
                                        SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Text(
                                                widget.tx('destSearchNoMatches'),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: _C.textSoft,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      else ...[
                                        if (hasLocal) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                                            child: Text(
                                              widget.tx('catalogLiveMatchesHeader'),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.15,
                                                color: _C.textSoft,
                                              ),
                                            ),
                                          ),
                                          ...localMatches.map((d) {
                                            final ap =
                                                AirportPlaceHeuristics.zoneKeyLooksLikeAirport(d);
                                            final label = localizedPlaceName(widget.l, d);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () => Navigator.pop(
                                                    sheetCtx,
                                                    _DestinationPick(zoneKey: d),
                                                  ),
                                                  child: Ink(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.white.withValues(alpha: 0.98),
                                                          _C.yellowSoft.withValues(alpha: 0.25),
                                                        ],
                                                      ),
                                                      border: Border.all(
                                                        color: ap
                                                            ? const Color(0xFF90CAF9)
                                                                .withValues(alpha: 0.5)
                                                            : _C.border.withValues(alpha: 0.65),
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          ap
                                                              ? Icons.flight_takeoff_rounded
                                                              : Icons.place_outlined,
                                                          color: ap
                                                              ? const Color(0xFF0D47A1)
                                                              : _C.textMid,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: _highlightQueryInDestination(
                                                            label,
                                                            query,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.north_west_rounded,
                                                          size: 18,
                                                          color: _C.yellowDeep.withValues(alpha: 0.85),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                        if (hasRestaurants) ...[
                                          if (hasLocal) const SizedBox(height: 14),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                                            child: Text(
                                              widget.tx('restaurantSuggestionsHeader'),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.15,
                                                color: _C.textSoft,
                                              ),
                                            ),
                                          ),
                                          ...restaurantMatches.map((r) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () =>
                                                      Navigator.pop(sheetCtx, '$_kRestaurantPickPrefix${r.id}'),
                                                  child: Ink(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.white.withValues(alpha: 0.98),
                                                          const Color(0xFF00695C).withValues(alpha: 0.06),
                                                        ],
                                                      ),
                                                      border: Border.all(
                                                        color: const Color(0xFF00695C).withValues(alpha: 0.28),
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.restaurant_rounded,
                                                          color: Color(0xFF00695C),
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: _highlightQueryInDestination(
                                                            r.name,
                                                            query,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.north_west_rounded,
                                                          size: 18,
                                                          color: _C.yellowDeep.withValues(alpha: 0.85),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                        if (hasWeb) ...[
                                          if (hasLocal || hasRestaurants) const SizedBox(height: 14),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                                            child: Text(
                                              widget.tx('placesSuggestionsHeader'),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.15,
                                                color: _C.textSoft,
                                              ),
                                            ),
                                          ),
                                          ...sug.map(
                                            (item) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () async {
                                                    FocusScope.of(sheetCtx).unfocus();
                                                    final det =
                                                        await _places.placeDetails(item.placeResourceName);
                                                    if (!sheetCtx.mounted) return;
                                                    if (det == null) return;
                                                    final zone =
                                                        _nearestCatalogDestinationForPlace(det.position);
                                                    if (zone == null) {
                                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            widget.tx('destinationPlaceOutOfCoverage'),
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    Navigator.pop(
                                                      sheetCtx,
                                                      _DestinationPick(
                                                        zoneKey: zone,
                                                        placeTitle: item.label,
                                                        formattedAddress: det.formattedAddress,
                                                        exact: det.position,
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(
                                                          item.isAirport
                                                              ? Icons.flight_takeoff_rounded
                                                              : Icons.public_rounded,
                                                          color: item.isAirport
                                                              ? const Color(0xFF0D47A1)
                                                              : _C.textMid,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: _highlightQueryInDestination(
                                                            item.label,
                                                            query,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
    debounce?.cancel();
    if (picked == null || !mounted) return;
    if (picked is String && picked.startsWith(_kRestaurantPickPrefix)) {
      final rid = picked.substring(_kRestaurantPickPrefix.length);
      final r = TunisiaTouristRestaurants.byId(rid);
      if (r == null) return;
      setState(() {
        _focusedRestaurantId = rid;
        _markerCategory = _MapMarkerCategory.restaurants;
      });
      await _refreshDestMarkerBitmaps();
      final c = _map;
      if (c != null && mounted) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(r.position, 13.8));
      }
      if (!mounted) return;
      await _applyRestaurantSelection(r);
      return;
    }
    if (picked is! _DestinationPick) return;
    final d = picked;
    setState(() {
      _selectedTo = d.zoneKey;
      _selectedRouteKey = _findRouteKey(_selectedFrom, _selectedTo);
      _focusedRestaurantId = null;
      final title = (d.placeTitle ?? '').trim();
      _destinationPlaceTitle = title.isEmpty ? null : title;
      _destinationExact = d.exact;
      final fa = (d.formattedAddress ?? '').trim();
      _destinationAddressLine = fa.isEmpty ? null : fa;
    });
    if ((d.formattedAddress ?? '').trim().isEmpty) {
      if (d.exact != null) {
        unawaited(_reverseGeocodeDestinationPin());
      } else {
        unawaited(_loadDestinationAddressFromZone(d.zoneKey));
      }
    }
    await _recalcQuote();
    await _loadRoute(fitCamera: true);
    await _refreshDestMarkerBitmaps();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledPickupAt ?? now.add(const Duration(hours: 12));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledPickupAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isGoogleMapsPlatformSupported) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.l.passengerBookingSectionTitle)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ajoutez GOOGLE_MAPS_API_KEY au lancement Flutter (--dart-define) pour afficher la carte.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.surfaceAlt,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.42,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userGps ?? TunisiaZoneCoordinates.tunisOverview,
                      zoom: 11,
                      tilt: 16,
                    ),
                    markers: _markers(),
                    polylines: _polylines(),
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: !_hasRouteDestination,
                    buildingsEnabled: true,
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 8,
                      bottom: _hasRouteDestination
                          ? (MediaQuery.sizeOf(context).height * 0.28).clamp(120.0, 220.0)
                          : 24,
                    ),
                    onCameraMoveStarted: () {
                      if (mounted) setState(() => _followUser = false);
                    },
                    onMapCreated: (c) async {
                      _map = c;
                      await c.setMapStyle(kPassengerLightMapStyleJson);
                      final u = _userGps;
                      if (u != null) {
                        await c.moveCamera(CameraUpdate.newLatLngZoom(u, 11.2));
                      }
                      await _refreshDestMarkerBitmaps();
                      unawaited(_fetchPickupAddressLine());
                    },
                  ),
                  if (_userGps != null)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 52,
                      right: 10,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: const CircleBorder(),
                        elevation: 5,
                        shadowColor: _C.yellow.withValues(alpha: 0.25),
                        child: IconButton(
                          tooltip: widget.tx('mapRecenterFollow'),
                          onPressed: () {
                            setState(() => _followUser = true);
                            final u = _userGps;
                            if (u != null && _map != null) {
                              unawaited(_map!.animateCamera(CameraUpdate.newLatLngZoom(u, 12)));
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, color: _C.yellowDeep),
                        ),
                      ),
                    ),
                  if (!_hasRouteDestination)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 14,
                      child: _MapMarkerFilterBar(
                      markerCategory: _markerCategory,
                      onChanged: (f) {
                        setState(() {
                          _markerCategory = f;
                          if (f != _MapMarkerCategory.restaurants) {
                            _focusedRestaurantId = null;
                          }
                        });
                        unawaited(_refreshDestMarkerBitmaps());
                      },
                      tx: widget.tx,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: _C.charcoal),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.route_rounded, color: _C.yellowDeep, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            widget.tx('reserveRideTitle'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.48,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, -12),
                    ),
                  ],
                  border: Border.all(color: _C.border.withValues(alpha: 0.6)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _C.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Text(
                      widget.tx('reserveRideBody'),
                      style: const TextStyle(color: _C.textSoft, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    if (!_hasRouteDestination) ...[
                      Text(
                        widget.tx('mapPickupGpsHint'),
                        style: TextStyle(
                          color: _C.textSoft.withValues(alpha: 0.92),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.tx('mapMarkersPickFilterHint'),
                        style: TextStyle(
                          color: _C.textSoft.withValues(alpha: 0.88),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.tx('mapTapDestinationHint'),
                        style: TextStyle(
                          color: _C.textSoft.withValues(alpha: 0.88),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ] else ...[
                      Text(
                        widget.tx('mapBookingFocusedHint'),
                        style: TextStyle(
                          color: _C.textSoft.withValues(alpha: 0.92),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _modeRow(),
                    const SizedBox(height: 14),
                    if (_scheduleLater) ...[
                      _glassTile(
                        onTap: _pickSchedule,
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: _C.yellowDeep),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _scheduledPickupAt == null
                                    ? widget.tx('choosePickupDateTime')
                                    : widget.formatScheduledDateTime(_scheduledPickupAt!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _C.charcoal,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: _C.yellowDeep),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _glassTile(
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: Color(0xFFAB47BC), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocationEndpointBlock(
                                  sectionLabel: widget.l.ridePickupLabel,
                                  title: localizedPlaceName(widget.l, _selectedFrom),
                                  address: (_pickupGeoLine ?? '').trim().isEmpty ? null : _pickupGeoLine!.trim(),
                                ),
                                if (_locationDenied) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.tx('locationPermissionReservationNote'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: Colors.orange,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _pickDestination,
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                _C.yellowSoft.withValues(alpha: 0.95),
                                Colors.white,
                              ],
                            ),
                            border: Border.all(color: _C.yellow.withValues(alpha: 0.55)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.place_rounded, color: Color(0xFFE65100), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: LocationEndpointBlock(
                                  sectionLabel: widget.l.rideDestinationLabel,
                                  title: _selectedTo == null
                                      ? widget.tx('selectDestination')
                                      : (_destinationPlaceTitle ??
                                          localizedPlaceName(widget.l, _selectedTo!)),
                                  address: _selectedTo == null
                                      ? null
                                      : ((_destinationAddressLine ?? '').trim().isEmpty
                                          ? null
                                          : _destinationAddressLine!.trim()),
                                  titleStyle: _selectedTo == null
                                      ? const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          height: 1.25,
                                          color: _C.textSoft,
                                        )
                                      : null,
                                ),
                              ),
                              const Icon(Icons.search_rounded, color: _C.yellowDeep),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _routeMetricsCard(),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _promoCtrl,
                      decoration: _fd(widget.l.promoCodeOptionalLabel, icon: Icons.discount_outlined),
                      onChanged: (_) async {
                        _promoCode = _promoCtrl.text.trim();
                        await _recalcQuote();
                      },
                    ),
                    if (_promoCtrl.text.trim().toUpperCase() == 'WELCOME26') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.success.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: _C.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'WELCOME26 · −20%',
                                style: TextStyle(
                                  color: _C.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_quote != null) ...[
                      NightFareBreakdown(
                        quote: _quote!,
                        promoLabel:
                            _promoCtrl.text.trim().toUpperCase() == 'WELCOME26'
                                ? 'WELCOME26 −20%'
                                : null,
                        nightRateLabel: widget.l.nightFare50,
                        baseLabel:
                            widget.l.fareAmount.split('(').first.trim(),
                        surchargeLabel: 'Night surcharge',
                        totalLabel: 'Total',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.l.nightFareScheduleHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.textSoft.withValues(alpha: 0.95),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (_quote != null) _priceHero(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: _C.textMid,
                              side: const BorderSide(color: _C.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text(widget.l.genericCancel, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _canSubmit
                                ? () {
                                    final key = _selectedRouteKey;
                                    if (key == null) return;
                                    final u = _userGps;
                                    final dl = _effectiveDestinationLatLng();
                                    Navigator.of(context).pop(
                                      PassengerReservationMapResult(
                                        routeKey: key,
                                        promoCode: _promoCode,
                                        scheduleLater: _scheduleLater,
                                        finalFare:
                                            (_quote!['final_fare'] as num).toDouble(),
                                        scheduledPickupAt:
                                            _scheduleLater ? _scheduledPickupAt : null,
                                        pickupAddress: (_pickupGeoLine ?? '').trim().isEmpty
                                            ? null
                                            : _pickupGeoLine!.trim(),
                                        pickupDisplayName: localizedPlaceName(widget.l, _selectedFrom),
                                        destinationAddress: (_destinationAddressLine ?? '')
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : _destinationAddressLine!.trim(),
                                        destinationDisplayName: (_destinationPlaceTitle ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? _destinationPlaceTitle!.trim()
                                            : localizedPlaceName(widget.l, _selectedTo!),
                                        pickupLat: u?.latitude,
                                        pickupLng: u?.longitude,
                                        destinationLat: dl?.latitude,
                                        destinationLng: dl?.longitude,
                                      ),
                                    );
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _C.yellow,
                              foregroundColor: _C.charcoal,
                              disabledBackgroundColor: _C.border,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text(
                              _scheduleLater ? widget.tx('reserveDriver') : widget.l.requestRideButton,
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      _quote != null &&
      (_selectedTo ?? '').isNotEmpty &&
      (!_scheduleLater || _scheduledPickupAt != null);

  Widget _modeRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _chip(label: widget.tx('rideNow'), on: !_scheduleLater, onTap: () {
              setState(() => _scheduleLater = false);
            }),
          ),
          Expanded(
            child: _chip(label: widget.tx('scheduleRide'), on: _scheduleLater, onTap: () {
              setState(() => _scheduleLater = true);
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool on, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: on
              ? const LinearGradient(colors: [_C.yellowLight, _C.yellow, _C.yellowDeep])
              : null,
          color: on ? null : Colors.transparent,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: _C.yellow.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: on ? _C.charcoal : _C.textSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassTile({required Widget child, VoidCallback? onTap}) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border.withValues(alpha: 0.85)),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: box),
    );
  }

  Widget _routeMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFAFAFA),
            _C.yellowSoft.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: _C.yellow.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: _C.yellow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: _routeLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: _C.yellowDeep),
                  )
                : const Icon(Icons.timeline_rounded, color: _C.charcoal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Maps',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _C.textSoft,
                  ),
                ),
                const SizedBox(height: 4),
                if (_route != null)
                  Text(
                    '${_route!.distanceKm.toStringAsFixed(1)} km · ${_durationLabel(_route!.durationSeconds)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: _C.charcoal,
                      letterSpacing: -0.3,
                    ),
                  )
                else if (_routeError != null)
                  Text(
                    _routeError!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                  )
                else
                  Text(
                    _routeLoading ? '…' : '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _C.textMid),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Distance & time from the same route as on the map',
                  style: TextStyle(fontSize: 11, color: _C.textSoft.withValues(alpha: 0.95), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceHero() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                Color.lerp(_C.yellowSoft, _C.yellow, _pulse.value * 0.12)!,
                Colors.white,
              ],
            ),
            border: Border.all(color: _C.yellowDeep.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _C.yellow.withValues(alpha: 0.18 + _pulse.value * 0.08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${(_quote!['final_fare'] as num).toStringAsFixed(2)} DT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _C.charcoal,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.l.passengerFareFinalEstimate,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSoft, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapMarkerFilterBar extends StatelessWidget {
  const _MapMarkerFilterBar({
    required this.markerCategory,
    required this.onChanged,
    required this.tx,
  });

  final _MapMarkerCategory markerCategory;
  final ValueChanged<_MapMarkerCategory> onChanged;
  final String Function(String key, [Object? value]) tx;

  @override
  Widget build(BuildContext context) {
    Widget chip(_MapMarkerCategory f, String labelKey) {
      final on = markerCategory == f;
      return Expanded(
        child: AnimatedScale(
          scale: on ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.white.withValues(alpha: on ? 0.98 : 0.88),
            borderRadius: BorderRadius.circular(999),
            elevation: on ? 10 : 3,
            shadowColor: _C.yellow.withValues(alpha: 0.35),
            child: InkWell(
              onTap: () => onChanged(f),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tx(labelKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 0.15,
                        color: on ? _C.charcoal : _C.textSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_MapMarkerCategory.airports, 'mapFilterAirports'),
        const SizedBox(width: 8),
        chip(_MapMarkerCategory.zones, 'mapFilterZones'),
        const SizedBox(width: 8),
        chip(_MapMarkerCategory.restaurants, 'mapFilterRestaurants'),
      ],
    );
  }
}
