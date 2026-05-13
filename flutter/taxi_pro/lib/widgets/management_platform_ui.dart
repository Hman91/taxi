import 'package:flutter/material.dart';

import '../theme/taxi_app_theme.dart';

class ManagementModuleCard extends StatelessWidget {
  const ManagementModuleCard({
    super.key,
    required this.child,
    this.padding = 16,
    this.accent = false,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final double padding;
  final bool accent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: accent
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFF8E0),
                  Color(0xFFFFF3CC),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFF8F5EC).withOpacity(0.76),
                ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: accent
              ? TaxiAppColors.buttonDarkTop.withOpacity(0.65)
              : TaxiAppColors.cardBorder.withOpacity(0.86),
          width: accent ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                TaxiAppColors.buttonDarkTop.withOpacity(accent ? 0.18 : 0.08),
            blurRadius: accent ? 34 : 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.72),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: child,
      ),
    );
  }
}

class ManagementSectionHeader extends StatelessWidget {
  const ManagementSectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD84D), Color(0xFFFFC200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TaxiAppColors.buttonDarkTop.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon ?? Icons.auto_awesome_rounded,
                color: TaxiAppColors.textStrong, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TaxiAppColors.textStrong,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    letterSpacing: -0.1,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: TaxiAppColors.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ManagementMetricPill extends StatelessWidget {
  const ManagementMetricPill({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = TaxiAppColors.textStrong,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            color.withOpacity(0.07),
            const Color(0xFFFFF8E0).withOpacity(0.62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withOpacity(0.72),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ManagementInfoRowCard extends StatelessWidget {
  const ManagementInfoRowCard({
    super.key,
    required this.icon,
    required this.content,
    this.trailing,
    this.iconBg = const Color(0xFFF5F1E8),
    this.iconColor = TaxiAppColors.textStrong,
  });

  final IconData icon;
  final Widget content;
  final Widget? trailing;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.96),
            const Color(0xFFFFF8E0).withOpacity(0.34),
            const Color(0xFFF5F1E8).withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.92)),
        boxShadow: [
          BoxShadow(
            color: TaxiAppColors.buttonDarkTop.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconBg, Colors.white.withOpacity(0.88)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(child: content),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ManagementStatusPill extends StatelessWidget {
  const ManagementStatusPill({
    super.key,
    required this.label,
    this.color = TaxiAppColors.textStrong,
    this.background,
  });

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ManagementEmptyState extends StatelessWidget {
  const ManagementEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 42, color: TaxiAppColors.textSoft.withOpacity(0.68)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TaxiAppColors.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagementResponsiveWrap extends StatelessWidget {
  const ManagementResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final width = isWide
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
