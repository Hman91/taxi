import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Airport, zone, or restaurant — same footprint for consistent map density.
enum ReservationMarkerKind { airport, zone, restaurant }

/// Compact “floating card + tail” marker bitmaps, cached.
abstract final class ReservationBubbleMarker {
  ReservationBubbleMarker._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static const double _logicalW = 88;
  static const double _logicalH = 54;

  static String _normBadge(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '••';
    if (t.length <= 3) return t.toUpperCase();
    return t.substring(0, 3).toUpperCase();
  }

  static Future<BitmapDescriptor> build({
    required String cacheKey,
    required ReservationMarkerKind markerKind,
    required String badge,
    required bool selected,
  }) async {
    final k = cacheKey;
    final hit = _cache[k];
    if (hit != null) return hit;
    final bytes = await _paintPng(
      markerKind: markerKind,
      badge: _normBadge(badge),
      selected: selected,
    );
    final bd = BitmapDescriptor.bytes(
      bytes,
      width: _logicalW,
      height: _logicalH,
    );
    _cache[k] = bd;
    return bd;
  }

  static Future<Uint8List> _paintPng({
    required ReservationMarkerKind markerKind,
    required String badge,
    required bool selected,
  }) async {
    const logicalW = _logicalW;
    const logicalH = _logicalH;
    const dpr = 3.0;
    final w = (logicalW * dpr).round();
    final h = (logicalH * dpr).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 3, logicalW - 10, logicalH - 20),
      const Radius.circular(12),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawRRect(bubbleRect.shift(const Offset(0, 1.5)), shadowPaint);

    final fill = Paint()..color = Colors.white;
    canvas.drawRRect(bubbleRect, fill);

    if (selected) {
      final border = Paint()
        ..color = const Color(0xFFFFC200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawRRect(bubbleRect.deflate(0.8), border);
    } else {
      final border = Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(bubbleRect.deflate(0.5), border);
    }

    final tail = Path()
      ..moveTo(logicalW / 2 - 6, logicalH - 17)
      ..lineTo(logicalW / 2 + 6, logicalH - 17)
      ..lineTo(logicalW / 2, logicalH - 3)
      ..close();
    canvas.drawPath(tail, fill);
    canvas.drawPath(
      tail,
      Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final Color accent;
    final String glyph;
    switch (markerKind) {
      case ReservationMarkerKind.airport:
        accent = const Color(0xFF1565C0);
        glyph = '✈';
      case ReservationMarkerKind.zone:
        accent = const Color(0xFFE65100);
        glyph = '★';
      case ReservationMarkerKind.restaurant:
        accent = const Color(0xFF00695C);
        glyph = '🍴';
    }

    canvas.drawCircle(const Offset(19, 17), 8.5, Paint()..color = accent);

    final iconTp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: Colors.white,
          fontSize: markerKind == ReservationMarkerKind.restaurant ? 10 : 11,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconTp.paint(canvas, Offset(19 - iconTp.width / 2, 17 - iconTp.height / 2));

    final labelTp = TextPainter(
      text: TextSpan(
        text: badge,
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontSize: selected ? 12 : 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: logicalW - 40);
    labelTp.paint(canvas, Offset(32, 13.5 - labelTp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }
}
