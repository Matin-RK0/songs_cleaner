import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

class TelegramRoute extends PageRouteBuilder<void> {
  TelegramRoute({required RouteSettings settings, required Widget child})
    : super(
        settings: settings,
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, _, child) =>
            _TelegramTransition(animation: animation, child: child),
      );
}

class _TelegramTransition extends StatefulWidget {
  const _TelegramTransition({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;
  @override
  State<_TelegramTransition> createState() => _TelegramTransitionState();
}

class _TelegramTransitionState extends State<_TelegramTransition> {
  late final CurvedAnimation _curve;
  late final Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _curve = CurvedAnimation(
      parent: widget.animation,
      curve: AppMotion.standard,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_curve);
  }

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? widget.child
      : SlideTransition(
          position: _slide,
          child: RepaintBoundary(child: widget.child),
        );
}
