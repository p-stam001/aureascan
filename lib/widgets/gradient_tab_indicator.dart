import 'package:flutter/material.dart';

class GradientTabIndicator extends Decoration {
  final Gradient gradient;
  final double indicatorHeight;
  final double underlineWidth;

  const GradientTabIndicator({
    required this.gradient,
    this.indicatorHeight = 4,
    this.underlineWidth = 70, // Default underline width
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientPainter(this, gradient, indicatorHeight, underlineWidth);
  }
}

class _GradientPainter extends BoxPainter {
  final GradientTabIndicator decoration;
  final Gradient gradient;
  final double indicatorHeight;
  final double underlineWidth;

  _GradientPainter(this.decoration, this.gradient, this.indicatorHeight, this.underlineWidth);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    if (configuration.size == null) return;
    final double tabWidth = configuration.size!.width;
    final double tabHeight = configuration.size!.height;

    // Center the underline
    final double left = offset.dx + (tabWidth - underlineWidth) / 2;
    final double top = offset.dy + tabHeight - indicatorHeight;
    final Rect rect = Rect.fromLTWH(left, top, underlineWidth, indicatorHeight);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }
} 