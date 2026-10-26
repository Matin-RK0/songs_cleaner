import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Keeps actions mounted until their exit transition has finished.
class HomeActionVisibility extends StatefulWidget {
  const HomeActionVisibility({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  State<HomeActionVisibility> createState() => _HomeActionVisibilityState();
}

class _HomeActionVisibilityState extends State<HomeActionVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _visibility;
  late final Animation<Offset> _slide;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
      value: widget.visible ? 1 : 0,
    );
    _visibility = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.emphasized,
    );
    _slide = Tween<Offset>(
      begin: AppMotion.floatingActionEntryOffset,
      end: Offset.zero,
    ).animate(_visibility);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _controller.value = widget.visible ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant HomeActionVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (_reduceMotion) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      // Lay out the action at zero opacity before starting its entry, so the
      // tab's initial layout does not consume the animation's first frames.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.visible || _reduceMotion) return;
        _controller.forward();
      });
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _visibility.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Offstage(
        offstage: !widget.visible && _controller.isDismissed,
        child: child,
      ),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeSemantics(
          excluding: !widget.visible,
          child: RepaintBoundary(
            child: FadeTransition(
              opacity: _visibility,
              child: SlideTransition(position: _slide, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
