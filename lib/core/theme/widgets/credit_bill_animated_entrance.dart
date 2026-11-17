import 'dart:async';

import 'package:flutter/material.dart';

/// Reusable fade + slide entrance animation used to give screens and lists a
/// polished, staggered reveal without changing their business logic.
///
/// Wrap any widget in [CreditBillAnimatedEntrance] and optionally pass an
/// [index] so siblings stagger by [stagger]. Honours
/// [MediaQuery.disableAnimationsOf] (no motion when reduced motion is on).
class CreditBillAnimatedEntrance extends StatefulWidget {
  final Widget child;

  /// Zero-based position used to compute the stagger delay.
  final int index;

  /// Per-item delay between staggered entries.
  final Duration stagger;

  /// Total duration of the fade + slide.
  final Duration duration;

  /// How far (in logical pixels) the child slides in from.
  final double offset;

  const CreditBillAnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 320),
    this.offset = 16,
  });

  @override
  State<CreditBillAnimatedEntrance> createState() =>
      _CreditBillAnimatedEntranceState();
}

class _CreditBillAnimatedEntranceState extends State<CreditBillAnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final reduceMotion = WidgetsBinding.instance.platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _timer = Timer(widget.stagger * widget.index, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
