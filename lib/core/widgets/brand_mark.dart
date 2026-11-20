import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The Rasael envelope with its heart seal, drawn rather than shipped as a
/// bitmap so it stays sharp at any size and follows the theme.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.color});

  /// Width of the envelope; height follows the logo's 4:3 proportion.
  final double size;

  /// Envelope stroke. Defaults to the accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size * 0.75),
        painter: _EnvelopePainter(stroke: color ?? c.accent, seal: c.seal),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({required this.stroke, required this.seal});

  final Color stroke;
  final Color seal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = (w / 14).clamp(1.25, 3.0);
    final inset = line / 2;

    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = line
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - line, h - line),
      Radius.circular(w * 0.09),
    );
    canvas.drawRRect(body, paint);

    // The flap meets just below the middle, where the seal sits.
    final tip = Offset(w / 2, h * 0.56);
    canvas.drawPath(
      Path()
        ..moveTo(inset + w * 0.04, inset + h * 0.06)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(w - inset - w * 0.04, inset + h * 0.06),
      paint,
    );

    canvas.drawPath(_heart(tip, w * 0.30), Paint()..color = seal);
  }

  /// A heart of width [s] centred on [c].
  Path _heart(Offset c, double s) {
    final x = c.dx;
    final y = c.dy - s * 0.12;
    return Path()
      ..moveTo(x, y + s * 0.42)
      ..cubicTo(x - s * 0.62, y + s * 0.02, x - s * 0.40, y - s * 0.46, x,
          y - s * 0.16)
      ..cubicTo(x + s * 0.40, y - s * 0.46, x + s * 0.62, y + s * 0.02, x,
          y + s * 0.42)
      ..close();
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) =>
      old.stroke != stroke || old.seal != seal;
}

/// «رسائل» with the envelope, as on the Rasael logo, plus an optional
/// product name after a hairline.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22, this.product});

  final double size;
  final String? product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: product == null ? 'رسائل' : 'رسائل، $product',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: size * 1.25),
          SizedBox(width: size * 0.4),
          Text('رسائل', style: AppType.wordmark(size).copyWith(color: c.ink)),
          if (product != null) ...[
            Container(
              width: 1,
              height: size * 0.85,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: c.borderStrong,
            ),
            Text(
              product!,
              style: AppType.label.copyWith(
                color: c.inkSecondary,
                fontSize: size * 0.62,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
