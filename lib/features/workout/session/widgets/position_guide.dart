import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PositionGuide — where to stand relative to the phone.
// Drawn with CustomPainter: the project ships no illustration assets.
// ─────────────────────────────────────────────────────────────────────────────

class PositionGuide extends StatelessWidget {
  const PositionGuide({super.key});

  static const double _height = 190.0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _PositionGuidePainter()),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Text(
                'Full body in frame',
                style: tt.labelMedium?.copyWith(color: AppColors.accent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text('2 – 3 m away', style: tt.labelMedium),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _PositionGuidePainter extends CustomPainter {
  const _PositionGuidePainter();

  // Field of view half-angle of the drawn camera cone.
  static const double _fovHalfAngle = math.pi / 6; // 30°

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.80;

    // The FOV cone reaches past the top edge — keep it inside the card.
    canvas.clipRect(Offset.zero & size);

    _paintGround(canvas, w, h, groundY);
    final lens = _paintPhone(canvas, w, h, groundY);
    _paintFovCone(canvas, w, lens);
    _paintFigure(canvas, w, h, groundY);
    _paintDistanceHint(canvas, w, h, groundY);
  }

  void _paintGround(Canvas canvas, double w, double h, double groundY) {
    final paint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Bottom half of a wide ellipse — reads as a floor in perspective.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, groundY),
        width: w * 0.92,
        height: h * 0.14,
      ),
      0,
      math.pi,
      false,
      paint,
    );
  }

  /// Draws the phone standing on the ground and returns its lens position.
  Offset _paintPhone(Canvas canvas, double w, double h, double groundY) {
    final phoneW = w * 0.075;
    final phoneH = h * 0.34;
    final rect = Rect.fromLTWH(w * 0.13, groundY - phoneH, phoneW, phoneH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    canvas.drawRRect(rrect, Paint()..color = AppColors.surfaceElevated);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.borderMedium
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final lens = Offset(rect.center.dx, rect.top + h * 0.035);
    canvas.drawCircle(lens, h * 0.014, Paint()..color = AppColors.accent);
    return lens;
  }

  void _paintFovCone(Canvas canvas, double w, Offset lens) {
    final reach = w - lens.dx;
    final upper = Offset(
      lens.dx + reach * math.cos(-_fovHalfAngle),
      lens.dy + reach * math.sin(-_fovHalfAngle),
    );
    final lower = Offset(
      lens.dx + reach * math.cos(_fovHalfAngle),
      lens.dy + reach * math.sin(_fovHalfAngle),
    );

    final cone = Path()
      ..moveTo(lens.dx, lens.dy)
      ..lineTo(upper.dx, upper.dy)
      ..lineTo(lower.dx, lower.dy)
      ..close();

    canvas.drawPath(
      cone,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.accentGlow, AppColors.transparent],
        ).createShader(Rect.fromLTRB(lens.dx, upper.dy, w, lower.dy)),
    );
  }

  void _paintFigure(Canvas canvas, double w, double h, double groundY) {
    final x = w * 0.68;
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final headR = h * 0.05;
    final shoulderY = groundY - h * 0.46;
    final hipY = groundY - h * 0.26;

    canvas.drawCircle(Offset(x, groundY - h * 0.56), headR, paint);
    canvas.drawLine(Offset(x, groundY - h * 0.50), Offset(x, hipY), paint);

    // Arms
    canvas.drawLine(
      Offset(x, shoulderY),
      Offset(x - w * 0.055, groundY - h * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(x, shoulderY),
      Offset(x + w * 0.055, groundY - h * 0.32),
      paint,
    );

    // Legs
    canvas.drawLine(Offset(x, hipY), Offset(x - w * 0.045, groundY), paint);
    canvas.drawLine(Offset(x, hipY), Offset(x + w * 0.045, groundY), paint);
  }

  void _paintDistanceHint(Canvas canvas, double w, double h, double groundY) {
    final y = groundY + h * 0.09;
    final startX = w * 0.21;
    final endX = w * 0.68;

    final paint = Paint()
      ..color = AppColors.textDisabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dash = 5.0;
    const gap = 4.0;
    for (var x = startX; x < endX; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, endX), y),
        paint,
      );
    }

    // End ticks
    final tick = h * 0.03;
    canvas.drawLine(Offset(startX, y - tick), Offset(startX, y + tick), paint);
    canvas.drawLine(Offset(endX, y - tick), Offset(endX, y + tick), paint);
  }

  @override
  bool shouldRepaint(covariant _PositionGuidePainter oldDelegate) => false;
}
