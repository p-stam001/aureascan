import 'dart:math' as math;
import 'package:flutter/material.dart';

class TaskProcessingLoadingScreen extends StatelessWidget {
  final String message;
  final String? subtitle;

  const TaskProcessingLoadingScreen({
    super.key,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dark background with geometric shapes
          const _DarkBackgroundWithShapes(),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dot spinner
                const DotSpinner(
                  activeColor: Colors.white,
                  inactiveColor: Color(0xFF6B6B6B), // Muted brownish-grey
                  dotCount: 12,
                  dotSize: 8.0,
                  radius: 40.0,
                ),
                const SizedBox(height: 40),
                // Message
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dot Spinner Widget
class DotSpinner extends StatefulWidget {
  final Color activeColor;
  final Color inactiveColor;
  final int dotCount;
  final double dotSize;
  final double radius;

  const DotSpinner({
    super.key,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF6B6B6B),
    this.dotCount = 12,
    this.dotSize = 8.0,
    this.radius = 40.0,
  });

  @override
  State<DotSpinner> createState() => _DotSpinnerState();
}

class _DotSpinnerState extends State<DotSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(
            (widget.radius + widget.dotSize) * 2,
            (widget.radius + widget.dotSize) * 2,
          ),
          painter: _DotSpinnerPainter(
            progress: _controller.value,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            dotCount: widget.dotCount,
            dotSize: widget.dotSize,
            radius: widget.radius,
          ),
        );
      },
    );
  }
}

class _DotSpinnerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final int dotCount;
  final double dotSize;
  final double radius;

  _DotSpinnerPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotCount,
    required this.dotSize,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (2 * math.pi) / dotCount;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * angleStep) - (math.pi / 2); // Start from top
      final dotAngle = angle + (progress * 2 * math.pi); // Rotate

      final x = center.dx + radius * math.cos(dotAngle);
      final y = center.dy + radius * math.sin(dotAngle);

      // Calculate which dot should be bright (one dot at a time)
      final activeIndex = (progress * dotCount).floor() % dotCount;
      final isActive = i == activeIndex;

      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_DotSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Background with geometric shapes
class _DarkBackgroundWithShapes extends StatelessWidget {
  const _DarkBackgroundWithShapes();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DarkBackgroundPainter(),
      size: Size.infinite,
    );
  }
}

class _DarkBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base dark grey background
    final basePaint = Paint()
      ..color = const Color(0xFF2A2A2A) // Dark grey
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Geometric shape in upper-right (triangle/trapezoid)
    final shapePath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.85, size.height * 0.2)
      ..close();

    final shapePaint = Paint()
      ..color = const Color(0xFF1F1F1F)
          .withValues(alpha: 0.6) // Darker, slightly purple-tinted
      ..style = PaintingStyle.fill;

    canvas.drawPath(shapePath, shapePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
