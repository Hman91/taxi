import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_address_display.dart';
import '../services/taxi_app_service.dart';

/// B2B rides bill [Ride.b2bFare]; live quotes can differ from the locked corporate total.
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

/// Dark ride-offer card (pickup / destination, fare chips, accept / reject).
class DriverRideOfferCard extends StatefulWidget {
  const DriverRideOfferCard({
    super.key,
    required this.ride,
    required this.api,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
  });

  final Ride ride;
  final TaxiAppService api;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;

  static const Color _bg = Color(0xFF12192B);
  static const Color _pageBg = Color(0xFF0A0F1B);
  static const Color _borderGold = Color(0xFFE8C547);
  static const Color _titleGold = Color(0xFFFFD666);
  static const Color _accentGreen = Color(0xFF28A745);
  static const Color _accentRed = Color(0xFFDC3545);

  @override
  State<DriverRideOfferCard> createState() => _DriverRideOfferCardState();
}

class _DriverRideOfferCardState extends State<DriverRideOfferCard> {
  Map<String, dynamic>? _quote;
  bool _quoteLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final key =
        '${widget.ride.pickup.trim()} $airportRouteKeySeparator ${widget.ride.destination.trim()}';
    final pt = DateTime.tryParse(widget.ride.scheduledPickupAt ?? '');
    try {
      final q = await widget.api.quoteAirport(key, pricingTime: pt);
      if (!mounted) return;
      _applyB2bLockedFareToQuote(q, widget.ride);
      setState(() {
        _quote = q;
        _quoteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _quoteLoading = false;
      });
    }
  }

  int _etaMinutes(double distanceKm) =>
      (distanceKm * 2.52).round().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pickupLabel = ridePickupTitle(widget.ride, loc);
    final pickupAddr = ridePickupAddressLine(widget.ride, loc);
    final destLabel = rideDestinationTitle(widget.ride, loc);
    final destAddr = rideDestinationAddressLine(widget.ride, loc);

    final fare = _quote == null
        ? null
        : (_quote!['final_fare'] as num?)?.toDouble() ??
            (_quote!['base_fare'] as num?)?.toDouble();
    final distanceKm =
        _quote == null ? null : (_quote!['distance_km'] as num?)?.toDouble();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DriverRideOfferCard._bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DriverRideOfferCard._borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DriverRideOfferCard._pageBg.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🚨', style: TextStyle(fontSize: 22)),
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
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DarkCompactAddress(
              label: loc.driverOfferFromLabel,
              title: pickupLabel,
              subtitle: (pickupAddr ?? '').trim().isEmpty
                  ? null
                  : (pickupAddr ?? '').trim(),
              borderAccent: DriverRideOfferCard._accentRed.withOpacity(0.45),
              icon: Icons.my_location_rounded,
              iconColor: DriverRideOfferCard._accentRed,
            ),
            const SizedBox(height: 6),
            _DarkCompactAddress(
              label: loc.driverOfferToLabel,
              title: destLabel,
              subtitle: (destAddr ?? '').trim().isEmpty
                  ? null
                  : (destAddr ?? '').trim(),
              borderAccent: const Color(0xFFFFA726).withOpacity(0.5),
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFFFFA726),
            ),
            if (widget.ride.isB2b == true) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DriverRideOfferCard._borderGold.withOpacity(0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 16,
                          color: DriverRideOfferCard._titleGold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (widget.ride.b2bTenantName ?? '').trim().isNotEmpty
                                ? widget.ride.b2bTenantName!.trim()
                                : loc.driverOfferB2bCompanyUnknown,
                            style: const TextStyle(
                              color: DriverRideOfferCard._titleGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.driverOfferB2bGuestLabel}: ${(widget.ride.b2bGuestName ?? '').trim().isEmpty ? '—' : widget.ride.b2bGuestName!.trim()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if ((widget.ride.b2bRoomNumber ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${loc.driverOfferB2bRoomLabel}: ${widget.ride.b2bRoomNumber!.trim()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (widget.ride.b2bFare != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        loc.driverOfferB2bAgreedFare(
                          widget.ride.b2bFare!.toStringAsFixed(3),
                        ),
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
            if (widget.ride.isB2b != true &&
                ((widget.ride.passengerName ?? '').trim().isNotEmpty ||
                    (widget.ride.passengerPhone ?? '').trim().isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.driverOfferPassengerSectionTitle,
                          style: const TextStyle(
                            color: DriverRideOfferCard._titleGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.driverOfferPassengerNameLabel}: ${(widget.ride.passengerName ?? '').trim().isEmpty ? '—' : widget.ride.passengerName!.trim()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc.driverOfferPassengerPhoneLabel}: ${(widget.ride.passengerPhone ?? '').trim().isEmpty ? '—' : widget.ride.passengerPhone!.trim()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_quoteLoading)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DriverRideOfferCard._borderGold,
                  ),
                ),
              )
            else
              _OfferChips(
                fareText: fare != null
                    ? loc.driverOfferFareChip(_formatAmount(fare))
                    : null,
                distanceText: distanceKm != null
                    ? loc.driverOfferDistanceChip(
                        distanceKm.toStringAsFixed(1),
                      )
                    : null,
                timeText: distanceKm != null
                    ? loc.driverOfferTimeChip(
                        '${_etaMinutes(distanceKm)}',
                      )
                    : null,
              ),
              if (_quote != null && _quote!['is_night'] == true) ...[
                const SizedBox(height: 8),
                Text(
                  loc.nightFare50,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DriverRideOfferCard._titleGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.ownerWalletShareHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      onPressed: widget.busy ? null : widget.onReject,
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
                          color: Colors.white.withOpacity(0.15),
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
                      onPressed: widget.busy ? null : widget.onAccept,
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
                          color: Colors.white.withOpacity(0.2),
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

class _DarkCompactAddress extends StatelessWidget {
  const _DarkCompactAddress({
    required this.label,
    required this.title,
    this.subtitle,
    required this.borderAccent,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String title;
  final String? subtitle;
  final Color borderAccent;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DriverRideOfferCard._titleGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
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
              background: const Color(0xFF2C3038),
              foreground: const Color(0xFFFFD666),
              text: fareText!,
              icon: const Text('💰', style: TextStyle(fontSize: 13)),
            ),
          ),
        if (fareText != null && (distanceText != null || timeText != null))
          const SizedBox(width: 8),
        if (distanceText != null)
          Expanded(
            child: _Pill(
              background: const Color(0xFF1E3A5C),
              foreground: const Color(0xFF7EC8FF),
              text: distanceText!,
              icon: const Icon(
                Icons.straighten_rounded,
                size: 15,
                color: Color(0xFF7EC8FF),
              ),
            ),
          ),
        if (distanceText != null && timeText != null)
          const SizedBox(width: 8),
        if (timeText != null)
          Expanded(
            child: _Pill(
              background: const Color(0xFF1A3D2E),
              foreground: const Color(0xFF6EE7A0),
              text: timeText!,
              icon: const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Color(0xFF6EE7A0),
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
