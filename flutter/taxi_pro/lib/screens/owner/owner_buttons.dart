import 'package:flutter/material.dart';

import 'owner_colors.dart';

class OwnerYellowButton extends StatelessWidget {
  const OwnerYellowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final child = Container(
      height: small ? 38 : 48,
      width: fullWidth ? double.infinity : null,
      padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: disabled ? OwnerColors.yellowSoft : OwnerColors.yellow,
        borderRadius: BorderRadius.circular(50),
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: OwnerColors.yellow.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: OwnerColors.charcoal, size: small ? 14 : 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: OwnerColors.charcoal,
                fontWeight: FontWeight.w900,
                fontSize: small ? 12 : 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
    return GestureDetector(onTap: onPressed, child: child);
  }
}

class OwnerDarkButton extends StatelessWidget {
  const OwnerDarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.fullWidth = true,
  });

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
          color: disabled ? const Color(0xFFCCCCCC) : OwnerColors.charcoal,
          borderRadius: BorderRadius.circular(50),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: OwnerColors.charcoal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: small ? 14 : 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: small ? 12 : 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
