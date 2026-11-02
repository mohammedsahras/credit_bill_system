import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Attractive circular success icon with a lock/unlock illustration,
/// used on the Password Changed / Success screen.
class CreditBillSuccessIcon extends StatelessWidget {
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;

  const CreditBillSuccessIcon({
    super.key,
    this.size = 110,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? CreditBillColors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        boxShadow: [
          BoxShadow(
            color: CreditBillColors.successGreen.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Unlock / success illustration: an open padlock shackle.
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: fg.withValues(alpha: 0.25), width: 3),
            ),
          ),
          // Shackle arc.
          CustomPaint(
            size: Size(size * 0.62, size * 0.62),
            painter: _LockShacklePainter(color: fg),
          ),
          // Check mark.
          Icon(Icons.check, size: size * 0.34, color: fg),
        ],
      ),
    );
  }
}

/// Paints the open padlock shackle arc.
class _LockShacklePainter extends CustomPainter {
  final Color color;

  _LockShacklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2 + size.height * 0.06);

    // Draw the shackle arc (top half of an oval).
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.42,
        height: size.width * 0.55,
      ),
      -3.14159,
      3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LockShacklePainter old) => old.color != color;
}
