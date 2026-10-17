import 'dart:math' as math;
import 'dart:ui' as ui;

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
          third:
              palette?.third ??
              Color.lerp(
                tokens.playerGradientTop,
                tokens.playerGradientMiddle,
                0.5,
              )!,
        ),
        ColoredBox(color: tokens.background.withValues(alpha: 0.20)),
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
    required this.third,
  });

  final bool visible;
  final Color first;
  final Color second;
  final Color third;

  @override
  State<_AmbientLights> createState() => _AmbientLightsState();
}

class _AmbientLightsState extends State<_AmbientLights>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _secondMotionController;
  late final AnimationController _thirdMotionController;
  late final AnimationController _paletteController;
  late final AnimationController _visibilityController;
  late final _AmbientPath _firstPath;
  late final _AmbientPath _secondPath;
  late final _AmbientPath _thirdPath;
  late ColorTween _firstColor;
  late ColorTween _secondColor;
  late ColorTween _thirdColor;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: AppMotion.ambientPrimary,
    );
    _secondMotionController = AnimationController(
      vsync: this,
      duration: AppMotion.ambientPrimary,
    );
    _thirdMotionController = AnimationController(
      vsync: this,
      duration: AppMotion.ambientPrimary,
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
    final random = math.Random();
    _firstPath = _AmbientPath.random(random);
    _secondPath = _AmbientPath.random(random);
    _thirdPath = _AmbientPath.random(random);
    _firstColor = ColorTween(begin: widget.first, end: widget.first);
    _secondColor = ColorTween(begin: widget.second, end: widget.second);
    _thirdColor = ColorTween(begin: widget.third, end: widget.third);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.visible) return;
      _motionController.repeat();
      _secondMotionController.repeat();
      _thirdMotionController.repeat();
    });
  }

  @override
  void didUpdateWidget(covariant _AmbientLights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.first != widget.first ||
        oldWidget.second != widget.second ||
        oldWidget.third != widget.third) {
      _firstColor = ColorTween(
        begin: _firstColor.evaluate(_paletteController),
        end: widget.first,
      );
      _secondColor = ColorTween(
        begin: _secondColor.evaluate(_paletteController),
        end: widget.second,
      );
      _thirdColor = ColorTween(
        begin: _thirdColor.evaluate(_paletteController),
        end: widget.third,
      );
      _paletteController.forward(from: 0);
    }
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _visibilityController.forward();
        _motionController.repeat();
        _secondMotionController.repeat();
        _thirdMotionController.repeat();
      } else {
        _visibilityController.reverse();
        _motionController.stop();
        _secondMotionController.stop();
        _thirdMotionController.stop();
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _secondMotionController.dispose();
    _thirdMotionController.dispose();
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
              _secondMotionController,
              _thirdMotionController,
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
                      centerX: _firstPath.position(_motionController.value).dx,
                      centerY: _firstPath.position(_motionController.value).dy,
                      viewportWidth: width,
                      viewportHeight: height,
                      size: width * 1.70,
                    ),
                    _light(
                      color: _secondColor.evaluate(_paletteController)!,
                      centerX: _secondPath
                          .position(_secondMotionController.value)
                          .dx,
                      centerY: _secondPath
                          .position(_secondMotionController.value)
                          .dy,
                      viewportWidth: width,
                      viewportHeight: height,
                      size: width * 1.62,
                    ),
                    _light(
                      color: _thirdColor.evaluate(_paletteController)!,
                      centerX: _thirdPath
                          .position(_thirdMotionController.value)
                          .dx,
                      centerY: _thirdPath
                          .position(_thirdMotionController.value)
                          .dy,
                      viewportWidth: width,
                      viewportHeight: height,
                      size: width * 1.58,
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
    required double centerX,
    required double centerY,
    required double viewportWidth,
    required double viewportHeight,
    required double size,
  }) {
    return Positioned(
      left: centerX * viewportWidth - size / 2,
      top: centerY * viewportHeight - size / 2,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.66),
              color.withValues(alpha: 0.28),
              Colors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

/// A closed, random smooth path whose arc-length lookup keeps motion linear.
class _AmbientPath {
  _AmbientPath(Path path) : _metric = path.computeMetrics().first;

  final ui.PathMetric _metric;

  static _AmbientPath random(math.Random random) {
    final points = List<Offset>.generate(
      7,
      (_) => Offset(
        -0.55 + random.nextDouble() * 2.10,
        -0.55 + random.nextDouble() * 2.10,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final previous = points[(index - 1 + points.length) % points.length];
      final afterNext = points[(index + 2) % points.length];
      final controlStart = current + (next - previous) / 6;
      final controlEnd = next - (afterNext - current) / 6;
      path.cubicTo(
        controlStart.dx,
        controlStart.dy,
        controlEnd.dx,
        controlEnd.dy,
        next.dx,
        next.dy,
      );
    }
    path.close();
    return _AmbientPath(path);
  }

  Offset position(double progress) {
    final tangent = _metric.getTangentForOffset(
      _metric.length * progress.clamp(0.0, 1.0),
    );
    return tangent?.position ?? Offset.zero;
  }
}
