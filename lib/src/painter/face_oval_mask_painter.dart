import 'package:flutter/material.dart';

/// Painter that draws a dark dimmed overlay mask outside a central oval/circle camera viewport.
class FaceOvalMaskPainter extends CustomPainter {
  final Color overlayColor;

  FaceOvalMaskPainter({
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final ovalPath = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant FaceOvalMaskPainter oldDelegate) {
    return oldDelegate.overlayColor != overlayColor;
  }
}
