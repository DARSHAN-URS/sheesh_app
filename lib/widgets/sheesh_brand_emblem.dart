import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable Sheesh Brand Emblem featuring the signature arch,
/// 4-pointed celestial sparkle star, high-contrast serif "Sheश",
/// and the founder-approved tagline: "WOMEN CREATE, COMMUNITIES GROW."
class SheeshBrandEmblem extends StatelessWidget {
  final double scale;
  final bool showTagline;
  final bool animateStar;

  const SheeshBrandEmblem({
    super.key,
    this.scale = 1.0,
    this.showTagline = true,
    this.animateStar = true,
  });

  @override
  Widget build(BuildContext context) {
    final archWidth = 220.0 * scale;
    final archHeight = 185.0 * scale;
    final starWidth = 32.0 * scale;
    final starHeight = 42.0 * scale;
    final starTop = 26.0 * scale;
    final textBottom = 18.0 * scale;
    final fontSize = 52.0 * scale;
    final taglineSize = 11.5 * scale;
    final gap = 16.0 * scale;

    Widget starWidget = SizedBox(
      width: starWidth,
      height: starHeight,
      child: const CustomPaint(
        painter: StarSparklePainter(color: Color(0xFFD64438)),
      ),
    );

    if (animateStar) {
      starWidget = starWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1.06, 1.06),
            duration: 1600.ms,
            curve: Curves.easeInOut,
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: archWidth,
          height: archHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Arch Frame
              Positioned.fill(
                child: CustomPaint(
                  painter: SheeshArchPainter(
                    strokeColor: const Color(0xFFC83C34),
                    strokeWidth: 2.2 * scale,
                  ),
                ),
              ),

              // Apex 4-Point Celestial Star Sparkle
              Positioned(
                top: starTop,
                child: starWidget,
              ),

              // Wordmark: She + श
              Positioned(
                bottom: textBottom,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'She',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF261017),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'श',
                      style: GoogleFonts.rozhaOne(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD64438),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (showTagline) ...[
          SizedBox(height: gap),
          Column(
            children: [
              Text(
                'WOMEN CREATE,',
                style: GoogleFonts.montserrat(
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: const Color(0xFF522533),
                  height: 1.3,
                ),
              ),
              SizedBox(height: 2.0 * scale),
              Text(
                'COMMUNITIES GROW.',
                style: GoogleFonts.montserrat(
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: const Color(0xFF522533),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Draws the elegant red arch frame around the logo
class SheeshArchPainter extends CustomPainter {
  final Color strokeColor;
  final double strokeWidth;

  const SheeshArchPainter({
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, r);
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(w, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SheeshArchPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Draws the sharp 4-pointed celestial sparkle star at the apex of the arch
class StarSparklePainter extends CustomPainter {
  final Color color;

  const StarSparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;

    final path = Path();
    path.moveTo(cx, cy - ry);
    path.quadraticBezierTo(cx + rx * 0.16, cy - ry * 0.16, cx + rx, cy);
    path.quadraticBezierTo(cx + rx * 0.16, cy + ry * 0.16, cx, cy + ry);
    path.quadraticBezierTo(cx - rx * 0.16, cy + ry * 0.16, cx - rx, cy);
    path.quadraticBezierTo(cx - rx * 0.16, cy - ry * 0.16, cx, cy - ry);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StarSparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

