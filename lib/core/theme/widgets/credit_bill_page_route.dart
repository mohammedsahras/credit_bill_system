import 'package:flutter/material.dart';

/// Shared page transition for settings navigation: a short fade with a
/// subtle upward slide, built on Flutter's built-in animation APIs.
///
/// Honours the platform's "remove animations" accessibility setting —
/// when `disableAnimations` is on, content is shown without transition.
class CreditBillPageRoute<T> extends PageRouteBuilder<T> {
  CreditBillPageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        opaque: true,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
