import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../api/models.dart';
import '../app_locale.dart'
    show
        AppUiRole,
        applyPreferredLanguageToApp,
        appLocale,
        rememberCurrentLocaleForRole,
        restoreUiRoleLocale,
        userChoseLocaleThisSession;
import '../l10n/app_localizations.dart';
import '../l10n/place_localization.dart';
import '../l10n/ride_status_localization.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../config.dart';
import '../services/local_notification_service.dart';
import '../services/session_store.dart';
import '../services/taxi_app_service.dart';
import '../theme/taxi_app_theme.dart';
import '../widgets/locale_popup_menu.dart';
import '../widgets/management_platform_ui.dart';
import '../utils/chat_unread_poll.dart'
    show
        cachedOrFetchConversationId,
        computeUnreadChatDelta,
        maxChatMessageId,
        rideMayHaveConversation;
import '../utils/int_from_json.dart';
import '../widgets/driver_ride_offer_card.dart';
import '../widgets/voom_logo.dart';
import 'ride_chat_screen.dart';
import 'unified_login_screen.dart';

// ── Design tokens (mirrors owner_screen._C) ──────────────────
class _C {
  static const yellow = Color(0xFFFFC200);
  static const yellowLight = Color(0xFFFFD84D);
  static const yellowSoft = Color(0xFFFFF8E0);
  static const yellowDeep = Color(0xFFE6A800);
  static const charcoal = Color(0xFF1A1A1A);
  static const charcoalMid = Color(0xFF2C2C2C);
  static const bgWarm = Color(0xFFF8F5EC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F1E8);
  static const border = Color(0xFFDDD8C8);
  static const textStrong = Color(0xFF111111);
  static const textMid = Color(0xFF3F3F3F);
  static const textSoft = Color(0xFF5C5C5C);
  static const danger = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE4E4);
  static const success = Color(0xFF1A7A4A);
  static const successBg = Color(0xFFD4EDDA);
  static const info = Color(0xFF1E3A8A);
  static const infoBg = Color(0xFFDEEBFF);
}

// ── Shared UI helpers (mirrors owner_screen) ─────────────────

InputDecoration _fd(String label, {IconData? icon, String? suffix}) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMid, fontSize: 13),
      prefixIcon:
          icon != null ? Icon(icon, color: _C.charcoal, size: 18) : null,
      suffixText: suffix,
      filled: true,
      fillColor: _C.surfaceAlt,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.yellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class _YellowButton extends StatelessWidget {
  const _YellowButton(
      {required this.label,
      required this.onPressed,
      this.icon,
      this.small = false,
      this.fullWidth = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 38 : 48,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? _C.yellowSoft : _C.yellow,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                      color: _C.yellow.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: _C.charcoal, size: small ? 14 : 18),
            const SizedBox(width: 6)
          ],
          Text(label,
              style: TextStyle(
                  color: _C.charcoal,
                  fontWeight: FontWeight.w900,
                  fontSize: small ? 12 : 14,
                  letterSpacing: 0.2)),
        ])),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton(
      {required this.label,
      required this.onPressed,
      this.icon,
      this.small = false,
      this.fullWidth = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 38 : 48,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFCCCCCC) : _C.charcoal,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                      color: _C.charcoal.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: small ? 14 : 18),
            const SizedBox(width: 6)
          ],
          Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: small ? 12 : 14,
                  letterSpacing: 0.2)),
        ])),
      ),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module(
      {required this.child, this.padding = 16.0, this.accent = false});
  final Widget child;
  final double padding;
  final bool accent;

  @override
  Widget build(BuildContext context) => ManagementModuleCard(
        padding: padding,
        accent: accent,
        child: child,
      );
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ManagementSectionHeader(
        title,
        subtitle: subtitle,
        trailing: trailing,
        icon: Icons.auto_awesome_rounded,
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      this.color = _C.charcoal});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ManagementMetricPill(
        label: label,
        value: value,
        icon: icon,
        color: color,
      );
}

Widget _rowInfoCard({
  required IconData icon,
  required Widget content,
  Widget? trailing,
  Color iconBg = _C.surfaceAlt,
  Color iconColor = _C.charcoal,
}) =>
    ManagementInfoRowCard(
      icon: icon,
      content: content,
      trailing: trailing,
      iconBg: iconBg,
      iconColor: iconColor,
    );

Color _driverRideStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'ongoing':
      return _C.info;
    case 'completed':
      return _C.success;
    case 'cancelled':
    case 'canceled':
      return _C.danger;
    case 'accepted':
    default:
      return _C.yellowDeep;
  }
}

IconData _driverRideStatusIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'ongoing':
      return Icons.route_rounded;
    case 'completed':
      return Icons.check_circle_rounded;
    case 'cancelled':
    case 'canceled':
      return Icons.block_rounded;
    case 'accepted':
    default:
      return Icons.verified_rounded;
  }
}

String _driverInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String firstChar(String value) => value.isEmpty ? '?' : value[0];
  if (parts.length == 1) return firstChar(parts.first).toUpperCase();
  return '${firstChar(parts.first)}${firstChar(parts.last)}'.toUpperCase();
}

String _driverTwoDigits(int value) => value.toString().padLeft(2, '0');

String _driverPrettyDate(String raw) {
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw.trim().isEmpty ? '-' : raw;
  return '${_driverTwoDigits(dt.day)}/${_driverTwoDigits(dt.month)}/${dt.year}';
}

String _driverPrettyTime(String raw) {
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw.trim().isEmpty ? '-' : raw;
  return '${_driverTwoDigits(dt.hour)}:${_driverTwoDigits(dt.minute)}';
}

ImageProvider<Object>? _driverImageProviderFromString(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('data:image/')) {
    final commaIdx = raw.indexOf(',');
    if (commaIdx <= 0 || commaIdx + 1 >= raw.length) return null;
    try {
      return MemoryImage(base64Decode(raw.substring(commaIdx + 1)));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(raw);
}

class _DriverTripHistoryCard extends StatelessWidget {
  const _DriverTripHistoryCard({
    required this.ride,
    required this.statusLabel,
    required this.route,
    required this.passengerLine,
    required this.metaLine,
    required this.actions,
  });

  final Ride ride;
  final String statusLabel;
  final String route;
  final String passengerLine;
  final String metaLine;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final color = _driverRideStatusColor(ride.status);
    final bg = ride.status == 'completed'
        ? _C.successBg
        : (ride.status == 'cancelled' || ride.status == 'canceled')
            ? _C.dangerBg
            : ride.status == 'ongoing'
                ? _C.infoBg
                : _C.yellowSoft;
    final fare = ride.b2bFare;
    return RepaintBoundary(
      child: _Module(
        padding: 10,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _rowInfoCard(
            icon: _driverRideStatusIcon(ride.status),
            iconBg: bg,
            iconColor: color,
            trailing: ManagementStatusPill(
              label: statusLabel,
              color: color,
              background: bg,
            ),
            content:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.textStrong,
                  fontSize: 12.5,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                passengerLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.textSoft,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(spacing: 5, runSpacing: 4, children: [
                ManagementStatusPill(
                  label: metaLine,
                  color: _C.textSoft,
                  background: _C.surfaceAlt,
                ),
                if (ride.isB2b == true)
                  ManagementStatusPill(
                    label: 'B2B',
                    color: _C.info,
                    background: _C.infoBg,
                  ),
                if (fare != null)
                  ManagementStatusPill(
                    label: '${fare.toStringAsFixed(2)} DT',
                    color: _C.success,
                    background: _C.successBg,
                  ),
              ]),
            ]),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(spacing: 6, runSpacing: 5, children: actions),
            ),
        ]),
      ),
    );
  }
}

class _DriverRideDetailsCard extends StatefulWidget {
  const _DriverRideDetailsCard({
    required this.ride,
    required this.api,
    required this.busy,
    required this.onStart,
    required this.onRelease,
    required this.onComplete,
    required this.chatButton,
  });

  final Ride ride;
  final TaxiAppService api;
  final bool busy;
  final VoidCallback? onStart;
  final VoidCallback? onRelease;
  final VoidCallback? onComplete;
  final Widget? chatButton;

  @override
  State<_DriverRideDetailsCard> createState() => _DriverRideDetailsCardState();
}

class _DriverRideDetailsCardState extends State<_DriverRideDetailsCard> {
  Map<String, dynamic>? _quote;
  bool _quoteLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void didUpdateWidget(covariant _DriverRideDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ride.id != widget.ride.id ||
        oldWidget.ride.pickup != widget.ride.pickup ||
        oldWidget.ride.destination != widget.ride.destination) {
      _quote = null;
      _quoteLoading = true;
      _loadQuote();
    }
  }

  Future<void> _loadQuote() async {
    final key =
        '${widget.ride.pickup.trim()} $airportRouteKeySeparator ${widget.ride.destination.trim()}';
    try {
      final quote = await widget.api.quoteAirport(key);
      if (!mounted) return;
      setState(() {
        _quote = quote;
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

  String _amountText(double value) => '${value.toStringAsFixed(2)} DT';

  double? get _fare {
    if (widget.ride.b2bFare != null) return widget.ride.b2bFare;
    return (_quote?['final_fare'] as num?)?.toDouble() ??
        (_quote?['base_fare'] as num?)?.toDouble();
  }

  double? get _distanceKm => (_quote?['distance_km'] as num?)?.toDouble();

  String get _durationText {
    final distance = _distanceKm;
    if (distance == null) return _quoteLoading ? '...' : '-';
    return '${(distance * 2.52).round().clamp(1, 999)} min';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ride = widget.ride;
    final statusColor = _driverRideStatusColor(ride.status);
    final passengerName = ride.isB2b == true
        ? ((ride.b2bGuestName ?? '').trim().isEmpty
            ? ((ride.passengerName ?? '').trim().isEmpty
                ? l.roleB2b
                : ride.passengerName!.trim())
            : ride.b2bGuestName!.trim())
        : ((ride.passengerName ?? '').trim().isEmpty
            ? l.rolePassenger
            : ride.passengerName!.trim());
    final passengerPhone = (ride.passengerPhone ?? '').trim();
    final route = localizedRideRouteRow(l, ride.pickup, ride.destination);
    final dateSource = (ride.scheduledPickupAt ?? ride.createdAt ?? '').trim();
    final passengerPhoto =
        _driverImageProviderFromString(ride.passengerPhotoUrl);
    final fareText =
        _fare == null ? (_quoteLoading ? '...' : '-') : _amountText(_fare!);
    final distanceText = _distanceKm == null
        ? (_quoteLoading ? '...' : '-')
        : '${_distanceKm!.toStringAsFixed(1)} km';

    return RepaintBoundary(
      child: ManagementModuleCard(
        accent: ride.status == 'accepted' || ride.status == 'ongoing',
        padding: 14,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD84D), Color(0xFFFFF8E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: _C.yellowDeep.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(
                    color: _C.yellow.withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: passengerPhoto == null
                    ? null
                    : DecorationImage(image: passengerPhoto, fit: BoxFit.cover),
              ),
              child: Center(
                child: passengerPhoto == null
                    ? Text(
                        _driverInitials(passengerName),
                        style: const TextStyle(
                          color: _C.charcoal,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passengerPhone.isEmpty
                          ? (ride.isB2b == true
                              ? '${l.roleB2b} • Room ${ride.b2bRoomNumber ?? '-'}'
                              : l.rolePassenger)
                          : passengerPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      ManagementStatusPill(
                        label: localizedRideStatusLabel(l, ride.status),
                        color: statusColor,
                        background: statusColor.withOpacity(0.10),
                      ),
                      if (ride.isB2b == true)
                        ManagementStatusPill(
                          label: 'B2B',
                          color: _C.info,
                          background: _C.infoBg,
                        ),
                      ManagementStatusPill(
                        label: fareText,
                        color: _C.success,
                        background: _C.successBg,
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.20)),
              ),
              child: Icon(_driverRideStatusIcon(ride.status),
                  color: statusColor, size: 21),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.surfaceAlt.withOpacity(0.72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _C.border.withOpacity(0.85)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                route,
                style: const TextStyle(
                  color: _C.textStrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              _DriverRouteLine(
                pickup: localizedPlaceName(l, ride.pickup),
                destination: localizedPlaceName(l, ride.destination),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          ManagementResponsiveWrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DriverRideMetric(
                icon: Icons.event_available_rounded,
                label: 'Ride date',
                value: _driverPrettyDate(dateSource),
              ),
              _DriverRideMetric(
                icon: Icons.schedule_rounded,
                label: 'Ride time',
                value: _driverPrettyTime(dateSource),
              ),
              _DriverRideMetric(
                icon: Icons.payments_outlined,
                label: 'Ride price',
                value: fareText,
              ),
              _DriverRideMetric(
                icon: Icons.route_rounded,
                label: 'Kilometrage',
                value: distanceText,
              ),
              _DriverRideMetric(
                icon: Icons.timer_outlined,
                label: 'Estimated duration',
                value: _durationText,
              ),
              _DriverRideMetric(
                icon: Icons.person_pin_circle_outlined,
                label: 'Passenger info',
                value: passengerPhone.isEmpty ? passengerName : passengerPhone,
              ),
            ],
          ),
          if (ride.isB2b == true) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ManagementStatusPill(
                label: 'Room ${ride.b2bRoomNumber ?? '-'}',
                color: _C.textMid,
                background: _C.surfaceAlt,
              ),
              if ((ride.b2bSourceCode ?? '').trim().isNotEmpty)
                ManagementStatusPill(
                  label: ride.b2bSourceCode!.trim(),
                  color: _C.info,
                  background: _C.infoBg,
                ),
            ]),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ride.status == 'accepted')
                _DarkButton(
                  label: l.startRide,
                  icon: Icons.play_arrow_rounded,
                  onPressed: widget.busy ? null : widget.onStart,
                  small: true,
                  fullWidth: false,
                ),
              if (ride.status == 'accepted' || ride.status == 'ongoing')
                GestureDetector(
                  onTap: widget.busy ? null : widget.onRelease,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _C.dangerBg,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _C.danger.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        l.cancelRidePassenger,
                        style: const TextStyle(
                          color: _C.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (ride.status == 'ongoing')
                _YellowButton(
                  label: l.completeRide,
                  icon: Icons.check_rounded,
                  onPressed: widget.busy ? null : widget.onComplete,
                  small: true,
                  fullWidth: false,
                ),
              if (widget.chatButton != null) widget.chatButton!,
            ],
          ),
        ]),
      ),
    );
  }
}

class _DriverRouteLine extends StatelessWidget {
  const _DriverRouteLine({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _DriverRoutePoint(
        icon: Icons.my_location_rounded,
        label: 'Pickup location',
        value: pickup,
        color: _C.danger,
      ),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 18),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 2,
            height: 20,
            color: _C.border,
          ),
        ),
      ),
      _DriverRoutePoint(
        icon: Icons.flag_rounded,
        label: 'Destination',
        value: destination,
        color: _C.success,
      ),
    ]);
  }
}

class _DriverRoutePoint extends StatelessWidget {
  const _DriverRoutePoint({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            style: const TextStyle(
              color: _C.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _C.textStrong,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _DriverRideMetric extends StatelessWidget {
  const _DriverRideMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border.withOpacity(0.76)),
        boxShadow: [
          BoxShadow(
            color: _C.charcoal.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: _C.textSoft, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _C.textSoft,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _C.textStrong,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DRIVER SCREEN
// ─────────────────────────────────────────────────────────────
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key, this.initialSession, this.appInitialSession});
  final DriverPinLoginResponse? initialSession;
  final AppLoginResponse? appInitialSession;

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen>
    with SingleTickerProviderStateMixin {
  final _api = TaxiAppService();
  final _socket = ChatSocketService();
  final _imagePicker = ImagePicker();
  final _phoneController = TextEditingController(text: '98123456');
  final _pinController = TextEditingController(text: '1234');
  List<String> _locations = [];
  String _location = '';
  String? _locationText;
  String? _locationError;
  bool _locating = false;
  double? _nearestZoneDistanceKm;
  String? _token;
  int? _userId;
  int? _driverId;
  String? _driverName;
  String? _driverEmail;
  String? _driverPhone;
  double _walletBalance = 0.0;
  Map<String, dynamic>? _gains;
  bool _isAvailable = true;
  String _historyFilter = 'all';
  String? _carModel;
  String? _carColor;
  String? _photoUrl;
  String? _profileImageRaw;
  ImageProvider<Object>? _profileImageProvider;
  String? _message;
  List<Ride> _rides = [];
  List<Map<String, dynamic>> _flightArrivals = [];
  String? _flightDataSource;
  final List<AppNotification> _notifications = [];
  final Set<int> _seenPendingRideIds = <int>{};
  final Set<int> _notifiedClosedRideIds = <int>{};
  Set<int> _lastPendingRideIds = <int>{};
  final Set<int> _selfAcceptedRideIds = <int>{};
  final Set<int> _dismissedPendingRideIds = <int>{};
  final Map<int, int> _unreadChatByRideId = <int, int>{};
  final Map<int, int> _rideIdByConversationId = <int, int>{};
  final Map<int, int> _conversationIdByRideId = <int, int>{};
  final Map<int, int> _lastSeenMessageIdByConversationId = <int, int>{};
  int? _activeChatRideId;
  bool _busy = false;
  double? _lastWalletSample;
  DateTime? _lastWalletDepletedNotifAt;

  /// Dedupes alerts when gains first load while wallet is already 0 (no prev > 0 → 0 transition).
  bool _walletDepletedNotifiedForZero = false;
  bool _obscurePin = true;
  Timer? _ridesPollingTimer;
  TabController? _tabController;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  String _uiText({
    required String en,
    required String ar,
    required String fr,
    required String es,
    required String de,
    required String it,
    required String ru,
    required String zh,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('fr')) return fr;
    if (code.startsWith('es')) return es;
    if (code.startsWith('de')) return de;
    if (code.startsWith('it')) return it;
    if (code.startsWith('ru')) return ru;
    if (code.startsWith('zh')) return zh;
    return en;
  }

  String _resolvedDriverName({
    String? primary,
    String? email,
    String? fallback,
  }) {
    final p = (primary ?? '').trim();
    final f = (fallback ?? '').trim();
    final e = (email ?? '').trim().toLowerCase();
    final placeholder = RegExp(r'^driver_\d+$');
    if (p.isNotEmpty && !placeholder.hasMatch(p.toLowerCase())) return p;
    if (e.contains('@')) {
      final left = e.split('@').first.trim();
      if (left.isNotEmpty) return left;
    }
    if (f.isNotEmpty && !placeholder.hasMatch(f.toLowerCase())) return f;
    return p.isNotEmpty ? p : (f.isNotEmpty ? f : 'Driver');
  }

  ({String? model, String? color}) _vehicleInfoParts(String? raw) {
    final src = (raw ?? '').trim();
    if (src.isEmpty) return (model: null, color: null);
    String? model;
    String? color;

    final modelJson =
        RegExp(r"""["']car_model["']\s*:\s*["']([^"']+)["']""").firstMatch(src);
    final colorJson =
        RegExp(r"""["']car_color["']\s*:\s*["']([^"']+)["']""").firstMatch(src);
    final modelEq =
        RegExp(r'model\s*=\s*([^;,\n]+)', caseSensitive: false).firstMatch(src);
    final colorEq =
        RegExp(r'color\s*=\s*([^;,\n]+)', caseSensitive: false).firstMatch(src);

    model = (modelJson?.group(1) ?? modelEq?.group(1) ?? '').trim();
    color = (colorJson?.group(1) ?? colorEq?.group(1) ?? '').trim();
    if (model.isEmpty) model = null;
    if (color.isEmpty) color = null;
    return (model: model, color: color);
  }

  static const Map<String, _ZoneCoord> _zoneCoords = {
    'مطار قرطاج': _ZoneCoord(36.8508, 10.2272),
    'مطار النفيضة': _ZoneCoord(36.0758, 10.4386),
    'مطار المنستير': _ZoneCoord(35.7581, 10.7547),
    'وسط سوسة': _ZoneCoord(35.8256, 10.63699),
    'الحمامات': _ZoneCoord(36.4000, 10.6167),
    'نابل': _ZoneCoord(36.4561, 10.7376),
    'القنطاوي': _ZoneCoord(35.8920, 10.5950),
    'Sidi Bou Saïd': _ZoneCoord(36.8710, 10.3470),
    'La Marsa': _ZoneCoord(36.8780, 10.3240),
    'Gammarth': _ZoneCoord(36.9170, 10.2870),
    'Carthage': _ZoneCoord(36.8520, 10.3230),
    'Musée du Bardo': _ZoneCoord(36.8100, 10.1400),
    'Médina de Tunis': _ZoneCoord(36.8000, 10.1700),
    'Byrsa Hill': _ZoneCoord(36.8527, 10.3295),
    'Lac de Tunis': _ZoneCoord(36.8400, 10.2400),
    'Geant': _ZoneCoord(36.8420, 10.2860),
    'Azur city': _ZoneCoord(36.7410, 10.2150),
    'tunisia mall': _ZoneCoord(36.8430, 10.2810),
    'Nabeul': _ZoneCoord(36.4510, 10.7360),
    'Hammamet': _ZoneCoord(36.4000, 10.6160),
    'Yasmine Hammamet': _ZoneCoord(36.3650, 10.5360),
    'Friguia Park': _ZoneCoord(36.1240, 10.4410),
    'Hergla park': _ZoneCoord(36.0270, 10.5090),
    'mall of sousse': _ZoneCoord(35.8290, 10.6350),
    'Skanes': _ZoneCoord(35.7650, 10.8100),
    'Marina de Monastir': _ZoneCoord(35.7770, 10.8260),
    'mahdia': _ZoneCoord(35.5050, 11.0630),
    'Skifa el Kahla': _ZoneCoord(35.5057, 11.0620),
    'Borj el Kebir': _ZoneCoord(35.5030, 11.0610),
  };

  ({String? zone, double? distanceMeters}) _nearestZoneFor(
      double lat, double lng) {
    String? bestZone;
    double? bestDist;
    for (final zone in _locations) {
      final z = _zoneCoords[zone];
      if (z == null) continue;
      final d = Geolocator.distanceBetween(lat, lng, z.lat, z.lng);
      if (bestDist == null || d < bestDist) {
        bestDist = d;
        bestZone = zone;
      }
    }
    return (zone: bestZone, distanceMeters: bestDist);
  }

  Future<void> _detectDriverLocation({bool push = true}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = l10n.passengerLocationServiceDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = l10n.passengerLocationPermissionDenied);
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nearest = _nearestZoneFor(p.latitude, p.longitude);
      final zone = nearest.zone;
      if (!mounted) return;
      setState(() {
        _locationText =
            '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
        _nearestZoneDistanceKm = nearest.distanceMeters == null
            ? null
            : nearest.distanceMeters! / 1000.0;
        if (zone != null && zone.isNotEmpty) _location = zone;
      });
      if (push && zone != null && zone.isNotEmpty) await _pushDriverLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Color _distanceColor(double km) {
    if (km < 3.0) return _C.success;
    if (km <= 10.0) return _C.yellowDeep;
    return _C.danger;
  }

  Future<void> _goToHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Future<void> _goBack() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    await _goToHome();
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
    );
  }

  Widget _appBarHomeLogo() => GestureDetector(
        onTap: () => unawaited(_goToHome()),
        child: const VoomLogo(height: 30),
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      restoreUiRoleLocale(AppUiRole.driver);
      final s =
          widget.initialSession ?? _sessionFromApp(widget.appInitialSession);
      if (s != null && _token == null) _bootstrapFromSession(s);
    });
  }

  DriverPinLoginResponse? _sessionFromApp(AppLoginResponse? r) {
    if (r == null) return null;
    return DriverPinLoginResponse(
      accessToken: r.accessToken,
      role: r.role,
      userId: r.userId,
      driverName: 'driver_${r.userId}',
      phone: '',
      preferredLanguage: r.preferredLanguage,
      walletBalance: 0,
      ownerCommissionRate: 10,
      b2bCommissionRate: 5,
      autoDeductEnabled: true,
    );
  }

  Future<void> _bootstrapFromSession(DriverPinLoginResponse r) async {
    await SessionStore.saveDriverPin(r);
    final l = AppLocalizations.of(context)!;
    if (!userChoseLocaleThisSession.value)
      applyPreferredLanguageToApp(r.preferredLanguage);
    rememberCurrentLocaleForRole(AppUiRole.driver);
    setState(() {
      _token = r.accessToken;
      _userId = r.userId;
      _driverId = r.driverId;
      _driverName =
          _resolvedDriverName(primary: r.driverName, fallback: _driverName);
      _walletBalance = r.walletBalance;
      _isAvailable = true;
      _driverPhone = r.phone;
      _driverEmail = null;
      _carModel = r.carModel;
      _carColor = r.carColor;
      _photoUrl = r.photoUrl;
      _unreadChatByRideId.clear();
      _rideIdByConversationId.clear();
      _conversationIdByRideId.clear();
      _lastSeenMessageIdByConversationId.clear();
      _activeChatRideId = null;
      _message = l.loggedInAs(r.role);
    });
    final fares = await _api.getAirportFares();
    final locations = _startsFromRouteKeys(fares.keys, l);
    setState(() {
      _locations = locations;
      if (_location.isEmpty || !_locations.contains(_location)) {
        _location = _locations.isNotEmpty ? _locations.first : '';
      }
    });
    await _detectDriverLocation(push: false);
    await _refreshRides();
    await _refreshArrivals(silent: true);
    await _hydrateDriverProfile();
    _socket.connect(r.accessToken,
        onReceiveMessage: _onChatMessage,
        onRideStatus: _onRideStatusEvent,
        onDriverWallet: _onDriverWallet);
    _startRidesPolling();
    await _pushDriverLocation();
  }

  Future<void> _hydrateDriverProfile() async {
    final t = _token;
    if (t == null) return;
    try {
      final payload = await _api.getDriverMe(t);
      final user = Map<String, dynamic>.from(
        (payload['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final pin = Map<String, dynamic>.from(
        (payload['pin_account'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final driver = Map<String, dynamic>.from(
        (payload['driver'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final v = _vehicleInfoParts(driver['vehicle_info']?.toString());
      if (!mounted) return;
      setState(() {
        _driverEmail = (user['email'] ?? _driverEmail)?.toString();
        final name = (user['display_name'] ?? pin['driver_name'] ?? _driverName)
            .toString()
            .trim();
        _driverName = _resolvedDriverName(
          primary: name,
          email: _driverEmail,
          fallback: _driverName,
        );
        _driverPhone =
            (user['phone'] ?? pin['phone'] ?? _driverPhone)?.toString();
        final pinModel = (pin['car_model'] ?? '').toString().trim();
        final pinColor = (pin['car_color'] ?? '').toString().trim();
        _carModel = pinModel.isNotEmpty ? pinModel : (v.model ?? _carModel);
        _carColor = pinColor.isNotEmpty ? pinColor : (v.color ?? _carColor);
        _photoUrl = (pin['photo_url'] ?? _photoUrl)?.toString();
      });
    } catch (_) {}
  }

  Future<void> _showEditDriverProfileDialog() async {
    final t = _token;
    if (t == null) return;
    final nameCtrl = TextEditingController(text: (_driverName ?? '').trim());
    final phoneCtrl = TextEditingController(
        text: (_driverPhone ?? _phoneController.text).trim());
    final emailCtrl = TextEditingController(text: (_driverEmail ?? '').trim());
    final modelCtrl = TextEditingController(text: (_carModel ?? '').trim());
    final colorCtrl = TextEditingController(text: (_carColor ?? '').trim());
    final passwordCtrl = TextEditingController();
    String photoData = (_photoUrl ?? '').trim();
    bool saving = false;
    String? localError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _C.surface,
          surfaceTintColor: _C.surface,
          title: Text(_uiText(
              en: 'Edit profile',
              ar: 'تعديل الملف الشخصي',
              fr: 'Modifier le profil',
              es: 'Editar perfil',
              de: 'Profil bearbeiten',
              it: 'Modifica profilo',
              ru: 'Редактировать профиль',
              zh: '编辑资料')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: _fd(
                    _uiText(
                        en: 'Name',
                        ar: 'الاسم',
                        fr: 'Nom',
                        es: 'Nombre',
                        de: 'Name',
                        it: 'Nome',
                        ru: 'Имя',
                        zh: '姓名'),
                    icon: Icons.person_outline_rounded,
                  ).copyWith(hintText: _driverName ?? ''),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fd(
                    _uiText(
                        en: 'Phone',
                        ar: 'الهاتف',
                        fr: 'Telephone',
                        es: 'Telefono',
                        de: 'Telefon',
                        it: 'Telefono',
                        ru: 'Телефон',
                        zh: '电话'),
                    icon: Icons.phone_outlined,
                  ).copyWith(hintText: _driverPhone ?? ''),
                ),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fd(
                    _uiText(
                        en: 'Email',
                        ar: 'البريد الإلكتروني',
                        fr: 'Email',
                        es: 'Correo',
                        de: 'E-Mail',
                        it: 'Email',
                        ru: 'Email',
                        zh: '邮箱'),
                    icon: Icons.alternate_email_rounded,
                  ).copyWith(hintText: _driverEmail ?? ''),
                ),
                TextField(
                  controller: modelCtrl,
                  decoration: _fd(
                    _uiText(
                        en: 'Car model',
                        ar: 'موديل السيارة',
                        fr: 'Modele voiture',
                        es: 'Modelo de coche',
                        de: 'Automodell',
                        it: 'Modello auto',
                        ru: 'Модель авто',
                        zh: '车型'),
                    icon: Icons.directions_car_outlined,
                  ).copyWith(hintText: _carModel ?? ''),
                ),
                TextField(
                  controller: colorCtrl,
                  decoration: _fd(
                    _uiText(
                        en: 'Car color',
                        ar: 'لون السيارة',
                        fr: 'Couleur voiture',
                        es: 'Color del coche',
                        de: 'Autofarbe',
                        it: 'Colore auto',
                        ru: 'Цвет авто',
                        zh: '车身颜色'),
                    icon: Icons.palette_outlined,
                  ).copyWith(hintText: _carColor ?? ''),
                ),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: _fd(
                    _uiText(
                        en: 'New password (optional)',
                        ar: 'كلمة مرور جديدة (اختياري)',
                        fr: 'Nouveau mot de passe (optionnel)',
                        es: 'Nueva contraseña (opcional)',
                        de: 'Neues Passwort (optional)',
                        it: 'Nuova password (opzionale)',
                        ru: 'Новый пароль (необязательно)',
                        zh: '新密码（可选）'),
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                  maxWidth: 1600,
                                );
                                if (picked == null) return;
                                final bytes = await picked.readAsBytes();
                                final n = picked.name.toLowerCase();
                                final ext = n.contains('.')
                                    ? n.split('.').last
                                    : 'jpeg';
                                final mime = ext == 'png'
                                    ? 'image/png'
                                    : ext == 'webp'
                                        ? 'image/webp'
                                        : 'image/jpeg';
                                setLocal(() => photoData =
                                    'data:$mime;base64,${base64Encode(bytes)}');
                              },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_uiText(
                            en: 'Pick photo',
                            ar: 'اختيار صورة',
                            fr: 'Choisir photo',
                            es: 'Elegir foto',
                            de: 'Foto wählen',
                            it: 'Scegli foto',
                            ru: 'Выбрать фото',
                            zh: '选择照片')),
                      ),
                    ),
                  ],
                ),
                if (localError != null) ...[
                  const SizedBox(height: 8),
                  Text(localError!,
                      style: const TextStyle(color: _C.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: Text(_uiText(
                    en: 'Cancel',
                    ar: 'إلغاء',
                    fr: 'Annuler',
                    es: 'Cancelar',
                    de: 'Abbrechen',
                    it: 'Annulla',
                    ru: 'Отмена',
                    zh: '取消'))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final model = modelCtrl.text.trim();
                      final color = colorCtrl.text.trim();
                      setLocal(() {
                        saving = true;
                        localError = null;
                      });
                      try {
                        String? onlyIfFilled(String v) {
                          final t = v.trim();
                          return t.isEmpty ? null : t;
                        }

                        await _api.patchDriverMe(
                          token: t,
                          displayName: onlyIfFilled(name),
                          phone: onlyIfFilled(phone),
                          email: onlyIfFilled(email),
                          password: onlyIfFilled(passwordCtrl.text),
                          // Car fields are optional and may be cleared.
                          carModel: model,
                          carColor: color,
                          photoUrl: onlyIfFilled(photoData),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setLocal(() {
                          localError = e.toString();
                          saving = false;
                        });
                      }
                    },
              child: Text(_uiText(
                  en: 'Save',
                  ar: 'حفظ',
                  fr: 'Enregistrer',
                  es: 'Guardar',
                  de: 'Speichern',
                  it: 'Salva',
                  ru: 'Сохранить',
                  zh: '保存')),
            ),
          ],
        ),
      ),
    );
    // Keep dialog controllers alive through route teardown to avoid
    // "TextEditingController was used after being disposed" during pop animation.
    if (ok == true) {
      await _hydrateDriverProfile();
      if (!mounted) return;
      setState(() => _message = _uiText(
          en: 'Profile updated successfully.',
          ar: 'تم تحديث الملف الشخصي بنجاح.',
          fr: 'Profil mis a jour avec succes.',
          es: 'Perfil actualizado correctamente.',
          de: 'Profil erfolgreich aktualisiert.',
          it: 'Profilo aggiornato con successo.',
          ru: 'Профиль успешно обновлен.',
          zh: '资料更新成功。'));
    }
  }

  void _pushNotification(
      {required String title,
      required String body,
      String? event,
      int? rideId}) {
    final now = DateTime.now();
    setState(() {
      _notifications.insert(
          0,
          AppNotification(
              id: '${now.microsecondsSinceEpoch}-${event ?? 'manual'}-${rideId ?? 0}',
              title: title,
              body: body,
              createdAt: now,
              event: event,
              rideId: rideId));
      if (_notifications.length > 60)
        _notifications.removeRange(60, _notifications.length);
    });
  }

  void _showNotifications() {
    String timeLabel(DateTime dt) =>
        '${_driverTwoDigits(dt.hour)}:${_driverTwoDigits(dt.minute)}';
    IconData eventIcon(String? event) {
      final e = (event ?? '').toLowerCase();
      if (e.contains('chat')) return Icons.chat_bubble_rounded;
      if (e.contains('cancel')) return Icons.block_rounded;
      if (e.contains('wallet')) return Icons.account_balance_wallet_rounded;
      if (e.contains('ride')) return Icons.local_taxi_rounded;
      return Icons.notifications_active_rounded;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF8F5EC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(children: [
                  Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: _C.yellow,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: _C.yellow.withOpacity(0.32),
                                blurRadius: 16,
                                offset: const Offset(0, 7))
                          ]),
                      child: const Icon(Icons.notifications_rounded,
                          color: _C.charcoal, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifications',
                              style: TextStyle(
                                  color: _C.textStrong,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17)),
                          Text('$_unreadCount unread updates',
                              style: const TextStyle(
                                  color: _C.textSoft,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ]),
                  ),
                  ManagementStatusPill(
                    label: '${_notifications.length}',
                    color: _C.info,
                    background: _C.infoBg,
                  ),
                ]),
              ),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 40, color: _C.textSoft),
                            const SizedBox(height: 8),
                            Text(
                                AppLocalizations.of(context)!
                                    .notificationsEmpty,
                                style: const TextStyle(color: _C.textSoft)),
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final color = n.isRead ? _C.textSoft : _C.yellowDeep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: n.isRead
                                    ? [Colors.white, _C.surfaceAlt]
                                    : [Colors.white, _C.yellowSoft],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: n.isRead
                                      ? _C.border
                                      : _C.yellowDeep.withOpacity(0.55)),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.charcoal.withOpacity(0.07),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                setState(() => n.isRead = true);
                                setSheetState(() {});
                                Navigator.of(context).pop();
                              },
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: color.withOpacity(0.20)),
                                        ),
                                        child: Icon(eventIcon(n.event),
                                            color: color, size: 19)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                child: Text(n.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight: n.isRead
                                                            ? FontWeight.w700
                                                            : FontWeight.w900,
                                                        fontSize: 13.5,
                                                        color: _C.textStrong)),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(timeLabel(n.createdAt),
                                                  style: const TextStyle(
                                                      color: _C.textSoft,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ]),
                                            const SizedBox(height: 4),
                                            Text(n.body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    height: 1.3,
                                                    color: _C.textSoft,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 7),
                                            Wrap(spacing: 6, children: [
                                              ManagementStatusPill(
                                                label:
                                                    n.isRead ? 'Read' : 'New',
                                                color: n.isRead
                                                    ? _C.textSoft
                                                    : _C.success,
                                                background: n.isRead
                                                    ? _C.surfaceAlt
                                                    : _C.successBg,
                                              ),
                                              if (n.rideId != null)
                                                ManagementStatusPill(
                                                  label: '#${n.rideId}',
                                                  color: _C.info,
                                                  background: _C.infoBg,
                                                ),
                                            ]),
                                          ]),
                                    ),
                                  ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _api.loginDriverPin(
          phone: _phoneController.text.trim(), pin: _pinController.text.trim());
      await SessionStore.saveDriverPin(r);
      if (!userChoseLocaleThisSession.value) {
        applyPreferredLanguageToApp(r.preferredLanguage);
      } else {
        try {
          await _api.patchPreferredLanguage(
              token: r.accessToken,
              preferredLanguage: appLocale.value.languageCode);
        } catch (_) {}
      }
      rememberCurrentLocaleForRole(AppUiRole.driver);
      setState(() {
        _token = r.accessToken;
        _userId = r.userId;
        _driverId = r.driverId;
        _driverName =
            _resolvedDriverName(primary: r.driverName, fallback: _driverName);
        _walletBalance = r.walletBalance;
        _isAvailable = true;
        _driverPhone = r.phone;
        _driverEmail = null;
        _carModel = r.carModel;
        _carColor = r.carColor;
        _photoUrl = r.photoUrl;
        _unreadChatByRideId.clear();
        _rideIdByConversationId.clear();
        _conversationIdByRideId.clear();
        _lastSeenMessageIdByConversationId.clear();
        _activeChatRideId = null;
        _message = l.loggedInAs(r.role);
      });
      final fares = await _api.getAirportFares();
      final locations = _startsFromRouteKeys(fares.keys, l);
      setState(() {
        _locations = locations;
        if (_location.isEmpty || !_locations.contains(_location))
          _location = _locations.isNotEmpty ? _locations.first : '';
      });
      await _detectDriverLocation(push: false);
      await _refreshRides();
      await _refreshArrivals(silent: true);
      await _hydrateDriverProfile();
      final host = Uri.tryParse(apiBaseUrl)?.host.toLowerCase() ?? '';
      final isWebLocal = kIsWeb &&
          (host == '127.0.0.1' || host == 'localhost' || host == '0.0.0.0');
      if (!isWebLocal)
        _socket.connect(r.accessToken,
            onReceiveMessage: _onChatMessage,
            onRideStatus: _onRideStatusEvent,
            onDriverWallet: _onDriverWallet);
      _startRidesPolling();
      await _pushDriverLocation();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshRides({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent)
      setState(() {
        _busy = true;
        _message = null;
      });
    try {
      final previousById = {for (final r in _rides) r.id: r};
      final rides = await _api.listRides(t);
      final walletSafeRides = (_walletBalance <= 0)
          ? rides.where((r) => r.status != 'pending').toList()
          : rides;
      if (_driverId == null) {
        for (final r in rides) {
          if (r.driverId != null) {
            _driverId = r.driverId;
            break;
          }
        }
      }
      setState(() => _rides = walletSafeRides);
      await _syncConversationRideMap(walletSafeRides);
      await _pollChatUnreadFallback();
      await _refreshGains();
      if (mounted) _processRideTransitions(previousById, walletSafeRides);
    } catch (e) {
      if (!silent) setState(() => _message = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshGains() async {
    final t = _token;
    if (t == null) return;
    try {
      final g = await _api.driverGains(t);
      if (!mounted) return;
      final wb = (g['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      final prev = _lastWalletSample;
      _lastWalletSample = wb;
      setState(() {
        _gains = g;
        _isAvailable = (g['is_available'] == true) && wb > 0;
        _walletBalance = wb;
      });
      if (wb > 0) {
        _walletDepletedNotifiedForZero = false;
      } else if (wb <= 0) {
        final crossedZero = prev != null && prev > 0;
        final openedFreshAtZero =
            prev == null && !_walletDepletedNotifiedForZero;
        if (crossedZero || openedFreshAtZero) {
          _onDriverWallet({
            'event': 'wallet_depleted',
            'wallet_balance': wb,
            'required_topup_dt': 100,
            'message': '',
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshArrivals({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) {
      setState(() {
        _busy = true;
        _message = null;
      });
    }
    try {
      final fr = await _api.listAdminTunisiaFlightArrivals(t);
      if (!mounted) return;
      setState(() {
        _flightArrivals = fr.flights;
        _flightDataSource = fr.source;
      });
    } catch (e) {
      if (!silent && mounted) setState(() => _message = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  String _arrivalAirportLabel(Map<String, dynamic> row) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') {
      return row['arrival_airport_ar']?.toString() ??
          row['arrival_airport_en']?.toString() ??
          '';
    }
    return row['arrival_airport_en']?.toString() ??
        row['arrival_airport_ar']?.toString() ??
        '';
  }

  String _departureAirportLabel(Map<String, dynamic> row) {
    final city = (row['departure_city'] ?? '').toString().trim();
    final country = (row['departure_country'] ?? '').toString().trim();
    final iata = (row['departure_iata'] ?? '').toString().trim().toUpperCase();
    if (city.isNotEmpty && country.isNotEmpty && iata.isNotEmpty) {
      return '$city, $country ($iata)';
    }
    return (row['departure_airport'] ?? '').toString();
  }

  String _prettyDateTime(String raw) {
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
      'Dec'
    ];
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final mon = months[local.month - 1];
    final year = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day $mon $year – $hh:$mm';
  }

  Future<void> _syncConversationRideMap(List<Ride> rides) async {
    final t = _token;
    if (t == null) return;
    final candidates =
        rides.where((r) => rideMayHaveConversation(r.status)).toList();
    for (final ride in candidates) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
      } catch (_) {}
    }
  }

  Future<void> _pollChatUnreadFallback() async {
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null) return;
    final l = AppLocalizations.of(context)!;
    for (final ride in _rides.where(
      (r) =>
          rideMayHaveConversation(r.status) &&
          _driverId != null &&
          r.driverId != null &&
          r.driverId == _driverId,
    )) {
      if (_activeChatRideId == ride.id) continue;
      try {
        final conversationId = await cachedOrFetchConversationId(
          api: _api,
          token: t,
          rideId: ride.id,
          conversationIdByRideId: _conversationIdByRideId,
          rideIdByConversationId: _rideIdByConversationId,
        );
        if (conversationId == null) continue;
        _lastSeenMessageIdByConversationId.putIfAbsent(conversationId, () => 0);
        final msgs = await _api.listConversationMessages(
            token: t, conversationId: conversationId, limit: 20);
        if (msgs.isEmpty) continue;
        final stored = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
        final delta = computeUnreadChatDelta(
            msgs: msgs, myUserId: uid, storedWatermark: stored);
        _lastSeenMessageIdByConversationId[conversationId] = delta.newWatermark;
        if (delta.incomingCount > 0) {
          if (!mounted) return;
          final int rid = ride.id;
          setState(() {
            _unreadChatByRideId[rid] =
                (_unreadChatByRideId[rid] ?? 0) + delta.incomingCount;
          });
          final latestIncoming = delta.latestIncoming;
          final body = (latestIncoming?.displayText.trim().isNotEmpty ?? false)
              ? latestIncoming!.displayText
              : l.openChatButton;
          final senderName = (latestIncoming?.senderName ?? '').trim();
          final title = senderName.isEmpty
              ? l.openChatButton
              : '${l.openChatButton} • $senderName';
          _pushNotification(
              title: title,
              body: body,
              event: 'chat_message_fallback',
              rideId: rid);
          LocalNotificationService.instance
              .show(title: title, body: body, isChat: true);
        }
      } catch (_) {}
    }
  }

  void _processRideTransitions(Map<int, Ride> previousById, List<Ride> rides) {
    if (_socket.isConnected) {
      _lastPendingRideIds =
          rides.where((r) => r.status == 'pending').map((r) => r.id).toSet();
      return;
    }
    final loc = AppLocalizations.of(context)!;
    final currentById = {for (final r in rides) r.id: r};
    final currentPendingRideIds =
        rides.where((r) => r.status == 'pending').map((r) => r.id).toSet();
    final removedPending =
        _lastPendingRideIds.difference(currentPendingRideIds);
    for (final rideId in removedPending) {
      if (_selfAcceptedRideIds.contains(rideId)) {
        _selfAcceptedRideIds.remove(rideId);
        continue;
      }
      final stillVisible = currentById[rideId];
      if (stillVisible != null &&
          _driverId != null &&
          stillVisible.driverId == _driverId) continue;
      if (_notifiedClosedRideIds.contains(rideId)) continue;
      _notifiedClosedRideIds.add(rideId);
      _pushNotification(
          title: loc.driverNotificationRequestClosedTitle,
          body: loc.driverNotificationRequestClosedBodyOther,
          event: 'ride_no_longer_visible',
          rideId: rideId);
    }
    _lastPendingRideIds = currentPendingRideIds;
    for (final ride in rides) {
      final prev = previousById[ride.id];
      if (prev == null && ride.status == 'pending') {
        _seenPendingRideIds.add(ride.id);
        _pushNotification(
            title: loc.driverNotificationNewRideTitle,
            body: loc.driverNotificationNewRideBodyDefault,
            event: 'ride_request_sent',
            rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.snackDriverNewNearbyRide)));
        LocalNotificationService.instance.show(
            title: loc.driverNotificationNewRideTitle,
            body: loc.driverNotificationNewRideBodyDefault);
      } else if (prev != null &&
          prev.status == 'pending' &&
          ride.status == 'accepted') {
        if (_selfAcceptedRideIds.contains(ride.id) ||
            (_driverId != null && ride.driverId == _driverId)) {
          _selfAcceptedRideIds.remove(ride.id);
          continue;
        }
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(
            title: loc.driverNotificationRequestClosedTitle,
            body: loc.driverNotificationRequestClosedBodyTaken,
            event: 'ride_taken_by_other_driver',
            rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.snackDriverRideTakenOther)));
        LocalNotificationService.instance.show(
            title: loc.driverNotificationRequestClosedTitle,
            body: loc.driverNotificationRequestClosedBodyTaken);
      } else if (prev != null &&
          prev.status != 'cancelled' &&
          ride.status == 'cancelled') {
        _notifiedClosedRideIds.add(ride.id);
        _pushNotification(
            title: loc.driverNotificationCancelledTitle,
            body: loc.driverNotificationCancelledBodyDefault,
            event: 'ride_cancelled_by_passenger',
            rideId: ride.id);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.snackDriverPassengerCancelled)));
        LocalNotificationService.instance.show(
            title: loc.driverNotificationCancelledTitle,
            body: loc.driverNotificationCancelledBodyDefault);
      }
      if (ride.status != 'pending') _seenPendingRideIds.remove(ride.id);
    }
    for (final prev in previousById.values) {
      if (prev.status == 'pending' &&
          !currentById.containsKey(prev.id) &&
          _seenPendingRideIds.contains(prev.id) &&
          !_notifiedClosedRideIds.contains(prev.id)) {
        _notifiedClosedRideIds.add(prev.id);
        _pushNotification(
            title: loc.driverNotificationRequestClosedTitle,
            body: loc.driverNotificationRequestClosedBodyOther,
            event: 'ride_no_longer_visible',
            rideId: prev.id);
        _seenPendingRideIds.remove(prev.id);
      }
    }
  }

  void _startRidesPolling() {
    _ridesPollingTimer?.cancel();
    Future<void> tick() async {
      if (!mounted || _token == null) return;
      if (!_busy) {
        await _refreshRides(silent: true);
      } else {
        await _pollChatUnreadFallback();
      }
    }

    unawaited(tick());
    _ridesPollingTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => unawaited(tick()));
  }

  Future<void> _pushDriverLocation() async {
    final t = _token;
    if (t == null || _location.isEmpty) return;
    try {
      await _api.updateDriverLocation(
        token: t,
        currentZone: _location,
        isAvailable: _isAvailable,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('wallet_depleted')) {
        setState(() => _isAvailable = false);
      }
    }
  }

  Future<void> _setAvailability(bool v) async {
    final t = _token;
    if (t == null) return;
    setState(() => _isAvailable = v);
    try {
      await _api.updateDriverLocation(
          token: t, currentZone: _location, isAvailable: v);
      await _refreshGains();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${l.statusLinePrefix}${localizedRideStatusLabel(l, v ? 'active' : 'cancelled')}')));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isAvailable = msg.contains('wallet_depleted') ? false : !v;
        _message = msg;
      });
    }
  }

  void _onDriverWallet(Map<String, dynamic> data) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final wbRaw = data['wallet_balance'];
    if (wbRaw is num) {
      final wb = wbRaw.toDouble();
      setState(() {
        _walletBalance = wb;
        if (wb <= 0) _isAvailable = false;
      });
      _lastWalletSample = wb;
    }
    final event = (data['event'] ?? '').toString();
    if (event != 'wallet_depleted') return;
    final now = DateTime.now();
    if (_lastWalletDepletedNotifAt != null &&
        now.difference(_lastWalletDepletedNotifAt!) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastWalletDepletedNotifAt = now;
    _walletDepletedNotifiedForZero = true;
    final amount = (data['required_topup_dt'] as num?)?.round() ?? 100;
    final body = ((data['message'] ?? '').toString().trim().isNotEmpty)
        ? (data['message'] as String).trim()
        : loc.driverWalletDepletedBody(amount);
    _pushNotification(
        title: loc.driverWalletDepletedTitle,
        body: body,
        event: 'wallet_depleted');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
    LocalNotificationService.instance
        .show(title: loc.driverWalletDepletedTitle, body: body);
  }

  void _onRideStatusEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final event = (payload['event'] ?? '').toString();
    final serverMessage = (payload['message'] ?? '').toString().trim();
    if (event == 'ride_taken_by_other_driver') {
      final accepterUserId =
          (payload['accepted_driver_user_id'] as num?)?.toInt() ??
              (payload['driver_id'] as num?)?.toInt();
      if (accepterUserId != null &&
          _userId != null &&
          accepterUserId == _userId) return;
      _pushNotification(
          title: loc.driverNotificationRequestClosedTitle,
          body: serverMessage.isNotEmpty
              ? serverMessage
              : loc.driverNotificationRequestClosedBodyTaken,
          event: event);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(serverMessage.isNotEmpty
              ? serverMessage
              : loc.snackDriverRideTakenOther)));
      LocalNotificationService.instance.show(
          title: loc.driverNotificationRequestClosedTitle,
          body: serverMessage.isNotEmpty
              ? serverMessage
              : loc.driverNotificationRequestClosedBodyTaken);
      _refreshRides();
      return;
    }
    if (event == 'ride_request_sent') {
      _pushNotification(
          title: loc.driverNotificationNewRideTitle,
          body: serverMessage.isNotEmpty
              ? serverMessage
              : loc.driverNotificationNewRideBodyDefault,
          event: event);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(serverMessage.isNotEmpty
              ? serverMessage
              : loc.snackDriverNewNearbyRide)));
      LocalNotificationService.instance.show(
          title: loc.driverNotificationNewRideTitle,
          body: serverMessage.isNotEmpty
              ? serverMessage
              : loc.driverNotificationNewRideBodyDefault);
      _refreshRides();
      return;
    }
    if (serverMessage.isNotEmpty) {
      _pushNotification(
          title: loc.notificationRideUpdateTitle,
          body: serverMessage,
          event: event.isEmpty ? 'ride_status_changed' : event);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(serverMessage)));
      LocalNotificationService.instance
          .show(title: loc.notificationRideUpdateTitle, body: serverMessage);
      _refreshRides();
    }
  }

  Future<int?> _resolveRideIdFromChatPayload(Map<String, dynamic> data) async {
    final directRideId = intFromDynamic(data['ride_id']);
    if (directRideId != null) return directRideId;
    final conversationId = intFromDynamic(data['conversation_id']);
    if (conversationId == null) return null;
    final cached = _rideIdByConversationId[conversationId];
    if (cached != null) return cached;
    final t = _token;
    if (t == null) return null;
    final candidates =
        _rides.where((r) => rideMayHaveConversation(r.status)).toList();
    for (final ride in candidates) {
      try {
        final info = await _api.getRideConversation(token: t, rideId: ride.id);
        if (info == null) continue;
        _rideIdByConversationId[info.conversationId] = ride.id;
        _conversationIdByRideId[ride.id] = info.conversationId;
        if (info.conversationId == conversationId) return ride.id;
      } catch (_) {}
    }
    return null;
  }

  void _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted) return;
    final ChatMessage msg;
    try {
      msg = ChatMessage.fromJson(data);
    } catch (_) {
      return;
    }
    final uid = _userId;
    if (uid == null || msg.senderUserId == uid) return;
    var rideId = await _resolveRideIdFromChatPayload(data);
    if (rideId == null && intFromDynamic(data['conversation_id']) != null) {
      await _refreshRides(silent: true);
      if (!mounted) return;
      rideId = await _resolveRideIdFromChatPayload(data);
    }
    if (!mounted || rideId == null) return;
    final conversationId = intFromDynamic(data['conversation_id']);
    final int rid = rideId;
    if (conversationId != null) {
      final prev = _lastSeenMessageIdByConversationId[conversationId] ?? 0;
      if (msg.id > prev)
        _lastSeenMessageIdByConversationId[conversationId] = msg.id;
      _conversationIdByRideId[rid] = conversationId;
      _rideIdByConversationId[conversationId] = rid;
    }
    if (_activeChatRideId == rid) return;
    final l = AppLocalizations.of(context)!;
    final body =
        msg.displayText.trim().isEmpty ? l.openChatButton : msg.displayText;
    setState(() {
      _unreadChatByRideId[rid] = (_unreadChatByRideId[rid] ?? 0) + 1;
    });
    final senderName = (msg.senderName ?? '').trim();
    final title = senderName.isEmpty
        ? l.openChatButton
        : '${l.openChatButton} • $senderName';
    _pushNotification(
        title: title, body: body, event: 'chat_message', rideId: rid);
    LocalNotificationService.instance
        .show(title: title, body: body, isChat: true);
  }

  Future<void> _acceptRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    _selfAcceptedRideIds.add(ride.id);
    setState(() => _busy = true);
    try {
      await _api.acceptRide(token: t, rideId: ride.id);
      await _refreshRides();
      _tabController?.animateTo(1);
    } catch (e) {
      _selfAcceptedRideIds.remove(ride.id);
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _declineOffer(Ride ride) {
    setState(() => _dismissedPendingRideIds.add(ride.id));
  }

  Future<void> _releaseRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.rejectRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.startRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRide(Ride ride) async {
    final t = _token;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await _api.completeRide(token: t, rideId: ride.id);
      await _refreshRides();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _primeReadWatermarkAfterChat({
    required String token,
    required int conversationId,
    required int rideId,
  }) async {
    try {
      final msgs = await _api.listConversationMessages(
        token: token,
        conversationId: conversationId,
        limit: 150,
      );
      if (!mounted) return;
      final maxId = maxChatMessageId(msgs);
      setState(() {
        _lastSeenMessageIdByConversationId[conversationId] = maxId;
        _unreadChatByRideId.remove(rideId);
      });
    } catch (_) {}
  }

  Future<void> _openChat(Ride ride) async {
    final t = _token;
    final uid = _userId;
    if (t == null || uid == null || uid <= 0) return;
    try {
      final info = await _api.getRideConversation(token: t, rideId: ride.id);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.snackDriverChatAfterAcceptance)));
        return;
      }
      final cid = info.conversationId;
      setState(() {
        _activeChatRideId = ride.id;
        _unreadChatByRideId.remove(ride.id);
      });
      _rideIdByConversationId[cid] = ride.id;
      _conversationIdByRideId[ride.id] = cid;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideChatScreen(
            token: t,
            myUserId: uid,
            rideId: ride.id,
            conversationId: cid,
            showDriverQuickReplies: true,
          ),
        ),
      );
      if (mounted && _activeChatRideId == ride.id)
        setState(() => _activeChatRideId = null);
      await _primeReadWatermarkAfterChat(
          token: t, conversationId: cid, rideId: ride.id);
      await _refreshRides(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted && _activeChatRideId == ride.id)
        setState(() => _activeChatRideId = null);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _ridesPollingTimer?.cancel();
    _socket.disconnect();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _chatActionButton(Ride ride) {
    final l = AppLocalizations.of(context)!;
    final unread = _unreadChatByRideId[ride.id] ?? 0;
    return Badge(
      label: Text(unread > 99 ? '99+' : '$unread',
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A))),
      padding:
          EdgeInsets.only(left: unread > 0 ? 6 : 0, right: unread > 0 ? 6 : 0),
      isLabelVisible: unread > 0,
      offset: const Offset(10, -6),
      backgroundColor: _C.yellow,
      child: GestureDetector(
        onTap: _busy ? null : () => _openChat(ride),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _C.charcoal,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                  color: _C.charcoal.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(l.openChatButton,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ══ PENDING OFFERS TAB ═════════════════════════════════════
  Widget _buildPendingTab(AppLocalizations l, List<Ride> pendingOffers) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshRides,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            accent: true,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead('Dispatch',
                  subtitle: '${pendingOffers.length} open offers'),
              // Zone selector
              Container(
                decoration: BoxDecoration(
                    color: _C.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _location.isEmpty ? null : _location,
                    isExpanded: true,
                    icon: const Icon(Icons.place_outlined,
                        color: _C.charcoal, size: 18),
                    items: _locations
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(localizedPlaceName(l, e),
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _location = v);
                      await _pushDriverLocation();
                    },
                    hint: Text(l.ridePickupLabel,
                        style:
                            const TextStyle(color: _C.textSoft, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationText != null
                              ? 'GPS: $_locationText'
                              : (_locationError ??
                                  (_locating
                                      ? l.passengerLocationDetecting
                                      : l.passengerLocationUnavailable)),
                          style:
                              const TextStyle(color: _C.textSoft, fontSize: 11),
                        ),
                        if (_nearestZoneDistanceKm != null &&
                            _location.trim().isNotEmpty)
                          Text(
                            'Nearest zone: ${localizedPlaceName(l, _location)} (${_nearestZoneDistanceKm!.toStringAsFixed(1)} km)',
                            style: TextStyle(
                              color: _distanceColor(_nearestZoneDistanceKm!),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _locating
                        ? null
                        : () => unawaited(_detectDriverLocation()),
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _DarkButton(
                        label: l.adminLoadRidesBtn,
                        icon: Icons.refresh_rounded,
                        onPressed: _busy ? null : _refreshRides,
                        small: true)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _StatChip(
                    label: l.driverPendingRides,
                    value: '${pendingOffers.length}',
                    icon: Icons.hourglass_top_rounded,
                    color: _C.yellowDeep),
                _StatChip(
                    label: 'Alerts',
                    value: '$_unreadCount',
                    icon: Icons.notifications_active_rounded,
                    color: _C.info),
              ]),
            ]),
          ),
          if (pendingOffers.isEmpty)
            _Module(
              child: ManagementEmptyState(
                message: l.driverPendingRides,
                icon: Icons.local_taxi_outlined,
              ),
            )
          else
            ...pendingOffers
                .where((r) => !_dismissedPendingRideIds.contains(r.id))
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DriverRideOfferCard(
                          ride: r,
                          api: _api,
                          busy: _busy,
                          onAccept: () => _acceptRide(r),
                          onReject: () => _declineOffer(r)),
                    )),
        ],
      ),
    );
  }

  // ══ HISTORY TAB ════════════════════════════════════════════
  Widget _buildHistoryTab(AppLocalizations l, List<Ride> historyRides) {
    final visibleRides = historyRides
        .where((r) => _historyFilter == 'all' || r.status == _historyFilter)
        .toList();
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshRides,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Module(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHead(l.operatorTabTripHistory,
                  subtitle: '${visibleRides.length} rides'),
              Container(
                decoration: BoxDecoration(
                    color: _C.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _historyFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.filter_list_rounded,
                        color: _C.charcoal, size: 18),
                    items: [
                      DropdownMenuItem(
                          value: 'all',
                          child: Text(l.adminRidesHeading,
                              style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'completed',
                          child: Text(localizedRideStatusLabel(l, 'completed'),
                              style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'cancelled',
                          child: Text(localizedRideStatusLabel(l, 'cancelled'),
                              style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'accepted',
                          child: Text(localizedRideStatusLabel(l, 'accepted'),
                              style: const TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'ongoing',
                          child: Text(localizedRideStatusLabel(l, 'ongoing'),
                              style: const TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) =>
                        setState(() => _historyFilter = v ?? 'all'),
                  ),
                ),
              ),
            ]),
          ),
          if (visibleRides.isEmpty)
            _Module(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 36, color: _C.textSoft),
                const SizedBox(height: 8),
                Text(l.noTripsYet, style: const TextStyle(color: _C.textSoft)),
              ]),
            )))
          else
            ...visibleRides.map((r) {
              final passengerName = r.isB2b == true
                  ? ((r.b2bGuestName ?? '').trim().isEmpty
                      ? (r.passengerName ?? '-')
                      : r.b2bGuestName!)
                  : ((r.passengerName ?? '').trim().isEmpty
                      ? '-'
                      : r.passengerName!);
              final passengerPhone = (r.passengerPhone ?? '').trim();
              final dateSource =
                  (r.scheduledPickupAt ?? r.createdAt ?? '').trim();
              if (r.status == 'accepted' || r.status == 'ongoing') {
                return _DriverRideDetailsCard(
                  ride: r,
                  api: _api,
                  busy: _busy,
                  onStart: _busy ? null : () => _startRide(r),
                  onRelease: _busy ? null : () => _releaseRide(r),
                  onComplete: _busy ? null : () => _completeRide(r),
                  chatButton: rideMayHaveConversation(r.status)
                      ? _chatActionButton(r)
                      : null,
                );
              }
              return _DriverTripHistoryCard(
                ride: r,
                statusLabel: localizedRideStatusLabel(l, r.status),
                route: localizedRideRouteRow(l, r.pickup, r.destination),
                passengerLine:
                    '${r.isB2b == true ? l.roleB2b : l.rolePassenger}: $passengerName${passengerPhone.isEmpty ? '' : ' • $passengerPhone'}',
                metaLine:
                    '${_driverPrettyDate(dateSource)} • ${_driverPrettyTime(dateSource)}',
                actions: [
                  if (r.status == 'accepted')
                    _DarkButton(
                        label: l.startRide,
                        icon: Icons.play_arrow_rounded,
                        onPressed: _busy ? null : () => _startRide(r),
                        small: true,
                        fullWidth: false),
                  if (r.status == 'accepted' || r.status == 'ongoing')
                    GestureDetector(
                      onTap: _busy ? null : () => _releaseRide(r),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            color: _C.dangerBg,
                            borderRadius: BorderRadius.circular(50),
                            border:
                                Border.all(color: _C.danger.withOpacity(0.3))),
                        child: Center(
                            child: Text(l.cancelRidePassenger,
                                style: const TextStyle(
                                    color: _C.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                      ),
                    ),
                  if (r.status == 'ongoing')
                    _YellowButton(
                        label: l.completeRide,
                        icon: Icons.check_rounded,
                        onPressed: _busy ? null : () => _completeRide(r),
                        small: true,
                        fullWidth: false),
                  if (rideMayHaveConversation(r.status)) _chatActionButton(r),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildArrivalsTab(AppLocalizations l) {
    return RefreshIndicator(
      color: _C.yellow,
      onRefresh: _refreshArrivals,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _DarkButton(
            label: l.adminLoadRidesBtn,
            icon: Icons.refresh_rounded,
            onPressed: _busy ? null : _refreshArrivals,
          ),
          const SizedBox(height: 16),
          _SectionHead(l.operatorTabTodaysArrivals),
          if ((_flightDataSource ?? '').startsWith('demo'))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.yellowDeep.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _C.charcoal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.flightArrivalsSampleDataBanner,
                        style: const TextStyle(
                            color: _C.textStrong, fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_flightArrivals.isEmpty)
            _Module(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flight_land_rounded,
                        size: 40,
                        color: _C.textSoft,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.operatorNoFlightArrivals,
                        style: const TextStyle(color: _C.textSoft),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _Module(
              padding: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_C.charcoal),
                  headingTextStyle: const TextStyle(
                    color: _C.yellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith(
                    (s) =>
                        s.contains(WidgetState.selected) ? _C.yellowSoft : null,
                  ),
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _C.border),
                  ),
                  columns: [
                    DataColumn(label: Text(l.operatorColFlightNumber)),
                    const DataColumn(label: Text('Airline')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Aircraft')),
                    DataColumn(label: Text(l.operatorColDepartureAirport)),
                    DataColumn(label: Text(l.operatorColTakeoffTime)),
                    DataColumn(label: Text(l.operatorColExpectedArrival)),
                    const DataColumn(label: Text('Last update')),
                    const DataColumn(label: Text('Speed')),
                    const DataColumn(label: Text('Altitude')),
                    DataColumn(label: Text(l.operatorColArrivalAirportTn)),
                  ],
                  rows: _flightArrivals.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r['flight_number']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['airline'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['status'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['aircraft'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _departureAirportLabel(r),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            r['takeoff_time']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (() {
                              final raw = _prettyDateTime(
                                r['expected_arrival']?.toString() ?? '',
                              );
                              return raw.trim().isEmpty ? '-' : raw;
                            })(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _prettyDateTime(r['last_update']?.toString() ?? ''),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['speed_kmh'] == null)
                                ? '-'
                                : '${r['speed_kmh']} km/h',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            (r['altitude_m'] == null)
                                ? '-'
                                : '${r['altitude_m']} m',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            _arrivalAirportLabel(r),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pendingOffers = (_walletBalance > 0 && _isAvailable)
        ? _rides.where((r) => r.status == 'pending').toList()
        : <Ride>[];
    final historyRides = _rides
        .where((r) => _driverId != null && r.driverId == _driverId)
        .toList();

    return Scaffold(
      backgroundColor: _C.bgWarm,
      appBar: AppBar(
        backgroundColor: _C.yellow,
        foregroundColor: _C.charcoal,
        centerTitle: true,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, color: _C.charcoal),
        ),
        title: Text(
          _uiText(
            en: 'Driver Workspace',
            ar: 'مساحة السائق',
            fr: 'Espace chauffeur',
            es: 'Espacio conductor',
            de: 'Fahrerbereich',
            it: 'Area autista',
            ru: 'Панель водителя',
            zh: '司机工作台',
          ),
          style: const TextStyle(
              color: _C.charcoal, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          LocalePopupMenuButton(
            authToken: _token,
            uiRole: AppUiRole.driver,
            foregroundColor: _C.charcoal,
          ),
          if (_token != null)
            IconButton(
              onPressed: () => unawaited(_logout()),
              tooltip: l.logoutApp,
              icon: const Icon(Icons.logout_rounded, color: _C.charcoal),
            ),
          if (_token != null)
            IconButton(
              onPressed: _showNotifications,
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_rounded, color: _C.charcoal),
                if (_unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: _C.yellow,
                          borderRadius: BorderRadius.circular(10)),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 14),
                      child: Text(_unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                              color: _C.charcoal,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ]),
            ),
        ],
      ),
      body: _token == null
          // ── Login ─────────────────────────────────────────
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 92,
                    height: 72,
                    decoration: BoxDecoration(
                        color: _C.yellow,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: _C.yellow.withOpacity(0.45),
                              blurRadius: 20)
                        ]),
                    child: const VoomLogo(height: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text('Driver Portal',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: _C.textStrong)),
                  const SizedBox(height: 4),
                  const Text('Sign in with your phone & PIN',
                      style: TextStyle(color: _C.textSoft, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.border),
                        boxShadow: [
                          BoxShadow(
                              color: _C.charcoal.withOpacity(0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration:
                              _fd(l.emailLabel, icon: Icons.phone_rounded)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinController,
                        obscureText: _obscurePin,
                        decoration: _fd(l.passwordLabel,
                                icon: Icons.lock_outline_rounded)
                            .copyWith(
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _C.charcoal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _YellowButton(
                          label: l.login,
                          icon: Icons.login_rounded,
                          onPressed: _busy ? null : _login),
                    ]),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: _C.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _C.danger.withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _C.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_message!,
                                style: const TextStyle(
                                    color: _C.danger, fontSize: 13)))
                      ]),
                    ),
                  ],
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                        color: _C.yellow, strokeWidth: 2.5)
                  ],
                ]),
              ),
            )
          // ── Dashboard ─────────────────────────────────────
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Welcome / status banner
              ManagementModuleCard(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: 12,
                accent: true,
                child: Row(children: [
                  GestureDetector(
                    onTap: _busy ? null : () => _setAvailability(!_isAvailable),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: _isAvailable ? _C.success : _C.charcoal,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: (_isAvailable ? _C.success : _C.charcoal)
                                .withOpacity(0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_isAvailable ? 'Online' : 'Offline',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverName != null
                                ? '${l.sessionActive} · $_driverName'
                                : l.sessionActive,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _C.charcoal,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _uiText(
                                en: 'Premium driver command center',
                                ar: 'مركز قيادة السائق المميز',
                                fr: 'Centre de conduite premium',
                                es: 'Centro premium del conductor',
                                de: 'Premium-Fahrerzentrale',
                                it: 'Centro guida premium',
                                ru: 'Премиум центр водителя',
                                zh: '高级司机工作中心'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _C.textSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 11),
                          ),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  ManagementStatusPill(
                    label: '${_walletBalance.toStringAsFixed(2)} DT',
                    color: _C.charcoal,
                    background: _C.yellowSoft,
                  ),
                ]),
              ),
              // Gains snapshot (collapsible)
              if (_gains != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border)),
                  child: Row(children: [
                    _StatChip(
                        label: 'Net Gains',
                        value:
                            '${((_gains!['net_gains'] ?? 0) as num).toStringAsFixed(2)} DT',
                        icon: Icons.payments_outlined,
                        color: _C.success),
                    const SizedBox(width: 8),
                    _StatChip(
                        label: 'Trips',
                        value: '${_gains!['completed_rides_count'] ?? 0}',
                        icon: Icons.route_outlined),
                  ]),
                ),
              // Driver profile card (name/photo/info/edit)
              _buildPhotoStrip(l),
              const SizedBox(height: 6),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.border.withOpacity(0.82)),
                  boxShadow: [
                    BoxShadow(
                      color: _C.charcoal.withOpacity(0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(5),
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD84D), Color(0xFFFFC200)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _C.yellow.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _C.charcoal,
                  unselectedLabelColor: _C.textSoft,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.3),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 12),
                  tabs: [
                    Tab(text: '🚖 ${l.driverPendingRides}'),
                    Tab(text: '📋 ${l.operatorTabTripHistory}'),
                    Tab(text: '✈️ ${l.operatorTabTodaysArrivals}'),
                  ],
                ),
              ),
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(l, pendingOffers),
                  _buildHistoryTab(l, historyRides),
                  _buildArrivalsTab(l),
                ],
              )),
              if (_message != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: _C.dangerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.danger.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: _C.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_message!,
                            style: const TextStyle(
                                color: _C.danger, fontSize: 13)))
                  ]),
                ),
            ]),
    );
  }

  Widget _buildPhotoStrip(AppLocalizations l) {
    final provider = _stableProfileImageProvider();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _C.yellowDeep, width: 2),
                image: provider == null
                    ? null
                    : DecorationImage(image: provider, fit: BoxFit.cover),
                color: _C.surfaceAlt,
              ),
              child: provider == null
                  ? const Icon(Icons.person_rounded, color: _C.textSoft)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_driverName ?? '').trim().isEmpty
                          ? _uiText(
                              en: 'Driver',
                              ar: 'السائق',
                              fr: 'Chauffeur',
                              es: 'Conductor',
                              de: 'Fahrer',
                              it: 'Autista',
                              ru: 'Водитель',
                              zh: '司机')
                          : _driverName!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _C.textStrong),
                    ),
                    if ((_driverPhone ?? '').trim().isNotEmpty)
                      Text(
                          '${_uiText(en: 'Phone', ar: 'الهاتف', fr: 'Telephone', es: 'Telefono', de: 'Telefon', it: 'Telefono', ru: 'Телефон', zh: '电话')}: ${_driverPhone!}',
                          style: const TextStyle(
                              color: _C.textSoft, fontSize: 12)),
                    if ((_driverEmail ?? '').trim().isNotEmpty)
                      Text(
                          '${_uiText(en: 'Email', ar: 'البريد الإلكتروني', fr: 'Email', es: 'Correo', de: 'E-Mail', it: 'Email', ru: 'Email', zh: '邮箱')}: ${_driverEmail!}',
                          style: const TextStyle(
                              color: _C.textSoft, fontSize: 12)),
                    Text(
                        '${_uiText(en: 'Car', ar: 'السيارة', fr: 'Voiture', es: 'Coche', de: 'Auto', it: 'Auto', ru: 'Авто', zh: '车辆')}: ${(_carModel ?? '').trim().isEmpty ? '—' : _carModel} · ${(_carColor ?? '').trim().isEmpty ? '—' : _carColor}',
                        style:
                            const TextStyle(color: _C.textSoft, fontSize: 12)),
                  ]),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _C.yellow,
                foregroundColor: _C.charcoal,
                side: const BorderSide(color: _C.yellowDeep),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: _busy ? null : _showEditDriverProfileDialog,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(_uiText(
                  en: 'Edit',
                  ar: 'تعديل',
                  fr: 'Modifier',
                  es: 'Editar',
                  de: 'Bearbeiten',
                  it: 'Modifica',
                  ru: 'Изменить',
                  zh: '编辑')),
            ),
          ]),
        ],
      ),
    );
  }

  List<String> _startsFromRouteKeys(
      Iterable<String> routeKeys, AppLocalizations l) {
    final starts = <String>{};
    for (final key in routeKeys) {
      final parts = key.split(airportRouteKeySeparator);
      if (parts.isNotEmpty) starts.add(parts.first.trim());
    }
    return starts.toList()
      ..sort((a, b) =>
          localizedPlaceName(l, a).compareTo(localizedPlaceName(l, b)));
  }

  ImageProvider<Object>? _imageProviderFromString(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:image/')) {
      final commaIdx = raw.indexOf(',');
      if (commaIdx <= 0 || commaIdx + 1 >= raw.length) return null;
      try {
        return MemoryImage(base64Decode(raw.substring(commaIdx + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(raw);
  }

  ImageProvider<Object>? _stableProfileImageProvider() {
    final raw = (_photoUrl ?? '').trim();
    if (raw == _profileImageRaw) return _profileImageProvider;
    _profileImageRaw = raw;
    _profileImageProvider = _imageProviderFromString(raw);
    return _profileImageProvider;
  }
}

class _ZoneCoord {
  const _ZoneCoord(this.lat, this.lng);
  final double lat;
  final double lng;
}
