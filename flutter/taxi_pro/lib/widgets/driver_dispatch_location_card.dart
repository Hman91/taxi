import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../services/google_geocoding_service.dart';

/// Dispatch hub: driver's **current place** as Google Geocoding `formatted_address` (no map).
class DriverDispatchLocationCard extends StatefulWidget {
  const DriverDispatchLocationCard({
    super.key,
    this.seedGps,
    this.onLiveGps,
  });

  final LatLng? seedGps;
  final ValueChanged<LatLng>? onLiveGps;

  @override
  State<DriverDispatchLocationCard> createState() =>
      _DriverDispatchLocationCardState();
}

class _DriverDispatchLocationCardState extends State<DriverDispatchLocationCard> {
  final _geocode = GoogleGeocodingService();
  StreamSubscription<Position>? _posSub;
  Timer? _geoDebounce;
  LatLng? _position;
  String? _address;
  bool _loadingAddress = false;
  String? _geoError;

  static const _yellow = Color(0xFFFFC200);
  static const _yellowDeep = Color(0xFFE6A800);
  static const _charcoal = Color(0xFF1A1A1A);
  static const _textSoft = Color(0xFF5C5C5C);

  @override
  void initState() {
    super.initState();
    _position = widget.seedGps;
    _scheduleGeocodeFrom(_position);
    _startLiveTracking();
  }

  @override
  void didUpdateWidget(covariant DriverDispatchLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedGps != widget.seedGps && widget.seedGps != null) {
      _position ??= widget.seedGps;
      _scheduleGeocodeFrom(_position);
    }
  }

  void _startLiveTracking() {
    if (kIsWeb || !isGoogleMapsPlatformSupported) return;
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
      ),
    ).listen(
      (p) {
        final ll = LatLng(p.latitude, p.longitude);
        if (!mounted) return;
        setState(() => _position = ll);
        widget.onLiveGps?.call(ll);
        _scheduleGeocodeFrom(ll);
      },
      onError: (_) {},
    );
  }

  void _scheduleGeocodeFrom(LatLng? p) {
    if (p == null) return;
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      unawaited(_fetchAddress(p));
    });
  }

  Future<void> _fetchAddress(LatLng p) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (!_geocode.isConfigured) {
      setState(() {
        _loadingAddress = false;
        _geoError = null;
        _address = l != null
            ? l.driverLocationRow(
                p.latitude.toStringAsFixed(6),
                p.longitude.toStringAsFixed(6),
              )
            : '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
      });
      return;
    }
    setState(() {
      _loadingAddress = true;
      _geoError = null;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final addr = await _geocode.reverseFormattedAddress(p, language: lang);
      if (!mounted) return;
      setState(() {
        _loadingAddress = false;
        _address = (addr != null && addr.isNotEmpty)
            ? addr
            : (l != null
                ? l.driverLocationRow(
                    p.latitude.toStringAsFixed(6),
                    p.longitude.toStringAsFixed(6),
                  )
                : '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAddress = false;
        _geoError = e.toString();
        _address = l != null
            ? l.driverLocationRow(
                p.latitude.toStringAsFixed(6),
                p.longitude.toStringAsFixed(6),
              )
            : '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _refreshNow() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.passengerLocationServiceDisabled)),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.passengerLocationPermissionDenied)),
          );
        }
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final ll = LatLng(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() => _position = ll);
      widget.onLiveGps?.call(ll);
      await _fetchAddress(ll);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _geoDebounce?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const radius = BorderRadius.all(Radius.circular(26));

    if (kIsWeb || !isGoogleMapsPlatformSupported) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _yellowDeep.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(22),
        child: Text(
          l.passengerLocationUnavailable,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textSoft,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      );
    }

    final body = _position == null
        ? Text(
            l.passengerLocationDetecting,
            style: const TextStyle(
              color: _textSoft,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.4,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.passengerLocationCurrent,
                style: const TextStyle(
                  color: _textSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _address ?? l.passengerLocationDetecting,
                      style: const TextStyle(
                        color: _charcoal,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (_loadingAddress)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 2),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _yellowDeep,
                        ),
                      ),
                    ),
                ],
              ),
              if (_geoError != null &&
                  (_address == null || _address!.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _geoError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _yellowDeep.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _yellowDeep.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.pin_drop_rounded,
                    color: _charcoal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: body),
                IconButton(
                  onPressed: () => unawaited(_refreshNow()),
                  icon: const Icon(Icons.my_location_rounded, color: _charcoal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
