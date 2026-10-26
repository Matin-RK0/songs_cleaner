import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/providers/library_providers.dart';

/// Album artwork for a song, decoded at the requested size through the
/// artwork cache. Falls back to a neutral music glyph.
class ArtworkImage extends ConsumerWidget {
  const ArtworkImage({
    super.key,
    required this.songId,
    this.size = 48,
    this.borderRadius,
    this.expand = false,
    this.resolution,
    this.semanticLabel,
  });

  final int songId;
  final double size;
  final BorderRadius? borderRadius;
  final bool expand;

  /// Overrides the requested source resolution. Small collage cells can pass a
  /// lower value so they are not decoded at the full list-thumbnail size.
  final int? resolution;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MediaStore returns a thumbnail at the requested dimensions. A 256px
    // request looks soft when the same artwork is enlarged in the player, so
    // keep the source at the reference app's 500px minimum for every usage.
    // Larger widgets still get a source large enough for their bounds.
    final requestSize = resolution ?? math.max(500, size.round());
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, requestSize);
    final bytes = ref.watch(songArtworkProvider((songId, requestSize)));
    final colors = context.colors;
    final image = RepaintBoundary(
      child: SizedBox(
        width: expand ? double.infinity : size,
        height: expand ? double.infinity : size,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.artworkPlaceholder,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.md,
            ),
          ),
          child:
              bytes.whenOrNull(
                data: (data) => data == null
                    ? null
                    : _image(data, decodeSize, colors.textLow),
              ) ??
              _placeholder(colors.textLow),
        ),
      ),
    );
    if (semanticLabel == null || semanticLabel!.isEmpty) return image;
    return Semantics(image: true, label: semanticLabel, child: image);
  }

  Widget _image(Uint8List data, int decodeSize, Color placeholderColor) {
    return ClipRRect(
      borderRadius: borderRadius ?? AppRadius.md,
      child: Image.memory(
        key: ValueKey(songId),
        data,
        cacheWidth: decodeSize,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(placeholderColor),
        frameBuilder: (context, child, frame, synchronouslyLoaded) {
          if (synchronouslyLoaded) return child;
          final placeholder = _placeholder(placeholderColor);
          if (frame == null) return placeholder;
          return Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              _ArtworkReveal(key: ValueKey(songId), child: child),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Icon(Icons.music_note_rounded, size: size * 0.5, color: color);
  }
}

/// Mounted only after the first decoded frame is ready, so the transition
/// never expires while an artwork request is still waiting for MediaStore.
class _ArtworkReveal extends StatefulWidget {
  const _ArtworkReveal({super.key, required this.child});

  final Widget child;

  @override
  State<_ArtworkReveal> createState() => _ArtworkRevealState();
}

class _ArtworkRevealState extends State<_ArtworkReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _opacity.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(opacity: _opacity, child: widget.child),
  );
}
