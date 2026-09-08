import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable Google Sign-In button adhering to brand guidelines and Sheesh theme.
class GoogleSignInButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    this.text = 'Continue with Google',
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleLogo(size: 22),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Official 4-color Google 'G' Logo widget.
/// Renders from asset bundle with high-fidelity vector fallback.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        size: Size(size, size),
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerR = size.width * 0.46;
    final double innerR = size.width * 0.26;
    final Rect outerRect = Rect.fromCircle(center: Offset(cx, cy), radius: outerR);
    final Rect innerRect = Rect.fromCircle(center: Offset(cx, cy), radius: innerR);

    // Official Google Brand Colors
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;

    // Red: Top arc
    _drawArcSegment(canvas, outerRect, innerRect, -math.pi * 0.75, math.pi * 0.55, redPaint);

    // Yellow: Bottom-left arc
    _drawArcSegment(canvas, outerRect, innerRect, -math.pi * 1.25, math.pi * 0.5, yellowPaint);

    // Green: Bottom arc
    _drawArcSegment(canvas, outerRect, innerRect, math.pi * 0.25, math.pi * 0.55, greenPaint);

    // Blue: Right bar & arc
    _drawArcSegment(canvas, outerRect, innerRect, -math.pi * 0.2, math.pi * 0.45, bluePaint);

    // Blue horizontal bar
    final barHeight = size.height * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(cx - size.width * 0.05, cy - barHeight / 2, outerR + size.width * 0.05, barHeight),
      bluePaint,
    );
  }

  void _drawArcSegment(
    Canvas canvas,
    Rect outerRect,
    Rect innerRect,
    double startAngle,
    double sweepAngle,
    Paint paint,
  ) {
    final path = Path()
      ..arcTo(outerRect, startAngle, sweepAngle, false)
      ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
