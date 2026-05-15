import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../services/google_directions_service.dart';
import '../services/google_geocoding_service.dart';
import '../services/taxi_app_service.dart';
import 'driver_offer_route_map.dart';
import 'driver_route_map_common.dart';
import 'night_fare_breakdown.dart';

/// B2B rides bill [Ride.b2bFare]; live GPS/table quotes are for routing only and can differ.
void _applyB2bLockedFareToQuote(Map<String, dynamic> quote, Ride ride) {
  if (ride.isB2b != true || ride.b2bFare == null) return;
  final T = ride.b2bFare!;
  final qb = ride.quotedBaseFareDt;
  final qn = ride.quotedNightSurchargeDt;
  final qSum = (qb != null && qn != null) ? qb + qn : null;
  var isNight = ride.quotedIsNight == true ||
      (qn != null && qn > 0.0001);
  if (!isNight) {
    isNight = quote['is_night'] == true;
  }
  const eps = 0.05;
  late double base;
  late double sur;
  if (qSum != null && (qSum - T).abs() <= eps) {
    base = qb!;
    sur = T - base;
    if (sur < 0) {
      sur = 0;
      base = T;
    }
    isNight = sur > 0.0001;
  } else if (isNight) {
    base = T / 1.5;
    sur = T - base;
  } else {
    base = T;
    sur = 0;
  }
  quote['final_fare'] = T;
  quote['base_fare'] = base;
  quote['night_surcharge_dt'] = sur;
  quote['is_night'] = sur > 0.0001;
}

/// Premium ride-offer card: full addresses, route map, fare / distance / ETA, accept / reject.
class DriverRideOfferCard extends StatefulWidget {
  const DriverRideOfferCard({
    super.key,
    required this.ride,
    required this.api,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
    this.driverGps,
    this.localOutcome,
  });

  final Ride ride;
  final TaxiAppService api;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;
  final LatLng? driverGps;
  final String? localOutcome;

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _borderGold = Color(0xFFE6A800);
  static const Color _titleGold = Color(0xFF1A1A1A);
  static const Color _textSoft = Color(0xFF5C5C5C);
  static const Color _surfaceAlt = Color(0xFFF5F1E8);
  static const Color _yellowSoft = Color(0xFFFFF8E0);
  static const Color _accentGreen = Color(0xFF28A745);
  static const Color _accentRed = Color(0xFFDC3545);
  static const Color _pickupTint = Color(0xFFEDE9FE);
  static const Color _destTint = Color(0xFFFFF3E0);

  @override
  State<DriverRideOfferCard> createState() => _DriverRideOfferCardState();
}

class _DriverRideOfferCardState extends State<DriverRideOfferCard> {
  Map<String, dynamic>? _quote;
  bool _quoteLoading = true;
  List<LatLng>? _routePolyline;
  String? _resolvedPickup;
  String? _resolvedDestination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapOffer());
    });
  }

  Future<void> _bootstrapOffer() async {
    await Future.wait([
      _resolveAddresses(),
      _loadQuoteAndRoute(),
    ]);
  }

  Future<void> _resolveAddresses() async {
    if (!mounted) return;
    final geo = GoogleGeocodingService();
    if (!geo.isConfigured) return;
    final lang = Localizations.localeOf(context).languageCode;
    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    final tasks = <Future<void>>[];
    if ((widget.ride.pickupAddress ?? '').trim().isEmpty && pick != null) {
      tasks.add(() async {
        final t = await geo.reverseFormattedAddress(pick, language: lang);
        if (!mounted || (t ?? '').trim().isEmpty) return;
        setState(() => _resolvedPickup = t!.trim());
      }());
    }
    if ((widget.ride.destinationAddress ?? '').trim().isEmpty && drop != null) {
      tasks.add(() async {
        final t = await geo.reverseFormattedAddress(drop, language: lang);
        if (!mounted || (t ?? '').trim().isEmpty) return;
        setState(() => _resolvedDestination = t!.trim());
      }());
    }
    await Future.wait(tasks);
  }

  Future<void> _loadQuoteAndRoute() async {
    final pick = RideRouteCoords.pickup(widget.ride);
    final drop = RideRouteCoords.destination(widget.ride);
    final dirs = GoogleDirectionsService();
    try {
      if (pick != null && drop != null && dirs.isConfigured) {
        final route = await dirs.fetchRoute(pick, drop);
        if (!mounted) return;
        if (route != null &&
            route.points.length >= 2 &&
            route.distanceMeters > 0) {
          final pt = widget.ride.scheduledPickupAt != null &&
                  (widget.ride.scheduledPickupAt!).trim().isNotEmpty
              ? DateTime.tryParse(widget.ride.scheduledPickupAt!)
              : null;
          final q = await widget.api.quoteGps(
              distanceKm: route.distanceKm, pricingTime: pt);
          if (!mounted) return;
          final merged = Map<String, dynamic>.from(q);
          merged['quote_mode'] = 'gps';
          merged['directions_km'] = route.distanceKm;
          merged['directions_duration_seconds'] = route.durationSeconds;
          _applyB2bLockedFareToQuote(merged, widget.ride);
          setState(() {
            _quote = merged;
            _routePolyline = route.points;
            _quoteLoading = false;
          });
          return;
        }
      }
      final key =
          '${widget.ride.pickup.trim()} $airportRouteKeySeparator ${widget.ride.destination.trim()}';
      final pt = widget.ride.scheduledPickupAt != null &&
              (widget.ride.scheduledPickupAt!).trim().isNotEmpty
          ? DateTime.tryParse(widget.ride.scheduledPickupAt!)
          : null;
      final q = await widget.api.quoteAirport(key, pricingTime: pt);
      if (!mounted) return;
      q['route_key'] = key;
      q['quote_mode'] = 'airport';
      _applyB2bLockedFareToQuote(q, widget.ride);
      setState(() {
        _quote = q;
        _routePolyline = null;
        _quoteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _routePolyline = null;
        _quoteLoading = false;
      });
    }
  }

  int _etaMinutesHeuristic(double distanceKm) =>
      (distanceKm * 2.52).round().clamp(1, 999);

  int _durationMinutesFromSeconds(int seconds) =>
      (seconds / 60).ceil().clamp(1, 999);

  String _scheduledLabel(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Scheduled pickup';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _pickupPrimary(AppLocalizations loc) {
    final a = (widget.ride.pickupAddress ?? '').trim();
    if (a.isNotEmpty) return a;
    final b = (_resolvedPickup ?? '').trim();
    if (b.isNotEmpty) return b;
    final c = (widget.ride.pickupDisplayName ?? '').trim();
    if (c.isNotEmpty) return c;
    return localizedPlaceName(loc, widget.ride.pickup);
  }

  String _destinationPrimary(AppLocalizations loc) {
    final a = (widget.ride.destinationAddress ?? '').trim();
    if (a.isNotEmpty) return a;
    final b = (_resolvedDestination ?? '').trim();
    if (b.isNotEmpty) return b;
    final c = (widget.ride.destinationDisplayName ?? '').trim();
    if (c.isNotEmpty) return c;
    return localizedPlaceName(loc, widget.ride.destination);
  }

  String? _pickupZoneSubtitle(AppLocalizations loc, String primary) {
    final zone = localizedPlaceName(loc, widget.ride.pickup).trim();
    if (zone.isEmpty) return null;
    if (zone == primary.trim()) return null;
    return zone;
  }

  String? _destinationZoneSubtitle(AppLocalizations loc, String primary) {
    final zone = localizedPlaceName(loc, widget.ride.destination).trim();
    if (zone.isEmpty) return null;
    if (zone == primary.trim()) return null;
    return zone;
  }

  String _mapPickupSnippet(AppLocalizations loc) => _pickupPrimary(loc);

  String _mapDestinationSnippet(AppLocalizations loc) =>
      _destinationPrimary(loc);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pickupMain = _pickupPrimary(loc);
    final destMain = _destinationPrimary(loc);
    final pickupSub = _pickupZoneSubtitle(loc, pickupMain);
    final destSub = _destinationZoneSubtitle(loc, destMain);

    final fare = _quote == null
        ? null
        : (_quote!['final_fare'] as num?)?.toDouble() ??
            (_quote!['base_fare'] as num?)?.toDouble();
    final distGps = (_quote?['directions_km'] as num?)?.toDouble();
    final distCat = (_quote?['distance_km'] as num?)?.toDouble();
    final distanceKm = distGps ?? distCat;

    final sec = (_quote?['directions_duration_seconds'] as num?)?.round();
    final timeChip = _quoteLoading
        ? null
        : sec != null && sec > 0
            ? loc.driverOfferTimeChip(
                '${_durationMinutesFromSeconds(sec)}',
              )
            : distanceKm != null
                ? loc.driverOfferTimeChip(
                    '${_etaMinutesHeuristic(distanceKm)}',
                  )
                : null;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DriverRideOfferCard._bg,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: DriverRideOfferCard._borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DriverRideOfferCard._titleGold.withValues(alpha: 0.10),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DriverRideOfferCard._yellowSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DriverRideOfferCard._borderGold.withValues(alpha: 0.36),
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: DriverRideOfferCard._titleGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.driverRideRequestBannerTitle,
                    style: const TextStyle(
                      color: DriverRideOfferCard._titleGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AddressDetailCard(
              title: loc.driverOfferFromLabel,
              address: pickupMain,
              subtitle: pickupSub,
              tint: DriverRideOfferCard._pickupTint,
              borderAccent: const Color(0xFF7C3AED),
              icon: Icons.my_location_rounded,
              iconColor: const Color(0xFF5B21B6),
            ),
            const SizedBox(height: 6),
            _AddressDetailCard(
              title: loc.driverOfferToLabel,
              address: destMain,
              subtitle: destSub,
              tint: DriverRideOfferCard._destTint,
              borderAccent: const Color(0xFFE65100),
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFFBF360C),
            ),
            const SizedBox(height: 12),
            Text(
              loc.driverOfferRoutePreviewLabel,
              style: TextStyle(
                color: DriverRideOfferCard._textSoft.withValues(alpha: 0.95),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            if (_quoteLoading)
              SizedBox(
                height: 232,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E0)],
                    ),
                    border: Border.all(
                      color: DriverRideOfferCard._borderGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DriverRideOfferCard._borderGold,
                      ),
                    ),
                  ),
                ),
              )
            else
              DriverOfferRouteMap(
                ride: widget.ride,
                driverGps: widget.driverGps,
                height: 232,
                routePolyline: _routePolyline,
                pickupInfoSnippet: _mapPickupSnippet(loc),
                destinationInfoSnippet: _mapDestinationSnippet(loc),
              ),
            if (widget.localOutcome != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.localOutcome == 'released'
                      ? DriverRideOfferCard._surfaceAlt
                      : const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.localOutcome == 'released'
                        ? DriverRideOfferCard._borderGold.withValues(alpha: 0.22)
                        : const Color(0xFF1A7A4A).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  widget.localOutcome == 'released'
                      ? 'Offer released — route stays for reference.'
                      : 'Accepted — updating your trips…',
                  style: TextStyle(
                    color: widget.localOutcome == 'released'
                        ? DriverRideOfferCard._textSoft
                        : const Color(0xFF1A7A4A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _PassengerInfoCard(
              ride: widget.ride,
              loc: loc,
            ),
            if ((widget.ride.scheduledPickupAt ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DriverRideOfferCard._yellowSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DriverRideOfferCard._borderGold.withValues(alpha: 0.55)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: DriverRideOfferCard._titleGold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled • ${_scheduledLabel(widget.ride.scheduledPickupAt!)}',
                        style: const TextStyle(
                          color: DriverRideOfferCard._titleGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (!_quoteLoading)
              _OfferChips(
                fareText: fare != null
                    ? loc.driverOfferFareChip(_formatAmount(fare))
                    : null,
                distanceText: distanceKm != null
                    ? loc.driverOfferDistanceChip(
                        distanceKm.toStringAsFixed(1),
                      )
                    : null,
                timeText: timeChip,
              ),
            if (!_quoteLoading && _quote != null) ...[
              const SizedBox(height: 12),
              NightFareBreakdown(
                quote: _quote!,
                nightRateLabel: loc.nightFare50,
              ),
            ],
            if (!_quoteLoading) const SizedBox(height: 16),
            if (_quoteLoading) const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      onPressed: (widget.busy || widget.localOutcome != null)
                          ? null
                          : widget.onReject,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DriverRideOfferCard._accentRed,
                          Color(0xFFB02A37),
                        ],
                      ),
                      label: loc.driverRejectOfferButton,
                      icon: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradientButton(
                      onPressed: (widget.busy || widget.localOutcome != null)
                          ? null
                          : widget.onAccept,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DriverRideOfferCard._accentGreen,
                          Color(0xFF1E7E34),
                        ],
                      ),
                      label: loc.acceptRide,
                      icon: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double v) => v.toStringAsFixed(3);
}

class _AddressDetailCard extends StatelessWidget {
  const _AddressDetailCard({
    required this.title,
    required this.address,
    required this.subtitle,
    required this.tint,
    required this.borderAccent,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String address;
  final String? subtitle;
  final Color tint;
  final Color borderAccent;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderAccent.withValues(alpha: 0.26),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderAccent.withValues(alpha: 0.32)),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: DriverRideOfferCard._textSoft.withValues(alpha: 0.88),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DriverRideOfferCard._titleGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.22,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DriverRideOfferCard._textSoft.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerInfoCard extends StatelessWidget {
  const _PassengerInfoCard({
    required this.ride,
    required this.loc,
  });

  final Ride ride;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final hasB2b = ride.isB2b == true;
    final hasPassenger = !hasB2b &&
        ((ride.passengerName ?? '').trim().isNotEmpty ||
            (ride.passengerPhone ?? '').trim().isNotEmpty);
    if (!hasPassenger && !hasB2b) return const SizedBox.shrink();

    final detailStyle = TextStyle(
      color: DriverRideOfferCard._textSoft,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DriverRideOfferCard._surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DriverRideOfferCard._borderGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasB2b) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 16,
                  color: DriverRideOfferCard._textSoft.withValues(alpha: 0.88),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (ride.b2bTenantName ?? '').trim().isNotEmpty
                            ? (ride.b2bTenantName ?? '').trim()
                            : loc.driverOfferB2bCompanyUnknown,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          height: 1.2,
                          color: DriverRideOfferCard._titleGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${loc.driverOfferB2bGuestLabel}: ${(ride.b2bGuestName ?? '').trim().isEmpty ? '—' : ride.b2bGuestName!.trim()}',
                        style: detailStyle,
                      ),
                      if ((ride.b2bRoomNumber ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${loc.driverOfferB2bRoomLabel}: ${ride.b2bRoomNumber!.trim()}',
                          style: detailStyle,
                        ),
                      ],
                      if (ride.b2bFare != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          loc.driverOfferB2bAgreedFare(
                              ride.b2bFare!.toStringAsFixed(3)),
                          style: const TextStyle(
                            color: DriverRideOfferCard._titleGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (hasPassenger) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: DriverRideOfferCard._textSoft.withValues(alpha: 0.88),
                ),
                const SizedBox(width: 6),
                Text(
                  loc.driverOfferPassengerSectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 0.55,
                    color: DriverRideOfferCard._titleGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${loc.driverOfferPassengerNameLabel}: ${(ride.passengerName ?? '').trim().isEmpty ? '—' : ride.passengerName!.trim()}',
              style: detailStyle,
            ),
            const SizedBox(height: 2),
            Text(
              '${loc.driverOfferPassengerPhoneLabel}: ${(ride.passengerPhone ?? '').trim().isEmpty ? '—' : ride.passengerPhone!.trim()}',
              style: detailStyle,
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferChips extends StatelessWidget {
  const _OfferChips({
    required this.fareText,
    required this.distanceText,
    required this.timeText,
  });

  final String? fareText;
  final String? distanceText;
  final String? timeText;

  @override
  Widget build(BuildContext context) {
    if (fareText == null && distanceText == null && timeText == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (fareText != null)
          Expanded(
            child: _Pill(
              background: DriverRideOfferCard._yellowSoft,
              foreground: DriverRideOfferCard._titleGold,
              text: fareText!,
              icon: const Icon(Icons.payments_rounded,
                  size: 15, color: Color(0xFF92400E)),
            ),
          ),
        if (fareText != null && (distanceText != null || timeText != null))
          const SizedBox(width: 8),
        if (distanceText != null)
          Expanded(
            child: _Pill(
              background: const Color(0xFFDEEBFF),
              foreground: const Color(0xFF1E3A8A),
              text: distanceText!,
              icon: const Icon(
                Icons.straighten_rounded,
                size: 15,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        if (distanceText != null && timeText != null) const SizedBox(width: 8),
        if (timeText != null)
          Expanded(
            child: _Pill(
              background: const Color(0xFFD4EDDA),
              foreground: const Color(0xFF1A7A4A),
              text: timeText!,
              icon: const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Color(0xFF1A7A4A),
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.foreground,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final String text;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.gradient,
    required this.label,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
