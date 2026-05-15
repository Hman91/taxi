import 'package:flutter/material.dart';

import 'owner_colors.dart';

InputDecoration ownerFieldDecoration(String label,
    {IconData? icon, String? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: OwnerColors.textMid, fontSize: 13),
    prefixIcon:
        icon != null ? Icon(icon, color: OwnerColors.charcoal, size: 18) : null,
    suffixText: suffix,
    filled: true,
    fillColor: OwnerColors.surfaceAlt,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: OwnerColors.border, width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: OwnerColors.yellow, width: 2),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
