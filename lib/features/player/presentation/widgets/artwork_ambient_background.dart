import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../application/providers/artwork_palette_provider.dart';

/// Artwork-derived light, clipped by the player to the area below the cover.
class ArtworkAmbientBackground extends ConsumerWidget {
  const ArtworkAmbientBackground({
    super.key,
    required this.songId,
    required this.visible,
    required this.child,
    this.subdued = false,
  });

  final int? songId;
  final bool visible;
  final Widget child;
  final bool subdued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.colors;
    final palette = songId == null
        ? null
        : ref.watch(artworkPaletteProvider(songId!)).value;
    final first = palette?.first ?? tokens.playerGradientTop;
    final second = palette?.second ?? tokens.playerGradientMiddle;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.background),
        if (visible)
          RepaintBoundary(
            child: subdued
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.background,
                          Color.alphaBlend(
                            first.withValues(alpha: 0.40),
                            tokens.background,
                          ),
                          Color.alphaBlend(
                            second.withValues(alpha: 0.55),
                            tokens.background,
                          ),
                        ],
                      ),
                    ),
                  )
                : _AmbientLights(
                    colors: [
                      first,
                      second,
                      palette?.third ?? Color.lerp(first, second, 0.5)!,
                    ],
                  ),
          ),
        ColoredBox(color: tokens.background.withValues(alpha: 0.20)),
        if (!subdued)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tokens.background,
                  tokens.background.withValues(alpha: 0),
                ],
                stops: const [0, 0.28],
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _AmbientLights extends StatefulWidget {
  const _AmbientLights({required this.colors});
  final List<Color> colors;

  @override
  State<_AmbientLights> createState() => _AmbientLightsState();
}

class _AmbientLightsState extends State<_AmbientLights>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  late final List<_AmbientPath> _paths;
  bool _enabled = false;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: AppMotion.ambientPrimary,
    );
    final random = math.Random();
    _paths = List.generate(3, (_) => _AmbientPath.random(random));
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (!_enabled || !_resumed) {
      _motion.stop();
      return;
    }
    if (_motion.isAnimating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _enabled && _resumed && !_motion.isAnimating) {
        _motion.repeat();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final size = width * 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < _paths.length; index++)
                Positioned(
                  left: 0,
                  top: 0,
                  width: size,
                  height: size,
                  child: AnimatedBuilder(
                    animation: _motion,
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.colors[index].withValues(alpha: 0.32),
                              widget.colors[index].withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.62, 1],
                          ),
                        ),
                      ),
                    ),
                    builder: (_, child) {
                      final position = _paths[index].position(_motion.value);
                      return Transform.translate(
                        offset: Offset(
                          position.dx * width - size / 2,
                          position.dy * height - size / 2,
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Random closed paths are cached once; only their transform changes per frame.
class _AmbientPath {
  _AmbientPath(Path path) : _metric = path.computeMetrics().first;
  final ui.PathMetric _metric;

  static _AmbientPath random(math.Random random) {
    final points = List.generate(
      7,
      (_) => Offset(random.nextDouble(), random.nextDouble()),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final previous = points[(index - 1 + points.length) % points.length];
      final afterNext = points[(index + 2) % points.length];
      final start = current + (next - previous) / 6;
      final end = next - (afterNext - current) / 6;
      path.cubicTo(start.dx, start.dy, end.dx, end.dy, next.dx, next.dy);
    }
    return _AmbientPath(path..close());
  }

  Offset position(double progress) =>
      _metric.getTangentForOffset(_metric.length * progress)?.position ??
      Offset.zero;
}
