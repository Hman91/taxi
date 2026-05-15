import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/place_localization.dart';
import '../../maps/tunisia_zone_coordinates.dart';
import '../../services/google_places_service.dart';
import '../../widgets/management_platform_ui.dart';
import 'owner_buttons.dart';
import 'owner_colors.dart';
import 'owner_field_decoration.dart';

/// Settings tab: commission demo slider + place-aware route fare editor.
class OwnerSettingsTab extends StatefulWidget {
  const OwnerSettingsTab({
    super.key,
    required this.l,
    required this.busy,
    required this.commissionPercent,
    required this.onCommissionChanged,
    required this.fareRoutes,
    required this.fareControllers,
    required this.onSaveFare,
    required this.onPullRefresh,
    this.searchHint =
        'Search by place, airport, or route — suggestions from Maps.',
  });

  final AppLocalizations l;
  final bool busy;
  final double commissionPercent;
  final ValueChanged<double> onCommissionChanged;
  final List<Map<String, dynamic>> fareRoutes;
  final Map<int, TextEditingController> fareControllers;
  final Future<void> Function(int routeId) onSaveFare;
  final Future<void> Function() onPullRefresh;
  final String searchHint;

  @override
  State<OwnerSettingsTab> createState() => _OwnerSettingsTabState();
}

class _OwnerSettingsTabState extends State<OwnerSettingsTab> {
  final _places = GooglePlacesService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PlaceAutocompleteItem> _suggestions = [];
  bool _suggestLoading = false;
  String? _suggestError;
  String _routeFilter = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRoutes {
    final q = _routeFilter.trim().toLowerCase();
    if (q.isEmpty) return widget.fareRoutes;
    return widget.fareRoutes.where((r) {
      final a = (r['start'] ?? '').toString().toLowerCase();
      final b = (r['destination'] ?? '').toString().toLowerCase();
      final row = localizedRideRouteRow(
        widget.l,
        (r['start'] ?? '').toString(),
        (r['destination'] ?? '').toString(),
      ).toLowerCase();
      return a.contains(q) || b.contains(q) || row.contains(q);
    }).toList();
  }

  void _applyFilterFromText(String raw) {
    final t = raw.trim();
    setState(() => _routeFilter = t);
    _debounce?.cancel();
    if (t.length < 2 || !_places.isConfigured) {
      setState(() {
        _suggestions = [];
        _suggestLoading = false;
        _suggestError =
            t.length >= 2 && !_places.isConfigured ? 'Maps key missing' : null;
      });
      return;
    }
    setState(() {
      _suggestLoading = true;
      _suggestError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final list = await _places.autocomplete(
          t,
          biasCenter: TunisiaZoneCoordinates.tunisOverview,
        );
        if (!mounted) return;
        setState(() {
          _suggestions = list;
          _suggestLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestLoading = false;
          _suggestError = e.toString();
        });
      }
    });
  }

  void _pickSuggestion(PlaceAutocompleteItem item) {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchCtrl.text = item.label;
      _routeFilter = item.label;
      _suggestions = [];
      _suggestError = null;
    });
  }

  void _clearFilter() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchCtrl.clear();
      _routeFilter = '';
      _suggestions = [];
      _suggestError = null;
    });
  }

  Widget _buildFareRouteTile(AppLocalizations l, Map<String, dynamic> r) {
    final id = (r['id'] as num).toInt();
    final label = localizedRideRouteRow(
      l,
      r['start']?.toString() ?? '',
      r['destination']?.toString() ?? '',
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OwnerColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OwnerColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: OwnerColors.textStrong,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: widget.busy
                      ? null
                      : () {
                          final c = widget.fareControllers[id];
                          if (c == null) return;
                          final v = double.tryParse(
                                  c.text.replaceAll(',', '.')) ??
                              0;
                          c.text = (v > 1 ? v - 1 : 0).toStringAsFixed(2);
                          setState(() {});
                        },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: OwnerColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.fareControllers[id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    decoration: ownerFieldDecoration('', suffix: 'DT'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.busy
                      ? null
                      : () {
                          final c = widget.fareControllers[id];
                          if (c == null) return;
                          final v = double.tryParse(
                                  c.text.replaceAll(',', '.')) ??
                              0;
                          c.text = (v + 1).toStringAsFixed(2);
                          setState(() {});
                        },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: OwnerColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OwnerYellowButton(
                label: l.ownerSaveRouteFare,
                icon: Icons.save_outlined,
                onPressed: widget.busy
                    ? null
                    : () => unawaited(widget.onSaveFare(id)),
                small: true,
                fullWidth: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final filtered = _filteredRoutes;
    return RefreshIndicator(
      color: OwnerColors.yellow,
      onRefresh: widget.onPullRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: ManagementModuleCard(
                accent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ManagementSectionHeader(l.ownerSettingsCommissionLabel),
                    Text(
                      l.ownerSettingsCommissionHint,
                      style: const TextStyle(
                        color: OwnerColors.textSoft,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        widget.commissionPercent.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: OwnerColors.charcoal,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        '%',
                        style: TextStyle(
                            color: OwnerColors.textSoft, fontSize: 14),
                      ),
                    ),
                    Slider(
                      value: widget.commissionPercent.clamp(0.0, 40.0),
                      min: 0,
                      max: 40,
                      divisions: 400,
                      label: widget.commissionPercent.toStringAsFixed(1),
                      activeColor: OwnerColors.yellow,
                      inactiveColor: OwnerColors.border,
                      onChanged:
                          widget.busy ? null : widget.onCommissionChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(
              child: ManagementModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ManagementSectionHeader(
                      l.ownerSettingsRouteFaresHeading,
                      subtitle:
                          '${filtered.length} / ${widget.fareRoutes.length} routes',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.searchHint,
                      style: const TextStyle(
                        color: OwnerColors.textSoft,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _applyFilterFromText,
                      enabled: !widget.busy,
                      decoration: ownerFieldDecoration(
                        l.ownerSettingsRouteFaresHeading,
                        icon: Icons.search_rounded,
                      ).copyWith(
                        hintText: l.messageFieldHint,
                        hintStyle: const TextStyle(
                          color: OwnerColors.textSoft,
                          fontSize: 13,
                        ),
                        suffixIcon: _routeFilter.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: widget.busy ? null : _clearFilter,
                                icon: const Icon(Icons.close_rounded,
                                    color: OwnerColors.charcoal),
                              ),
                      ),
                    ),
                    if (_suggestLoading ||
                        _suggestions.isNotEmpty ||
                        _suggestError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          color: OwnerColors.surface,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: _suggestLoading && _suggestions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: OwnerColors.yellow,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    children: [
                                      if (_suggestError != null)
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            _suggestError!,
                                            style: const TextStyle(
                                              color: OwnerColors.danger,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ..._suggestions.map((s) {
                                        return InkWell(
                                          onTap: widget.busy
                                              ? null
                                              : () => _pickSuggestion(s),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 11,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  s.isAirport
                                                      ? Icons
                                                          .flight_takeoff_rounded
                                                      : Icons.place_rounded,
                                                  size: 18,
                                                  color: s.isAirport
                                                      ? OwnerColors.info
                                                      : OwnerColors.yellowDeep,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        s.label,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13.5,
                                                          color: OwnerColors
                                                              .textStrong,
                                                          height: 1.25,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Tap to filter fares for this area',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: OwnerColors
                                                              .textSoft
                                                              .withValues(
                                                                  alpha: 0.9),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.north_west_rounded,
                                                  size: 16,
                                                  color: OwnerColors.textSoft,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.fareRoutes.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l.adminNoRidesLoaded,
                  style: const TextStyle(color: OwnerColors.textSoft),
                ),
              ),
            )
          else if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'No routes match this filter. Clear the search or type a different place.',
                  style: const TextStyle(color: OwnerColors.textSoft),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildFareRouteTile(l, filtered[index]);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
