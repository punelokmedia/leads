import 'package:flutter/material.dart';

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static Widget transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: const Offset(0.035, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => transition(context, animation, secondaryAnimation, child);
}
