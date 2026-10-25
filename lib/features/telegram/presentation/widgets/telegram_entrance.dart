import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';

/// A single, small transform animation. No per-frame widget-tree rebuilds.
class TelegramEntrance extends StatefulWidget {
  const TelegramEntrance({super.key, required this.child});
  final Widget child;
  @override
  State<TelegramEntrance> createState() => _TelegramEntranceState();
}

class _TelegramEntranceState extends State<TelegramEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(_curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && TickerMode.valuesOf(context).enabled) {
          _controller.forward();
        }
      });
    }
    _started = true;
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
