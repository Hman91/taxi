import 'package:flutter/material.dart';

class VoomLogo extends StatelessWidget {
  const VoomLogo({
    super.key,
    this.height = 56,
    this.topPadding = 0,
  });

  final double height;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Center(
        child: Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E0),
            borderRadius: BorderRadius.circular(height * 0.28),
            border: Border.all(color: const Color(0xFFE6A800), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/branding/voom_logo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_taxi_rounded,
              size: 30,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }
}
