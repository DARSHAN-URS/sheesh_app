import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints the botanical foliage leaves in warm coral, peach, and deep wine,
/// matching the signature Sheesh artisan brand identity.
class BotanicalLeavesPainter extends CustomPainter {
  const BotanicalLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Helper to draw a single botanical leaf with optional spine vein ──
    void drawLeaf({
      required Offset base,
      required Offset tip,
      required double leftBulge,
      required double rightBulge,
      required Color color,
      Color? tipColor,
      Color? veinColor,
      double veinLength = 0.88,
    }) {
      final dx = tip.dx - base.dx;
      final dy = tip.dy - base.dy;
      final normalX = -dy;
      final normalY = dx;
      final len = math.sqrt(normalX * normalX + normalY * normalY);
      if (len == 0) return;
      final nx = normalX / len;
      final ny = normalY / len;

      final p1 = Offset(
        base.dx + dx * 0.32 + nx * leftBulge,
        base.dy + dy * 0.32 + ny * leftBulge,
      );
      final p2 = Offset(
        base.dx + dx * 0.76 + nx * (leftBulge * 0.80),
        base.dy + dy * 0.76 + ny * (leftBulge * 0.80),
      );

      final p3 = Offset(
        base.dx + dx * 0.76 - nx * (rightBulge * 0.80),
        base.dy + dy * 0.76 - ny * (rightBulge * 0.80),
      );
      final p4 = Offset(
        base.dx + dx * 0.32 - nx * rightBulge,
        base.dy + dy * 0.32 - ny * rightBulge,
      );

      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, tip.dx, tip.dy)
        ..cubicTo(p3.dx, p3.dy, p4.dx, p4.dy, base.dx, base.dy)
        ..close();

      final paint = Paint()..style = PaintingStyle.fill;
      if (tipColor != null) {
        paint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color, tipColor],
        ).createShader(Rect.fromPoints(base, tip));
      } else {
        paint.color = color;
      }
      canvas.drawPath(path, paint);

      // Spine vein
      if (veinColor != null) {
        final veinPaint = Paint()
          ..color = veinColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;

        final midPoint = Offset(
          base.dx + dx * 0.5 + nx * ((leftBulge - rightBulge) * 0.12),
          base.dy + dy * 0.5 + ny * ((leftBulge - rightBulge) * 0.12),
        );
        final veinTip = Offset(
          base.dx + dx * veinLength,
          base.dy + dy * veinLength,
        );

        final veinPath = Path()
          ..moveTo(base.dx + dx * 0.08, base.dy + dy * 0.08)
          ..quadraticBezierTo(midPoint.dx, midPoint.dy, veinTip.dx, veinTip.dy);

        canvas.drawPath(veinPath, veinPaint);
      }
    }

    // ── Soft Bottom Mound / Horizon ──
    final moundPaint = Paint()
      ..color = const Color(0xFFFCEFE7).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final moundPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.28, h * 0.72, w * 0.52, h * 0.78)
      ..quadraticBezierTo(w * 0.78, h * 0.85, w, h * 0.74)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(moundPath, moundPaint);

    // ──────────────────────────────────────────────
    // LEFT BOTANICAL CLUSTER
    // ──────────────────────────────────────────────
    // 1. Far-left background pale blush leaf
    drawLeaf(
      base: Offset(w * -0.02, h * 0.88),
      tip: Offset(w * 0.10, h * 0.16),
      leftBulge: 18,
      rightBulge: 24,
      color: const Color(0xFFF7C5BA).withValues(alpha: 0.85),
      tipColor: const Color(0xFFFCE1DB),
    );

    // 2. Upright soft peach leaf
    drawLeaf(
      base: Offset(w * 0.02, h * 0.94),
      tip: Offset(w * 0.17, h * 0.26),
      leftBulge: 24,
      rightBulge: 26,
      color: const Color(0xFFF19D90),
      tipColor: const Color(0xFFF9C0B7),
      veinColor: const Color(0xFFFDE8E3),
    );

    // 3. Tall coral-rose leaf curving upward along left edge
    drawLeaf(
      base: Offset(w * 0.03, h * 0.97),
      tip: Offset(w * 0.14, h * 0.34),
      leftBulge: 22,
      rightBulge: 28,
      color: const Color(0xFFE2655A),
      tipColor: const Color(0xFFEC7E74),
      veinColor: const Color(0xFFFBD7D1),
    );

    // 4. Large hero coral-red leaf pointing diagonally up-right toward center
    drawLeaf(
      base: Offset(w * 0.05, h * 1.0),
      tip: Offset(w * 0.44, h * 0.52),
      leftBulge: 38,
      rightBulge: 38,
      color: const Color(0xFFD64D43),
      tipColor: const Color(0xFFE8695F),
      veinColor: const Color(0xFFFDD0C8),
      veinLength: 0.92,
    );

    // 5. Lower inner coral leaf
    drawLeaf(
      base: Offset(w * 0.07, h * 1.0),
      tip: Offset(w * 0.28, h * 0.72),
      leftBulge: 24,
      rightBulge: 24,
      color: const Color(0xFFDE5D52),
      tipColor: const Color(0xFFEB766C),
      veinColor: const Color(0xFFFAD7D1),
    );

    // 6. Deep dark wine accent leaf at base
    drawLeaf(
      base: Offset(w * 0.02, h * 1.0),
      tip: Offset(w * 0.15, h * 0.76),
      leftBulge: 20,
      rightBulge: 20,
      color: const Color(0xFF5D1726),
      tipColor: const Color(0xFF731F31),
    );

    // ──────────────────────────────────────────────
    // RIGHT BOTANICAL CLUSTER
    // ──────────────────────────────────────────────
    // 1. Background soft blush petal
    drawLeaf(
      base: Offset(w * 1.02, h * 0.85),
      tip: Offset(w * 0.89, h * 0.14),
      leftBulge: 22,
      rightBulge: 18,
      color: const Color(0xFFF8C8BD).withValues(alpha: 0.85),
      tipColor: const Color(0xFFFDE4DE),
    );

    // 2. Tall graceful soft coral-peach leaf
    drawLeaf(
      base: Offset(w * 0.98, h * 0.92),
      tip: Offset(w * 0.81, h * 0.24),
      leftBulge: 26,
      rightBulge: 24,
      color: const Color(0xFFEE998C),
      tipColor: const Color(0xFFF8BEB4),
      veinColor: const Color(0xFFFCE6E2),
    );

    // 3. Main center-leaning coral leaf
    drawLeaf(
      base: Offset(w * 0.96, h * 0.98),
      tip: Offset(w * 0.58, h * 0.50),
      leftBulge: 36,
      rightBulge: 34,
      color: const Color(0xFFDA5449),
      tipColor: const Color(0xFFE86D63),
      veinColor: const Color(0xFFFDD2CA),
      veinLength: 0.92,
    );

    // 4. Mid warm rose leaf
    drawLeaf(
      base: Offset(w * 0.94, h * 1.0),
      tip: Offset(w * 0.68, h * 0.68),
      leftBulge: 24,
      rightBulge: 24,
      color: const Color(0xFFCD453D),
      tipColor: const Color(0xFFDE5D55),
      veinColor: const Color(0xFFFCD5CE),
    );

    // 5. Deep wine / dark burgundy leaf at bottom-right corner
    drawLeaf(
      base: Offset(w * 0.90, h * 1.0),
      tip: Offset(w * 0.72, h * 0.78),
      leftBulge: 22,
      rightBulge: 22,
      color: const Color(0xFF4C1320),
      tipColor: const Color(0xFF621A2B),
    );
  }

  @override
  bool shouldRepaint(covariant BotanicalLeavesPainter oldDelegate) => false;
}

