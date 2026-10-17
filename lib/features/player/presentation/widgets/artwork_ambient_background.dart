import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../application/providers/artwork_palette_provider.dart';

/// Artwork-derived ambient lighting shared by the full and lock-screen player.
/// The lights use gradients instead of blur and are isolated from controls.
class ArtworkAmbientBackground extends ConsumerWidget {
  const ArtworkAmbientBackground({
    super.key,
    required this.songId,
    required this.visible,
    required this.child,
  });

  final int? songId;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.colors;
    final palette = songId == null
        ? null
        : ref.watch(artworkPaletteProvider(songId!)).value;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.background),
        _AmbientLights(
          visible: visible,
          first: palette?.first ?? tokens.playerGradientTop,
          second: palette?.second ?? tokens.playerGradientMiddle,
        ),
        ColoredBox(color: tokens.background.withValues(alpha: 0.62)),
        child,
      ],
    );
  }
}

class _AmbientLights extends StatefulWidget {
  const _AmbientLights({
    required this.visible,
    required this.first,
    required this.second,
  });

  final bool visible;
  final Color first;
  final Color second;

  @override
  State<_AmbientLights> createState() => _AmbientLightsState();
}

class _AmbientLightsState extends State<_AmbientLights>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _paletteController;
  late final AnimationController _visibilityController;
  late Animation<Offset> _firstOffset;
  late Animation<Offset> _secondOffset;
  late ColorTween _firstColor;
  late ColorTween _secondColor;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: AppMotion.slow * 5,
    );
    _paletteController = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    );
    _visibilityController = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
      value: widget.visible ? 1 : 0,
    );
    _firstOffset =
        Tween<Offset>(
          begin: const Offset(-0.12, -0.08),
          end: const Offset(0.12, 0.08),
        ).animate(
          CurvedAnimation(
            parent: _motionController,
            curve: AppMotion.emphasized,
          ),
        );
    _secondOffset =
        Tween<Offset>(
          begin: const Offset(0.12, 0.10),
          end: const Offset(-0.10, -0.06),
        ).animate(
          CurvedAnimation(parent: _motionController, curve: AppMotion.standard),
        );
    _firstColor = ColorTween(begin: widget.first, end: widget.first);
    _secondColor = ColorTween(begin: widget.second, end: widget.second);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.visible) return;
      _motionController.repeat(reverse: true);
    });
  }

  @override
  void didUpdateWidget(covariant _AmbientLights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.first != widget.first || oldWidget.second != widget.second) {
      _firstColor = ColorTween(
        begin: _firstColor.evaluate(_paletteController),
        end: widget.first,
      );
      _secondColor = ColorTween(
        begin: _secondColor.evaluate(_paletteController),
        end: widget.second,
      );
      _paletteController.forward(from: 0);
    }
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _visibilityController.forward();
        _motionController.repeat(reverse: true);
      } else {
        _visibilityController.reverse();
        _motionController.stop();
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _paletteController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _visibilityController,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _motionController,
              _paletteController,
            ]),
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(
                  children: [
                    _light(
                      color: _firstColor.evaluate(_paletteController)!,
                      left: width * (0.05 + _firstOffset.value.dx),
                      top: height * (0.04 + _firstOffset.value.dy),
                      size: width * 0.72,
                    ),
                    _light(
                      color: _secondColor.evaluate(_paletteController)!,
                      left: width * (0.38 + _secondOffset.value.dx),
                      top: height * (0.48 + _secondOffset.value.dy),
                      size: width * 0.70,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _light({
    required Color color,
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}
