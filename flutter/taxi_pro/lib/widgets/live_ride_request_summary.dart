import 'package:flutter/material.dart';

String _s(dynamic v) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? '—' : t;
}

/// Owner/operator Live list: party (B2B **or** passenger), driver name, km, price, time only.
class LiveRideRequestSummary extends StatelessWidget {
  const LiveRideRequestSummary({
    super.key,
    required this.ride,
    required this.distanceLabel,
    required this.priceLabel,
    required this.timeLabel,
    required this.labelColor,
    required this.valueColor,
    required this.borderColor,
    required this.sectionBg,
    required this.passengerSectionTitle,
    required this.b2bSectionTitle,
    required this.driverLabel,
  });

  final Map<String, dynamic> ride;
  final String distanceLabel;
  final String priceLabel;
  final String timeLabel;
  final Color labelColor;
  final Color valueColor;
  final Color borderColor;
  final Color sectionBg;

  final String passengerSectionTitle;
  final String b2bSectionTitle;
  final String driverLabel;

  @override
  Widget build(BuildContext context) {
    final isB2b = ride['is_b2b'] == true;
    final driverNm = _s(ride['driver_name']);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isB2b) ...[
            _hdr(b2bSectionTitle),
            _row('Guest', _s(ride['b2b_guest_name'])),
            _row('Hotel / tenant', _s(ride['b2b_tenant_name'])),
            _row('Room / notes', _s(ride['b2b_room_number'])),
            _row('Source', _s(ride['b2b_source_code'])),
            _row('Contact', _s(ride['passenger_phone'])),
          ] else ...[
            _hdr(passengerSectionTitle),
            _row('Name', _s(ride['passenger_name'])),
            _row('Phone', _s(ride['passenger_phone'])),
            _row('Email', _s(ride['passenger_email'])),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: borderColor.withValues(alpha: 0.65)),
          ),
          _hdr(driverLabel),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              driverNm,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metricChip('km', distanceLabel),
                _metricChip('Price', priceLabel),
                _metricChip('Duration', timeLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: TextStyle(
            color: labelColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
      );

  Widget _row(String k, String v) {
    if (v == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: '$k: ',
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            k,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            v,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
