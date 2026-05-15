import 'package:flutter/material.dart';

import '../../widgets/management_platform_ui.dart';
import 'owner_colors.dart';

/// Section heading with yellow accent (Owner / Operator management style).
class OwnerSectionHead extends StatelessWidget {
  const OwnerSectionHead(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ManagementSectionHeader(
        title,
        subtitle: subtitle,
        trailing: trailing,
      );
}

/// Module card container for Owner screens.
class OwnerModule extends StatelessWidget {
  const OwnerModule({
    super.key,
    required this.child,
    this.padding = 16,
    this.accent = false,
  });

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

/// Metric pill used in Owner dashboards.
class OwnerStatChip extends StatelessWidget {
  const OwnerStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = OwnerColors.charcoal,
  });

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
