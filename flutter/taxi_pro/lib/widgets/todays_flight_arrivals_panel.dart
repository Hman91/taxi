import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Visual tokens for [TodaysFlightArrivalsCardList] (driver / operator / owner).
@immutable
class FlightArrivalsVisualTokens {
  const FlightArrivalsVisualTokens({
    required this.accent,
    required this.accentSoft,
    required this.cardTop,
    required this.cardBottom,
    required this.cardBorder,
    required this.cardGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconCircle,
    required this.iconForeground,
    required this.badgeNeutralBg,
    required this.badgeNeutralFg,
    required this.badgeSuccessBg,
    required this.badgeSuccessFg,
    required this.badgeInfoBg,
    required this.badgeInfoFg,
    required this.badgeWarningBg,
    required this.badgeWarningFg,
    required this.badgeDangerBg,
    required this.badgeDangerFg,
  });

  final Color accent;
  final Color accentSoft;
  final Color cardTop;
  final Color cardBottom;
  final Color cardBorder;
  final Color cardGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconCircle;
  final Color iconForeground;
  final Color badgeNeutralBg;
  final Color badgeNeutralFg;
  final Color badgeSuccessBg;
  final Color badgeSuccessFg;
  final Color badgeInfoBg;
  final Color badgeInfoFg;
  final Color badgeWarningBg;
  final Color badgeWarningFg;
  final Color badgeDangerBg;
  final Color badgeDangerFg;

  /// Driver + operator management palette.
  static FlightArrivalsVisualTokens management() {
    return const FlightArrivalsVisualTokens(
      accent: Color(0xFFFFC200),
      accentSoft: Color(0xFFFFF8E0),
      cardTop: Color(0xF2FFFFFF),
      cardBottom: Color(0xE6F8F5EC),
      cardBorder: Color(0x55FFC200),
      cardGlow: Color(0x18FFC200),
      textPrimary: Color(0xFF111111),
      textSecondary: Color(0xFF5C5C5C),
      iconCircle: Color(0xFFFFF3CC),
      iconForeground: Color(0xFF1A1A1A),
      badgeNeutralBg: Color(0xFFE8E8E8),
      badgeNeutralFg: Color(0xFF2C2C2C),
      badgeSuccessBg: Color(0xFFD4EDDA),
      badgeSuccessFg: Color(0xFF14532D),
      badgeInfoBg: Color(0xFFDEEBFF),
      badgeInfoFg: Color(0xFF1E3A8A),
      badgeWarningBg: Color(0xFFFFF3CD),
      badgeWarningFg: Color(0xFF856404),
      badgeDangerBg: Color(0xFFFFE4E4),
      badgeDangerFg: Color(0xFFB91C1C),
    );
  }

  /// Owner HQ palette (matches [OwnerColors]).
  static FlightArrivalsVisualTokens owner() {
    return const FlightArrivalsVisualTokens(
      accent: Color(0xFFFFC200),
      accentSoft: Color(0xFFFFF8E0),
      cardTop: Color(0xF2FFFFFF),
      cardBottom: Color(0xE6F8F5EC),
      cardBorder: Color(0x55FFC200),
      cardGlow: Color(0x18FFC200),
      textPrimary: Color(0xFF111111),
      textSecondary: Color(0xFF5C5C5C),
      iconCircle: Color(0xFFFFF3CC),
      iconForeground: Color(0xFF1A1A1A),
      badgeNeutralBg: Color(0xFFE8E8E8),
      badgeNeutralFg: Color(0xFF2C2C2C),
      badgeSuccessBg: Color(0xFFD4EDDA),
      badgeSuccessFg: Color(0xFF14532D),
      badgeInfoBg: Color(0xFFDEEBFF),
      badgeInfoFg: Color(0xFF1E3A8A),
      badgeWarningBg: Color(0xFFFFF3CD),
      badgeWarningFg: Color(0xFF856404),
      badgeDangerBg: Color(0xFFFFE4E4),
      badgeDangerFg: Color(0xFFB91C1C),
    );
  }
}

String flightArrivalsPrettyTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final normalized = s.replaceFirst(' - ', 'T').replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized) ?? DateTime.tryParse(s);
  if (dt == null) return s;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final mon = months[local.month - 1];
  final year = local.year.toString();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$day $mon $year · $hh:$mm';
}

String flightArrivalsDepartureOriginLabel(Map<String, dynamic> row) {
  final city = (row['departure_city'] ?? '').toString().trim();
  final country = (row['departure_country'] ?? '').toString().trim();
  final iata = (row['departure_iata'] ?? '').toString().trim().toUpperCase();
  if (city.isNotEmpty && country.isNotEmpty && iata.isNotEmpty) {
    return '$city, $country ($iata)';
  }
  return (row['departure_airport'] ?? '').toString();
}

String flightArrivalsTunisiaAirportLabel(
  Map<String, dynamic> row,
  String languageCode,
) {
  if (languageCode.toLowerCase() == 'ar') {
    return row['arrival_airport_ar']?.toString() ??
        row['arrival_airport_en']?.toString() ??
        '';
  }
  return row['arrival_airport_en']?.toString() ??
      row['arrival_airport_ar']?.toString() ??
      '';
}

String flightArrivalsTerminalGateLine(Map<String, dynamic> row) {
  final t = (row['arrival_terminal'] ?? '').toString().trim();
  final g = (row['arrival_gate'] ?? '').toString().trim();
  if (t.isEmpty && g.isEmpty) return '';
  if (t.isNotEmpty && g.isNotEmpty) return '$t · $g';
  return t.isNotEmpty ? t : g;
}

Color _statusBadgeColors(String status, FlightArrivalsVisualTokens t) {
  switch (status.trim().toLowerCase()) {
    case 'landed':
    case 'completed':
    case 'arrived':
      return t.badgeSuccessBg;
    case 'cancelled':
    case 'canceled':
      return t.badgeDangerBg;
    case 'active':
    case 'en-route':
    case 'en route':
      return t.badgeInfoBg;
    case 'incident':
    case 'diverted':
    case 'redirected':
    case 'unknown':
      return t.badgeWarningBg;
    default:
      return t.badgeNeutralBg;
  }
}

Color _statusBadgeFg(String status, FlightArrivalsVisualTokens t) {
  switch (status.trim().toLowerCase()) {
    case 'landed':
    case 'completed':
    case 'arrived':
      return t.badgeSuccessFg;
    case 'cancelled':
    case 'canceled':
      return t.badgeDangerFg;
    case 'active':
    case 'en-route':
    case 'en route':
      return t.badgeInfoFg;
    case 'incident':
    case 'diverted':
    case 'redirected':
    case 'unknown':
      return t.badgeWarningFg;
    default:
      return t.badgeNeutralFg;
  }
}

class TodaysFlightArrivalsCardList extends StatelessWidget {
  const TodaysFlightArrivalsCardList({
    super.key,
    required this.rows,
    required this.theme,
  });

  final List<Map<String, dynamic>> rows;
  final FlightArrivalsVisualTokens theme;

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _FlightArrivalCard(
            row: rows[i],
            lang: loc,
            theme: theme,
            l: l,
          ),
        ],
      ],
    );
  }
}

class _FlightArrivalCard extends StatelessWidget {
  const _FlightArrivalCard({
    required this.row,
    required this.lang,
    required this.theme,
    required this.l,
  });

  final Map<String, dynamic> row;
  final String lang;
  final FlightArrivalsVisualTokens theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final status = (row['status'] ?? '').toString();
    final flight = (row['flight_number'] ?? '').toString();
    final airline = (row['airline'] ?? '').toString();
    final origin = flightArrivalsDepartureOriginLabel(row);
    final arrivalAirport = flightArrivalsTunisiaAirportLabel(row, lang);
    final rawEta = row['expected_arrival']?.toString() ?? '';
    final eta = flightArrivalsPrettyTime(rawEta);
    final etaOut = eta.trim().isEmpty ? '—' : eta;
    final tg = flightArrivalsTerminalGateLine(row);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardTop, theme.cardBottom],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: theme.cardGlow,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accentSoft],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flight_rounded,
                    color: theme.iconForeground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight.isEmpty ? '—' : flight,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.1,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (airline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          airline,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: status.isEmpty ? '—' : status,
                  bg: _statusBadgeColors(status, theme),
                  fg: _statusBadgeFg(status, theme),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              theme: theme,
              icon: Icons.schedule_rounded,
              label: l.operatorColExpectedArrival,
              value: etaOut,
              emphasizeValue: true,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              icon: Icons.flight_takeoff_rounded,
              label: l.operatorColDepartureAirport,
              value: origin.isEmpty ? '—' : origin,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              icon: Icons.flight_land_rounded,
              label: l.operatorColArrivalAirportTn,
              value: arrivalAirport.isEmpty ? '—' : arrivalAirport,
            ),
            if (tg.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                theme: theme,
                icon: Icons.door_front_door_outlined,
                label: l.flightArrivalsTerminalGate,
                value: tg,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final FlightArrivalsVisualTokens theme;
  final IconData icon;
  final String label;
  final String value;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.iconCircle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: theme.iconForeground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: emphasizeValue ? 15 : 13.5,
                  fontWeight: emphasizeValue ? FontWeight.w800 : FontWeight.w600,
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
