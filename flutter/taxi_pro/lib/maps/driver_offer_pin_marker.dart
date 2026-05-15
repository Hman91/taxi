import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Premium pickup / drop-off pin bitmaps for driver offer map (cached).
abstract final class DriverOfferPinMarker {
  DriverOfferPinMarker._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> pickup() =>
      _get('pickup', const Color(0xFF6D28D9), const Color(0xFF4C1D95), 'A');

  static Future<BitmapDescriptor> destination() =>
      _get('destination', const Color(0xFFE65100), const Color(0xFFBF360C), 'B');

  static Future<BitmapDescriptor> _get(
    String key,
    Color top,
    Color rim,
    String letter,
  ) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final bytes = await _paintPng(top: top, rim: rim, letter: letter);
    const logicalW = 52.0;
    const logicalH = 62.0;
    final bd = BitmapDescriptor.bytes(bytes, width: logicalW, height: logicalH);
    _cache[key] = bd;
    return bd;
  }

  static Future<Uint8List> _paintPng({
    required Color top,
    required Color rim,
    required String letter,
  }) async {
    const logicalW = 52.0;
    const logicalH = 62.0;
    const dpr = 3.0;
    final w = (logicalW * dpr).round();
    final h = (logicalH * dpr).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final cx = logicalW / 2;
    const headR = 17.0;
    final headCenter = Offset(cx, 18);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(headCenter.translate(0, 1.2), headR + 1, shadow);

    final headGrad = Paint()
      ..shader = RadialGradient(
        colors: [top, Color.lerp(top, rim, 0.35)!],
        stops: const [0.35, 1],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headR));
    canvas.drawCircle(headCenter, headR, headGrad);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(headCenter, headR - 1, rimPaint);

    final tail = Path()
      ..moveTo(cx - 9, 30)
      ..quadraticBezierTo(cx - 11, 40, cx, logicalH - 6)
      ..quadraticBezierTo(cx + 11, 40, cx + 9, 30)
      ..close();
    final tailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, rim],
      ).createShader(Rect.fromLTWH(0, 28, logicalW, logicalH));
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(
      tail,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 18 - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }
}
