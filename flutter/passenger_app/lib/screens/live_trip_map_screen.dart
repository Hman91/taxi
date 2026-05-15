import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/models.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/ride_address_display.dart';
import '../maps/light_elegant_map_style.dart';
import '../maps/tunisia_zone_coordinates.dart';
import '../services/google_directions_service.dart';
import '../services/google_places_service.dart';

enum LiveTripMapRole { passenger, driver }

/// Full-screen immersive map: Places search, markers, driving route.
class LiveTripMapScreen extends StatefulWidget {
  const LiveTripMapScreen({
    super.key,
    required this.role,
    this.myGps,
    this.focusRide,
    this.driverDeclaredZone,
  });

  final LiveTripMapRole role;
  final LatLng? myGps;
  final Ride? focusRide;
  final String? driverDeclaredZone;

  @override
  State<LiveTripMapScreen> createState() => _LiveTripMapScreenState();
}

class _LiveTripMapScreenState extends State<LiveTripMapScreen>
    with SingleTickerProviderStateMixin {
  final _places = GooglePlacesService();
  final _directions = GoogleDirectionsService();
  final _searchCtrl = TextEditingController();
  GoogleMapController? _map;
  Timer? _debounce;

  List<PlaceAutocompleteItem> _suggestions = [];
  bool _searchLoading = false;
  String? _searchError;

  LatLng? _pickPin;
  LatLng? _dropPin;
  String? _pickLabel;
  String? _dropLabel;

  List<LatLng> _route = [];
  bool _routeLoading = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _applyFocusRideSnapshot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshRoute());
    });
  }

  void _applyFocusRideSnapshot() {
    final r = widget.focusRide;
    if (r == null) return;
    _pickPin = _ridePickupLatLng(r);
    _dropPin = _rideDestLatLng(r);
    _pickLabel = _storedLine(
      address: r.pickupAddress,
      displayName: r.pickupDisplayName,
      zoneKey: r.pickup,
    );
    _dropLabel = _storedLine(
      address: r.destinationAddress,
      displayName: r.destinationDisplayName,
      zoneKey: r.destination,
    );
  }

  static String _storedLine({
    required String? address,
    required String? displayName,
    required String zoneKey,
  }) {
    final a = (address ?? '').trim();
    if (a.isNotEmpty) return a;
    final d = (displayName ?? '').trim();
    if (d.isNotEmpty) return d;
    return zoneKey.trim();
  }

  static LatLng? _latLngFromStored(double? lat, double? lng, String zoneKey) {
    if (lat != null && lng != null && (lat.abs() > 1e-4 || lng.abs() > 1e-4)) {
      return LatLng(lat, lng);
    }
    return TunisiaZoneCoordinates.lookup(zoneKey);
  }

  LatLng? _ridePickupLatLng([Ride? ride]) {
    final r = ride ?? widget.focusRide;
    if (r == null) return null;
    return _latLngFromStored(r.pickupLat, r.pickupLng, r.pickup);
  }

  LatLng? _rideDestLatLng([Ride? ride]) {
    final r = ride ?? widget.focusRide;
    if (r == null) return null;
    return _latLngFromStored(r.destinationLat, r.destinationLng, r.destination);
  }

  String _legendPickupLabel(AppLocalizations l) {
    final manual = (_pickLabel ?? '').trim();
    if (manual.isNotEmpty) return manual;
    final r = widget.focusRide;
    if (r == null) return '—';
    return ridePickupPrimaryLine(r, l);
  }

  String _legendDestinationLabel(AppLocalizations l) {
    final manual = (_dropLabel ?? '').trim();
    if (manual.isNotEmpty) return manual;
    final r = widget.focusRide;
    if (r == null) return '—';
    return rideDestinationPrimaryLine(r, l);
  }

  LatLng? _driverApproxPin() {
    final z = (widget.driverDeclaredZone ?? '').trim();
    if (z.isNotEmpty) return TunisiaZoneCoordinates.lookup(z);
    final dz = (widget.focusRide?.driverCurrentZone ?? '').trim();
    if (dz.isNotEmpty) return TunisiaZoneCoordinates.lookup(dz);
    return null;
  }

  Future<void> _onSearchChanged(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 360), () async {
      final v = value.trim();
      if (v.length < 2) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      if (!_places.isConfigured) {
        if (mounted) {
          setState(() {
            _searchError = 'Places API key missing';
            _suggestions = [];
          });
        }
        return;
      }
      setState(() {
        _searchLoading = true;
        _searchError = null;
      });
      try {
        final bias = widget.myGps ?? TunisiaZoneCoordinates.tunisOverview;
        final list = await _places.autocomplete(v, biasCenter: bias);
        if (!mounted) return;
        setState(() {
          _suggestions = list;
          _searchLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _searchLoading = false;
          _searchError = e.toString();
        });
      }
    });
  }

  Future<void> _selectSuggestion(PlaceAutocompleteItem item) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchLoading = true;
      _suggestions = [];
    });
    try {
      final d = await _places.placeDetails(item.placeResourceName);
      if (!mounted) return;
      if (d == null) {
        setState(() => _searchLoading = false);
        return;
      }
      setState(() {
        _searchLoading = false;
        _searchCtrl.clear();
      });
      await _showPinAssignSheet(d);
    } catch (_) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  Future<void> _showPinAssignSheet(PlaceDetailsResult d) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.34,
          minChildSize: 0.28,
          maxChildSize: 0.55,
          builder: (_, scroll) {
            return _GlassPanel(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    d.title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.25,
                    ),
                  ),
                  if ((d.formattedAddress ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      d.formattedAddress!,
                      style: TextStyle(
                        color: const Color(0xFF5C5C5C).withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SheetAction(
                    icon: Icons.flag_rounded,
                    label: 'Set as pickup',
                    accent: const Color(0xFFFFC200),
                    onTap: () => Navigator.pop(ctx, 'pickup'),
                  ),
                  const SizedBox(height: 10),
                  _SheetAction(
                    icon: Icons.place_rounded,
                    label: 'Set as destination',
                    accent: const Color(0xFFFF7043),
                    onTap: () => Navigator.pop(ctx, 'dest'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color:
                              const Color(0xFF5C5C5C).withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || choice == null) return;
    setState(() {
      if (choice == 'pickup') {
        _pickPin = d.position;
        _pickLabel = d.title;
      } else {
        _dropPin = d.position;
        _dropLabel = d.title;
      }
    });
    await _refreshRoute();
    await _animateToAll();
  }

  LatLng get _pickupResolved =>
      _pickPin ??
      _ridePickupLatLng() ??
      TunisiaZoneCoordinates.tunisOverview;

  LatLng get _destResolved =>
      _dropPin ?? _rideDestLatLng() ?? TunisiaZoneCoordinates.tunisOverview;

  Future<void> _refreshRoute() async {
    final a = _pickupResolved;
    final b = _destResolved;
    final dist = _haversineKm(a, b);
    if (dist < 0.05) {
      if (mounted) setState(() => _route = []);
      return;
    }
    if (!_directions.isConfigured) {
      if (mounted) setState(() => _route = [a, b]);
      return;
    }
    setState(() => _routeLoading = true);
    final pts = await _directions.routePoints(a, b);
    if (!mounted) return;
    setState(() {
      _routeLoading = false;
      _route = pts ?? [a, b];
    });
    await _animateToAll();
  }

  double _haversineKm(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = _rad(p2.latitude - p1.latitude);
    final dLng = _rad(p2.longitude - p1.longitude);
    final la1 = _rad(p1.latitude);
    final la2 = _rad(p2.latitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(la1) * math.cos(la2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  double _rad(double d) => d * math.pi / 180.0;

  Future<void> _animateToAll() async {
    final c = _map;
    if (c == null) return;
    final pts = <LatLng>[
      if (widget.myGps != null) widget.myGps!,
      if (_driverApproxPin() != null) _driverApproxPin()!,
      _pickupResolved,
      _destResolved,
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 13.2));
      return;
    }
    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLng = pts.first.longitude;
    var maxLng = pts.first.longitude;
    for (final p in pts.skip(1)) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 11));
    }
  }

  Set<Marker> _buildMarkers() {
    final driverPin = _driverApproxPin();
    final showDriverPin = driverPin != null &&
        (widget.role == LiveTripMapRole.passenger || widget.myGps == null);

    return {
      if (widget.myGps != null)
        Marker(
          markerId: const MarkerId('me'),
          position: widget.myGps!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: widget.role == LiveTripMapRole.passenger
                ? 'You'
                : 'Your GPS',
          ),
        ),
      if (showDriverPin)
        Marker(
          markerId: const MarkerId('driver_zone'),
          position: driverPin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Driver (zone)'),
        ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupResolved,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: (_pickLabel ?? '').trim().isEmpty ? null : _pickLabel,
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destResolved,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: (_dropLabel ?? '').trim().isEmpty ? null : _dropLabel,
        ),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (_route.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('trip'),
        color: const Color(0xE6FFC200),
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        points: _route,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !isGoogleMapsPlatformSupported) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: const Text('Live map'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              kIsWeb
                  ? 'Google Maps runs on Android/iOS builds in this project. Use a device or emulator with GOOGLE_MAPS_API_KEY set.'
                  : 'Add your key: flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY\n'
                      'and enable Maps SDK, Places API, Directions API in Google Cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3F3F3F).withValues(alpha: 0.9),
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final initial = widget.myGps ??
        _pickPin ??
        _ridePickupLatLng() ??
        TunisiaZoneCoordinates.tunisOverview;

    final routeAnim = ModalRoute.of(context)?.animation ??
        const AlwaysStoppedAnimation<double>(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initial,
              zoom: 11.4,
              tilt: 42,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            myLocationButtonEnabled: false,
            buildingsEnabled: true,
            mapType: MapType.normal,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 112,
              bottom: 200,
            ),
            onMapCreated: (c) async {
              _map = c;
              await c.setMapStyle(kPassengerLightMapStyleJson);
              await _animateToAll();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _RoundGlassIcon(
                        onTap: () => Navigator.of(context).maybePop(),
                        icon: Icons.arrow_back_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.lerp(
                                      const Color(0x22FFC200),
                                      const Color(0x55FFC200),
                                      _pulse.value,
                                    )!,
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _GlassPanel(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFFFFC200),
                                  decoration: InputDecoration(
                                    hintText: 'Search places in Tunisia…',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF5C5C5C)
                                          .withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: const Color(0xFF3F3F3F)
                                          .withValues(alpha: 0.75),
                                    ),
                                    suffixIcon: _searchLoading
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFFFC200),
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() {
                                                _suggestions = [];
                                                _searchError = null;
                                              });
                                            },
                                            icon: Icon(
                                              Icons.close_rounded,
                                              color: const Color(0xFF5C5C5C)
                                                  .withValues(alpha: 0.75),
                                            ),
                                          ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _GlassPanel(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: const Color(0xFFDDD8C8)
                                  .withValues(alpha: 0.85),
                            ),
                            itemBuilder: (_, i) {
                              final s = _suggestions[i];
                              final ap = s.isAirport;
                              return ListTile(
                                dense: true,
                                tileColor: ap
                                    ? const Color(0xFFE3F2FD).withValues(alpha: 0.85)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  ap
                                      ? Icons.flight_takeoff_rounded
                                      : Icons.place_outlined,
                                  color: ap
                                      ? const Color(0xFF0D47A1)
                                      : const Color(0xFF5C5C5C),
                                  size: 22,
                                ),
                                title: Text(
                                  s.label.isEmpty ? s.placeResourceName : s.label,
                                  style: TextStyle(
                                    color: ap
                                        ? const Color(0xFF0D47A1)
                                        : const Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.north_west_rounded,
                                  color: const Color(0xFF5C5C5C)
                                      .withValues(alpha: 0.55),
                                  size: 18,
                                ),
                                onTap: () => unawaited(_selectSuggestion(s)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (_searchError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _searchError!,
                        style: const TextStyle(color: Color(0xFFC62828)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: routeAnim,
                  curve: Curves.easeOutCubic,
                ),
                child: _GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD84D),
                                    Color(0xFFFFC200),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.role == LiveTripMapRole.passenger
                                    ? 'PASSENGER LIVE'
                                    : 'DRIVER LIVE',
                                style: const TextStyle(
                                  color: Color(0xFF111111),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_routeLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFC200),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.focusRide != null
                              ? (widget.focusRide!.id <= 0
                                  ? 'Route preview'
                                  : 'Ride #${widget.focusRide!.id}')
                              : 'Route preview',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LegendRow(
                          color: const Color(0xFFAB47BC),
                          label: 'Pickup',
                          value: _legendPickupLabel(
                            AppLocalizations.of(context)!,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _LegendRow(
                          color: const Color(0xFFFF7043),
                          label: 'Destination',
                          value: _legendDestinationLabel(
                            AppLocalizations.of(context)!,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  await _refreshRoute();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1A1A1A),
                                  side: BorderSide(
                                    color: const Color(0xFFDDD8C8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Refresh route'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => unawaited(_animateToAll()),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC200),
                                  foregroundColor: const Color(0xFF111111),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Fit map'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          border: Border.all(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC200).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

class _RoundGlassIcon extends StatelessWidget {
  const _RoundGlassIcon({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xF2FFFFFF),
            border: Border.all(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1A1A1A).withValues(alpha: 0.88)),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.55)),
            color: const Color(0xFFFFF8E0).withValues(alpha: 0.65),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: const Color(0xFF5C5C5C).withValues(alpha: 0.55)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.55),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF5C5C5C).withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
