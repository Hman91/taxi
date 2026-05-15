import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/ride_address_display.dart';

/// Shared pickup / destination layout for booking preview, ride details, etc.
class LocationEndpointBlock extends StatelessWidget {
  const LocationEndpointBlock({
    super.key,
    required this.sectionLabel,
    required this.title,
    this.address,
    this.titleStyle,
    this.addressStyle,
  });

  final String sectionLabel;
  final String title;
  final String? address;
  final TextStyle? titleStyle;
  final TextStyle? addressStyle;

  @override
  Widget build(BuildContext context) {
    final baseTitle = titleStyle ??
        const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          height: 1.25,
          color: Color(0xFF1A1A1A),
        );
    final addrStyle = addressStyle ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          height: 1.35,
          color: Color(0xFF3F3F3F),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: Color(0xFF5C5C5C),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: baseTitle),
        if ((address ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(address!.trim(), style: addrStyle),
        ],
      ],
    );
  }
}

/// Full ride pickup + destination from a [Ride] (server snapshot).
class RideAddressSummaryCard extends StatelessWidget {
  const RideAddressSummaryCard({
    super.key,
    required this.ride,
    required this.l,
    this.compact = false,
    this.coordsStyle,
  });

  final Ride ride;
  final AppLocalizations l;
  final bool compact;
  final TextStyle? coordsStyle;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 14.0 : 18.0;
    final coords = rideEndpointCoordsLine(ride);
    final cs = coordsStyle ??
        const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: Color(0xFF5C5C5C),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationEndpointBlock(
          sectionLabel: l.ridePickupLabel,
          title: ridePickupTitle(ride, l),
          address: ridePickupAddressLine(ride, l),
        ),
        SizedBox(height: gap),
        LocationEndpointBlock(
          sectionLabel: l.rideDestinationLabel,
          title: rideDestinationTitle(ride, l),
          address: rideDestinationAddressLine(ride, l),
        ),
        if (coords != null) ...[
          SizedBox(height: compact ? 10 : 12),
          SelectableText(coords, style: cs),
        ],
      ],
    );
  }
}
