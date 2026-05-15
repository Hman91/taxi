import 'package:flutter/material.dart';

import 'owner_colors.dart';

/// Number of primary destinations in the Owner portal (see [_OwnerScreenState] tab order).
const int kOwnerPortalTabCount = 9;

/// Desktop / tablet: vertical rail synced with [TabController].
class OwnerNavigationRail extends StatelessWidget {
  const OwnerNavigationRail({
    super.key,
    required this.controller,
    required this.destinations,
  });

  final TabController controller;
  final List<NavigationRailDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return NavigationRail(
          backgroundColor: OwnerColors.charcoal,
          selectedIndex: controller.index,
          onDestinationSelected: (i) {
            if (i == controller.index) return;
            controller.animateTo(i);
          },
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: OwnerColors.yellow, size: 22),
          unselectedIconTheme: const IconThemeData(color: Colors.white38, size: 20),
          selectedLabelTextStyle: const TextStyle(
            color: OwnerColors.yellow,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          indicatorColor: OwnerColors.yellow.withValues(alpha: 0.22),
          destinations: destinations,
        );
      },
    );
  }
}
