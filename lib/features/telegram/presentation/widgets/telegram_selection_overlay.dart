import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';

class TelegramSelectionOverlay extends StatefulWidget {
  const TelegramSelectionOverlay({
    super.key,
    required this.visible,
    required this.child,
  });
  final bool visible;
  final Widget child;
  @override
  State<TelegramSelectionOverlay> createState() =>
      _TelegramSelectionOverlayState();
}

class _TelegramSelectionOverlayState extends State<TelegramSelectionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<Offset> _slide;
  bool _firstFrame = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstFrame = true;
        _drive();
      }
    });
  }

  void _drive() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.visible ? 1 : 0;
      return;
    }
    if (!TickerMode.valuesOf(context).enabled ||
        ModalRoute.of(context)?.isCurrent == false) {
      _controller.stop();
      return;
    }
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstFrame) _drive();
  }

  @override
  void didUpdateWidget(covariant TelegramSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _drive();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.visible,
    child: ExcludeSemantics(
      excluding: !widget.visible,
      child: RepaintBoundary(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _curve,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height *
                    AppSpacing.selectionMaxHeightFactor,
              ),
              child: SingleChildScrollView(child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}
