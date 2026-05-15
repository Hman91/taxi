import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/models.dart';
import '../config.dart';
import '../maps/driver_offer_pin_marker.dart';
import '../maps/light_elegant_map_style.dart';
import '../maps/tunisia_zone_coordinates.dart';
import '../services/google_directions_service.dart';
import 'driver_route_map_common.dart';

/// In-card map: exact pickup / destination, driving route, optional driver pin.
/// When [routePolyline] is provided (≥2 points), the map skips a duplicate Directions call.
class DriverOfferRouteMap extends StatefulWidget {
  const DriverOfferRouteMap({
    super.key,
    required this.ride,
    this.driverGps,
    this.height = 228,
    this.routePolyline,
    this.pickupInfoSnippet,
    this.destinationInfoSnippet,
  });

  final Ride ride;
  final LatLng? driverGps;
  final double height;

  /// Pre-computed route from parent (e.g. after a single Directions request).
  final List<LatLng>? routePolyline;

  /// Shown in marker info windows (typically full formatted address).
  final String? pickupInfoSnippet;
  final String? destinationInfoSnippet;

  @override
  State<DriverOfferRouteMap> createState() => _DriverOfferRouteMapState();
}

class _DriverOfferRouteMapState extends State<DriverOfferRouteMap> {
  final _directions = GoogleDirectionsService();
  GoogleMapController? _map;
  List<LatLng> _route = [];
  bool _loading = true;
  BitmapDescriptor? _pickPin;
  BitmapDescriptor? _dropPin;

  static const _routeColor = Color(0xE6FFC200);

  static String _snippet(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return '';
    return t.length <= 72 ? t : '${t.substring(0, 69)}…';
  }

  static bool _polylineEquals(List<LatLng>? a, List<LatLng>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    if (a.isEmpty) return true;
    return a.first.latitude == b.first.latitude &&
        a.first.longitude == b.first.longitude &&
        a.last.latitude == b.last.latitude &&
        a.last.longitude == b.last.longitude;
  }

  @override
  void didUpdateWidget(covariant DriverOfferRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ride.id != widget.ride.id) {
      _applyRouteSource();
      return;
    }
    if (!_polylineEquals(oldWidget.routePolyline, widget.routePolyline)) {
      _applyRouteSource();
    }
  }

  void _applyRouteSource() {
    final poly = widget.routePolyline;
    if (poly != null && poly.length >= 2) {
      setState(() {
        _route = poly;
        _loading = false;
      });
      unawaited(_fitCamera());
    } else {
      setState(() {
        _route = [];
        _loading = true;
      });
      unawaited(_loadRoute());
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPins());
    final poly = widget.routePolyline;
    if (poly != null && poly.length >= 2) {
      _route = poly;
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_fitCamera()));
    } else {
      unawaited(_loadRoute());
    }
  }

  Future<void> _loadPins() async {
    try {
      final p = await DriverOfferPinMarker.pickup();
      final d = await DriverOfferPinMarker.destination();
      if (!mounted) return;
      setState(() {
        _pickPin = p;
        _dropPin = d;
      });
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    if (pick == null || drop == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!_directions.isConfigured) {
      if (mounted) {
        setState(() {
          _route = [pick, drop];
          _loading = false;
        });
        await _fitCamera();
      }
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final res = await _directions.fetchRoute(pick, drop);
      if (!mounted) return;
      setState(() {
        _route = (res != null && res.points.length >= 2)
            ? res.points
            : <LatLng>[pick, drop];
        _loading = false;
      });
      await _fitCamera();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _route = [pick, drop];
        _loading = false;
      });
      await _fitCamera();
    }
  }

  Future<void> _fitCamera() async {
    final c = _map;
    if (c == null || !mounted) return;
    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    final d = widget.driverGps;
    final pts = <LatLng>[..._route];
    if (pick != null) pts.add(pick);
    if (drop != null) pts.add(drop);
    if (d != null) pts.add(d);
    if (pts.isEmpty) return;
    double minLa = pts.first.latitude, maxLa = pts.first.latitude;
    double minLn = pts.first.longitude, maxLn = pts.first.longitude;
    for (final p in pts) {
      minLa = minLa < p.latitude ? minLa : p.latitude;
      maxLa = maxLa > p.latitude ? maxLa : p.latitude;
      minLn = minLn < p.longitude ? minLn : p.longitude;
      maxLn = maxLn > p.longitude ? maxLn : p.longitude;
    }
    await c.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLa - 0.02, minLn - 0.02),
          northeast: LatLng(maxLa + 0.02, maxLn + 0.02),
        ),
        48,
      ),
    );
  }

  Set<Marker> _markers() {
    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    final d = widget.driverGps;
    final ps = _snippet(widget.pickupInfoSnippet);
    final ds = _snippet(widget.destinationInfoSnippet);
    return {
      if (pick != null)
        Marker(
          markerId: const MarkerId('pick'),
          position: pick,
          anchor: const Offset(0.5, 1.0),
          icon: _pickPin ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: ps.isEmpty ? null : ps,
          ),
        ),
      if (drop != null)
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          anchor: const Offset(0.5, 1.0),
          icon: _dropPin ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: ds.isEmpty ? null : ds,
          ),
        ),
      if (d != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: d,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
    };
  }

  Set<Polyline> _polylines() {
    if (_route.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('offer'),
        color: _routeColor,
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
      return _fallbackShell(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Map preview needs Google Maps on Android/iOS with API key.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5C5C5C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    final d = widget.driverGps;
    final initial = d ?? pick ?? drop ?? TunisiaZoneCoordinates.tunisOverview;

    return _fallbackShell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              style: kPassengerLightMapStyleJson,
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: 11,
                tilt: 12,
              ),
              markers: _markers(),
              polylines: _polylines(),
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              buildingsEnabled: true,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              onMapCreated: (c) async {
                _map = c;
                await _fitCamera();
              },
            ),
            if (_loading)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x33FFFFFF),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFFFC200),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackShell({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
        ),
        border: Border.all(color: const Color(0xFFE6A800).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
