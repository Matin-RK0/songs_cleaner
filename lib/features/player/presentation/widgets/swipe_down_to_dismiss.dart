import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Wraps a full-screen player so a downward drag pulls the page down with the
/// finger and, past a small threshold (or with enough velocity), dismisses it.
///
/// Movement uses a GPU-friendly [Transform.translate] driven by a cached
/// [AnimationController] instead of rebuilding layout, so dragging stays cheap.
class SwipeDownToDismiss extends StatefulWidget {
  const SwipeDownToDismiss({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeDownToDismiss> createState() => _SwipeDownToDismissState();
}

class _SwipeDownToDismissState extends State<SwipeDownToDismiss>
    with SingleTickerProviderStateMixin {
  static const double _dismissFraction = 0.28;
  static const double _dismissVelocity = 700;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double extent) {
    _controller.value += (details.primaryDelta ?? 0) / extent;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        velocity > _dismissVelocity || _controller.value >= _dismissFraction;
    _controller.fling(velocity: shouldDismiss ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) => _handleDragUpdate(details, extent),
          onVerticalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            child: RepaintBoundary(child: widget.child),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _controller.value * extent),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
