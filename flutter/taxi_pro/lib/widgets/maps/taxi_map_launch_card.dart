import 'package:flutter/material.dart';

import '../../config.dart';

/// Premium entry tile — opens [LiveTripMapScreen] from parent via [onOpen].
class TaxiMapLaunchCard extends StatelessWidget {
  const TaxiMapLaunchCard({
    super.key,
    required this.onOpen,
    required this.title,
    required this.subtitle,
    this.enabled = true,
  });

  final VoidCallback onOpen;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ready = enabled && isGoogleMapsPlatformSupported;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ready ? onOpen : null,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ready
                  ? const [
                      Color(0xFF151a2e),
                      Color(0xFF0c1020),
                      Color(0xFF1a1408),
                    ]
                  : [
                      const Color(0xFF3a3a3a),
                      const Color(0xFF2a2a2a),
                    ],
            ),
            border: Border.all(
              color: ready
                  ? const Color(0x66FFC200)
                  : Colors.white.withOpacity(0.12),
              width: 1.4,
            ),
            boxShadow: [
              if (ready)
                BoxShadow(
                  color: const Color(0xFFFFC200).withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD84D), Color(0xFFFFC200)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC200).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF111111),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(ready ? 1 : 0.55),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ready
                            ? subtitle
                            : 'Configure GOOGLE_MAPS_API_KEY for Android/iOS.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(ready ? 0.85 : 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
