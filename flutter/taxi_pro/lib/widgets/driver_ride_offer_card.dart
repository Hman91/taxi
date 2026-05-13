import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../services/taxi_app_service.dart';

/// Premium ride-offer card (pickup / destination, fare chips, accept / reject).
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

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _pageBg = Color(0xFFF8F5EC);
  static const Color _borderGold = Color(0xFFE6A800);
  static const Color _titleGold = Color(0xFF1A1A1A);
  static const Color _textSoft = Color(0xFF5C5C5C);
  static const Color _surfaceAlt = Color(0xFFF5F1E8);
  static const Color _yellowSoft = Color(0xFFFFF8E0);
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
    try {
      final q = await widget.api.quoteAirport(key);
      if (!mounted) return;
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

  String _scheduledLabel(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Scheduled pickup';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pickupLabel = localizedPlaceName(loc, widget.ride.pickup);
    final destLabel = localizedPlaceName(loc, widget.ride.destination);

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
              color: DriverRideOfferCard._titleGold.withOpacity(0.10),
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
                      color: DriverRideOfferCard._borderGold.withOpacity(0.36),
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
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LocationBlock(
                    label: loc.driverOfferFromLabel,
                    place: pickupLabel,
                    leading: const Icon(
                      Icons.location_on_rounded,
                      color: DriverRideOfferCard._accentRed,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LocationBlock(
                    label: loc.driverOfferToLabel,
                    place: destLabel,
                    leading: const Text(
                      '🏁',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.ride.isB2b == true) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DriverRideOfferCard._surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DriverRideOfferCard._borderGold.withOpacity(0.18)),
                ),
                child: Text(
                  'B2B: ${widget.ride.b2bGuestName ?? '-'}'
                  ' • Room ${widget.ride.b2bRoomNumber ?? '-'}'
                  ' • ${widget.ride.b2bSourceCode ?? '-'}',
                  style: const TextStyle(
                    color: DriverRideOfferCard._textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if ((widget.ride.scheduledPickupAt ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DriverRideOfferCard._yellowSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DriverRideOfferCard._borderGold.withOpacity(0.55)),
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
            if ((widget.ride.passengerName ?? '').trim().isNotEmpty ||
                (widget.ride.passengerPhone ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Passenger: ${(widget.ride.passengerName ?? '').trim().isEmpty ? '-' : widget.ride.passengerName}'
                ' • ${(widget.ride.passengerPhone ?? '').trim().isEmpty ? '-' : widget.ride.passengerPhone}',
                style: const TextStyle(
                  color: DriverRideOfferCard._textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.label,
    required this.place,
    required this.leading,
  });

  final String label;
  final String place;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DriverRideOfferCard._textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: leading,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                place,
                style: const TextStyle(
                  color: DriverRideOfferCard._titleGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ],
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
              icon: const Text('💰', style: TextStyle(fontSize: 13)),
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
