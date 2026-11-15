import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConfettiBurst — a one-shot celebration over the summary screen. Pieces fan
// up out of the header, fall under gravity and fade out, then the widget paints
// nothing. It never takes touches, and it stays off entirely when the user has
// asked the OS for reduced motion.
// ─────────────────────────────────────────────────────────────────────────────

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _particleCount = 70;

  /// Fixed so the burst looks the same every time — it is decoration, and a
  /// stable shape is easier to tune than a random one.
  static const _seed = 7;

  static const _colors = [
    AppColors.accent,
    AppColors.accentBlue,
    AppColors.warning,
    AppColors.textPrimary,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _ConfettiPainter.duration,
  );

  late final List<_Particle> _particles = _buildParticles();

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Started here rather than in initState: the reduced-motion setting comes
    // from MediaQuery, which initState cannot read.
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() {
    final random = math.Random(_seed);
    double between(double min, double max) =>
        min + random.nextDouble() * (max - min);

    return List.generate(_particleCount, (i) {
      // An upward fan: straight up is -π/2, the spread keeps pieces off the
      // horizontal so none skim sideways across the stats.
      final angle = between(-math.pi + _ConfettiPainter.fanInset,
          -_ConfettiPainter.fanInset);
      final speed = between(
          _ConfettiPainter.minSpeed, _ConfettiPainter.maxSpeed);
      return _Particle(
        originX: between(
            _ConfettiPainter.minOriginX, _ConfettiPainter.maxOriginX),
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        spin: between(-_ConfettiPainter.maxSpin, _ConfettiPainter.maxSpin),
        size: between(
            _ConfettiPainter.minPieceSize, _ConfettiPainter.maxPieceSize),
        color: _colors[i % _colors.length],
        round: i % 3 == 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isCompleted) return const SizedBox.shrink();
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.originX,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  /// Launch point as a fraction of the canvas width.
  final double originX;

  /// Launch velocity in canvas short-sides per second.
  final double vx;
  final double vy;

  /// Radians per second.
  final double spin;

  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;

  /// 0–1 across [duration].
  final double progress;

  static const duration = Duration(milliseconds: 2600);

  // ── Launch ────────────────────────────────────────────────────────────────
  /// Height of the launch point — roughly the header icon — as a fraction of
  /// the canvas height.
  static const double originY = 0.12;
  static const double minOriginX = 0.4;
  static const double maxOriginX = 0.6;

  /// Keeps launch angles this far (radians) off the horizontal.
  static const double fanInset = 0.35;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 1.3;

  // ── Flight ────────────────────────────────────────────────────────────────
  /// Canvas short-sides per second squared.
  static const double gravity = 1.6;
  static const double maxSpin = 8.0;

  /// Fraction of the run after which pieces start fading out.
  static const double fadeStart = 0.65;

  // ── Pieces ────────────────────────────────────────────────────────────────
  static const double minPieceSize = 5.0;
  static const double maxPieceSize = 10.0;

  /// Rectangular pieces are this much shorter than they are wide.
  static const double stripAspect = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final seconds =
        progress * duration.inMilliseconds / Duration.millisecondsPerSecond;
    final opacity = progress < fadeStart
        ? 1.0
        : (1 - (progress - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);

    final paint = Paint();
    for (final p in particles) {
      final dx = p.vx * seconds * unit;
      final dy = (p.vy * seconds + 0.5 * gravity * seconds * seconds) * unit;
      final position =
          Offset(size.width * p.originX + dx, size.height * originY + dy);
      if (position.dy > size.height) continue;

      paint.color = p.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(p.spin * seconds);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * stripAspect,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
