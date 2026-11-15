import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';
import 'player_track_info.dart';

/// Keeps a fixed layout footprint: only artwork and metadata transforms animate.
/// Timeline, actions and quick-delete never move when playback is toggled.
class PlayerArtworkAndInfo extends ConsumerStatefulWidget {
  const PlayerArtworkAndInfo({
    super.key,
    required this.song,
    required this.artworkSize,
    required this.useHero,
  });

  final Song song;
  final double artworkSize;
  final bool useHero;

  @override
  ConsumerState<PlayerArtworkAndInfo> createState() =>
      _PlayerArtworkAndInfoState();
}

class _PlayerArtworkAndInfoState extends ConsumerState<PlayerArtworkAndInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  late final Animation<double> _artworkOffset;
  late final Animation<double> _infoOffset;
  late final ProviderSubscription<bool> _playingSubscription;
  bool _playing = false;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _playing = ref.read(playerProvider).playing;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: _playing ? 1 : 0,
    );
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _scale = Tween<double>(
      begin: AppPlayerMetrics.pausedArtworkScale,
      end: 1,
    ).animate(_curve);
    _artworkOffset = Tween<double>(
      begin: AppPlayerMetrics.pausedArtworkOffset,
      end: 0,
    ).animate(_curve);
    _infoOffset = Tween<double>(
      begin:
          -(1 -
              AppPlayerMetrics.pausedArtworkScale -
              AppPlayerMetrics.pausedArtworkOffset -
              AppPlayerMetrics.pausedInfoGap),
      end: 0,
    ).animate(_curve);
    _playingSubscription = ref.listenManual(
      playerProvider.select((state) => state.playing),
      (_, playing) {
        _playing = playing;
        _syncPlayback();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    // Initial layout already reflects current playback; do not animate entry.
    _syncPlayback();
  }

  void _syncPlayback() {
    final target = _playing ? 1.0 : 0.0;
    if (_animate) {
      _controller.animateTo(target);
    } else {
      _controller.value = target;
    }
  }

  @override
  void dispose() {
    _playingSubscription.close();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.artworkSize;
    final artwork = ArtworkImage(
      songId: widget.song.id,
      size: size,
      borderRadius: BorderRadius.circular(
        size * AppPlayerMetrics.artworkRadiusFraction,
      ),
    );
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            child: RepaintBoundary(
              child: widget.useHero
                  ? Hero(tag: 'song-artwork-${widget.song.id}', child: artwork)
                  : artwork,
            ),
            builder: (_, child) => Transform.translate(
              offset: Offset(0, size * _artworkOffset.value),
              child: Transform.scale(
                scale: _scale.value,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedBuilder(
            animation: _controller,
            child: RepaintBoundary(child: PlayerTrackInfo(song: widget.song)),
            builder: (_, child) => Transform.translate(
              offset: Offset(0, size * _infoOffset.value),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
