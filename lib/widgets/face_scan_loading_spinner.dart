import 'dart:math';
import 'package:flutter/material.dart';

/// Three-layer biometric spinner composed of:
/// 1. Dotted outer circumference with mirrored thin arc
/// 2. Pair of thick center arcs orbiting the face contour
/// 3. Concentric dotted loops near the center
class FaceScanLoadingSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const FaceScanLoadingSpinner({
    super.key,
    this.size = 200,
    this.color,
  });

  @override
  State<FaceScanLoadingSpinner> createState() => _FaceScanLoadingSpinnerState();
}

class _FaceScanLoadingSpinnerState extends State<FaceScanLoadingSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _outerRingController;
  late final AnimationController _middleArcsController;
  late final AnimationController _dotPulseController;

  @override
  void initState() {
    super.initState();
    // Outer ring rotates slowly
    _outerRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Middle arcs rotate faster (opposite direction)
    _middleArcsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Dot grid has a subtle pulse animation
    _dotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _outerRingController.dispose();
    _middleArcsController.dispose();
    _dotPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _outerRingController,
          _middleArcsController,
          _dotPulseController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: _FaceScanSpinnerPainter(
              outerRingRotation: _outerRingController.value,
              middleArcsRotation: _middleArcsController.value,
              dotPulse: _dotPulseController.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _FaceScanSpinnerPainter extends CustomPainter {
  final double outerRingRotation;
  final double middleArcsRotation;
  final double dotPulse;
  final Color color;

  _FaceScanSpinnerPainter({
    required this.outerRingRotation,
    required this.middleArcsRotation,
    required this.dotPulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Layer order: inner dots -> middle thick arcs -> dotted ring -> thin arc
    _drawInnerDotLoops(canvas, center, maxRadius * 0.55);
    _drawMiddleThickArcs(canvas, center, maxRadius * 0.7, middleArcsRotation);
    _drawOuterDottedRing(canvas, center, maxRadius * 0.88, outerRingRotation);
    _drawOuterThinArc(canvas, center, maxRadius * 0.95, outerRingRotation);
  }

  /// Draws two tidy dotted rings plus a floating dot band between them.
  void _drawInnerDotLoops(Canvas canvas, Offset center, double radius) {
    final loopPaint = Paint()
      ..color = color.withValues(alpha: 0.45 + dotPulse * 0.25)
      ..style = PaintingStyle.fill;

    final innerLoopRadius = radius * 0.55;
    final midLoopRadius = radius * 0.78;
    final bridgeRadius = (innerLoopRadius + midLoopRadius) / 2;

    _drawDotRing(canvas, center, innerLoopRadius, 48, 2.4, loopPaint);
    _drawDotRing(canvas, center, midLoopRadius, 60, 2.1, loopPaint);

    // Floating dots between the two loops for extra detail
    final bridgePaint = Paint()
      ..color = color.withValues(alpha: 0.35 + dotPulse * 0.2)
      ..style = PaintingStyle.fill;
    _drawDotRing(canvas, center, bridgeRadius, 24, 1.6, bridgePaint);
  }

  void _drawDotRing(Canvas canvas, Offset center, double radius, int count,
      double dotSize, Paint paint) {
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i) / count;
      final offset = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawCircle(offset, dotSize, paint);
    }
  }

  /// Draws two thick arc segments that orbit around the face area.
  void _drawMiddleThickArcs(
      Canvas canvas, Offset center, double radius, double rotation) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = radius * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arcCount = 2;
    final baseAngle = -2 * pi * rotation;
    const sweep = pi / 2.2;

    for (int i = 0; i < arcCount; i++) {
      final startAngle = baseAngle + i * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        arcPaint,
      );
    }
  }

  /// Draws an outer dotted circumference. Appears dotted even when static.
  void _drawOuterDottedRing(
      Canvas canvas, Offset center, double radius, double rotation) {
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashCount = 120;
    const dashAngle = (2 * pi) / (dashCount * 2);
    final rotationAngle = 2 * pi * rotation;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = rotationAngle + (i * 2 * dashAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.65,
        false,
        dotPaint,
      );
    }
  }

  /// Adds a thin arc sitting outside the dotted ring that mirrors on both sides.
  void _drawOuterThinArc(
      Canvas canvas, Offset center, double radius, double rotation) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rotationAngle = 2 * pi * rotation;
    const arcSweep = pi / 3.2;

    // Draw symmetrical arcs on left/right sides.
    for (final direction in [0, pi]) {
      final startAngle = rotationAngle + direction - arcSweep / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcSweep,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FaceScanSpinnerPainter oldDelegate) {
    return oldDelegate.outerRingRotation != outerRingRotation ||
        oldDelegate.middleArcsRotation != middleArcsRotation ||
        oldDelegate.dotPulse != dotPulse;
  }
}
