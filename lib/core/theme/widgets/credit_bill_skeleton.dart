import 'package:flutter/material.dart';

import '../credit_bill_colors.dart';

/// A lightweight, dependency-free shimmer skeleton used as a loading
/// placeholder. Animates a moving highlight across a rounded rectangle.
class CreditBillSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const CreditBillSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<CreditBillSkeleton> createState() => _CreditBillSkeletonState();
}

class _CreditBillSkeletonState extends State<CreditBillSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * t, 0),
              end: Alignment(1.0 + 2 * t, 0),
              colors: [
                CreditBillColors.inputBackground,
                CreditBillColors.white,
                CreditBillColors.inputBackground,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}
