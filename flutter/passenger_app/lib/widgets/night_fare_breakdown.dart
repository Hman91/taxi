import 'package:flutter/material.dart';

/// Futuristic fare strip: base → night surcharge → total (from `/api/fares/quote`).
class NightFareBreakdown extends StatelessWidget {
  const NightFareBreakdown({
    super.key,
    required this.quote,
    this.afterPromoTotal,
    this.promoLabel,
    this.nightRateLabel = 'Night rate applied (+50%)',
    this.baseLabel = 'Base',
    this.surchargeLabel = 'Night surcharge',
    this.totalLabel = 'Total',
  });

  final Map<String, dynamic> quote;
  final double? afterPromoTotal;
  final String? promoLabel;
  final String nightRateLabel;
  final String baseLabel;
  final String surchargeLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final base = (quote['base_fare'] as num?)?.toDouble();
    final sur = (quote['night_surcharge_dt'] as num?)?.toDouble();
    final rawFinal = (quote['final_fare'] as num?)?.toDouble();
    final isNight = quote['is_night'] == true;
    if (base == null || rawFinal == null) return const SizedBox.shrink();

    final totalOut = afterPromoTotal ?? rawFinal;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            scheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isNight ? 0.12 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.2),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nightlight_round,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      nightRateLabel,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _line(context, baseLabel, '${base.toStringAsFixed(2)} DT', muted: true),
          if (isNight && (sur ?? 0) > 0)
            _line(context, surchargeLabel, '+${sur!.toStringAsFixed(2)} DT',
                accent: const Color(0xFF8B5CF6)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _line(context, totalLabel, '${totalOut.toStringAsFixed(2)} DT',
              strong: true),
          if (promoLabel != null && promoLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                promoLabel!,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String k,
    String v, {
    bool muted = false,
    bool strong = false,
    Color? accent,
  }) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: (muted ? t.bodySmall : t.bodyMedium)?.copyWith(
              color: accent ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            v,
            style: t.titleSmall?.copyWith(
              color: accent ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
