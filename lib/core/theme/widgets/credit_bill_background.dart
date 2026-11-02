import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';
import '../credit_bill_theme.dart';

/// Custom clipper that produces the premium white geometric panel with
/// diagonal/angular edges — rounded top-left and bottom-right corners,
/// chamfered (diagonal) cuts at the top-right and bottom-left corners.
///
/// The blue background shows through the diagonal cuts, matching the
/// reference design's diagonal blue sections at top-right and bottom-left.
class CreditBillGeometricClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double diagonalCut;

  const CreditBillGeometricClipper({
    this.cornerRadius = 26.0,
    this.diagonalCut = 46.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final c = diagonalCut;

    // Top edge begins after the rounded top-left corner.
    path.moveTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: false);

    // Top edge to the start of the top-right diagonal cut.
    path.lineTo(w - c, 0);

    // Diagonal cut at top-right corner: (w - c, 0) -> (w, c).
    path.lineTo(w, c);

    // Right edge down to the rounded bottom-right corner.
    path.lineTo(w, h - r);
    path.arcToPoint(
      Offset(w - r, h),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // Bottom edge to the start of the bottom-left diagonal cut.
    path.lineTo(c, h);

    // Diagonal cut at bottom-left corner: (c, h) -> (0, h - c).
    path.lineTo(0, h - c);

    // Left edge back up to the start.
    path.lineTo(0, r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CreditBillGeometricClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.diagonalCut != diagonalCut;
}

/// Decorative diagonal blue section rendered at the top-right and
/// bottom-left of the screen behind the white geometric panel.
class CreditBillDiagonalSection extends StatelessWidget {
  final Alignment alignment;

  const CreditBillDiagonalSection({super.key, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.rotate(
          angle: alignment == Alignment.topRight ? -0.35 : 0.35,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFF075B87)
                  .withValues(red: 7.0, green: 91.0, blue: 135.0, alpha: 115.0),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium blue gradient background shared across all authentication screens.
///
/// Draws the blue gradient, the decorative diagonal blue sections at the
/// top-right and bottom-left, and centres the white geometric panel that
/// holds the screen content.
class CreditBillBackground extends StatelessWidget {
  final Widget child;

  const CreditBillBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: CreditBillColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Decorative diagonal blue sections.
          const CreditBillDiagonalSection(alignment: Alignment.topRight),
          const CreditBillDiagonalSection(alignment: Alignment.bottomLeft),

          // White geometric panel containing the screen content.
          Center(child: CreditBillGeometricPanel(child: child)),
        ],
      ),
    );
  }
}

/// White geometric panel with diagonal/angular edges and rounded corners.
///
/// Wraps the screen content with premium padding and a subtle shadow.
class CreditBillGeometricPanel extends StatelessWidget {
  final Widget child;
  final double width;
  final double padding;

  const CreditBillGeometricPanel({
    super.key,
    required this.child,
    this.width = 340,
    this.padding = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const CreditBillGeometricClipper(),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: BoxDecoration(
          gradient: CreditBillColors.panelGradient,
          boxShadow: [
            BoxShadow(
              color: CreditBillColors.deepBlue.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}
