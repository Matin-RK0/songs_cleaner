import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/song.dart';

/// Fixed-extent, lazy list. Only transforms and opacity change per frame;
/// removal and insertion batches share a single short-lived ticker.
class AnimatedSongList extends StatefulWidget {
  const AnimatedSongList({
    super.key,
    required this.songs,
    required this.itemExtent,
    required this.itemBuilder,
    required this.physics,
    this.controller,
    this.emptyState,
  });

  final List<Song> songs;
  final double itemExtent;
  final Widget Function(BuildContext, Song) itemBuilder;
  final ScrollPhysics physics;
  final ScrollController? controller;
  final Widget? emptyState;

  @override
  State<AnimatedSongList> createState() => _AnimatedSongListState();
}

class _AnimatedSongListState extends State<AnimatedSongList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _progress;
  late final Animation<double> _reverseProgress;
  late List<Song> _songs;
  late Map<int, int> _indices;
  Set<int> _entering = {};
  Set<int> _removing = {};
  Map<int, double> _offsets = {};
  bool _scheduled = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    _songs = List.of(widget.songs);
    _indices = {for (var i = 0; i < _songs.length; i++) _songs[i].id: i};
    _entering = _songs.map((song) => song.id).toSet();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _progress = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _reverseProgress = ReverseAnimation(_progress);
    _controller.addStatusListener(_onStatus);
    _startAfterLayout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (!_tickerEnabled) {
      _controller.stop();
    } else if (_reduceMotion) {
      _controller.value = 1;
    } else if (_controller.value < 1) {
      _startAfterLayout();
    } else {
      _scheduleSync();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSongList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.songs, widget.songs)) _scheduleSync();
  }

  void _startAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tickerEnabled) return;
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  void _scheduleSync() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_tickerEnabled || _controller.isAnimating) return;
      _sync();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Serializing batches avoids overlapping removal/reorder animations when
    // MediaStore reports several changes during a multi-song delete.
    _scheduleSync();
  }

  void _sync() {
    final next = widget.songs;
    final nextIds = next.map((song) => song.id).toSet();
    if (_removing.isEmpty && !_reduceMotion) {
      final removed = _songs
          .where((song) => !nextIds.contains(song.id))
          .map((song) => song.id)
          .toSet();
      if (removed.isNotEmpty) {
        setState(() {
          _entering = {};
          _offsets = {};
          _removing = removed;
        });
        _controller.duration = AppMotion.fast;
        _controller.forward(from: 0);
        return;
      }
    }

    final oldIndices = <int, int>{
      for (var i = 0; i < _songs.length; i++) _songs[i].id: i,
    };
    final entering = <int>{};
    final offsets = <int, double>{};
    final maxOffset = widget.itemExtent * AppMotion.songMaxMoveRows;
    for (var i = 0; i < next.length; i++) {
      final oldIndex = oldIndices[next[i].id];
      if (oldIndex == null) {
        entering.add(next[i].id);
      } else if (oldIndex != i) {
        offsets[next[i].id] = ((oldIndex - i) * widget.itemExtent).clamp(
          -maxOffset,
          maxOffset,
        );
      }
    }
    setState(() {
      _songs = List.of(next);
      _indices = {for (var i = 0; i < next.length; i++) next[i].id: i};
      _removing = {};
      _entering = entering;
      _offsets = offsets;
    });
    if (!_reduceMotion && (entering.isNotEmpty || offsets.isNotEmpty)) {
      _controller.duration = AppMotion.normal;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_songs.isEmpty && widget.emptyState != null) return widget.emptyState!;
    return ListView.builder(
      controller: widget.controller,
      physics: widget.physics,
      itemExtent: widget.itemExtent,
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpacing.xl,
        start: AppSpacing.xs,
        end: AppSpacing.sm,
      ),
      itemCount: _songs.length,
      findChildIndexCallback: (key) =>
          key is ValueKey<int> ? _indices[key.value] : null,
      itemBuilder: (context, index) {
        final song = _songs[index];
        final removing = _removing.contains(song.id);
        final entering = _entering.contains(song.id);
        final offset = _offsets[song.id] ?? 0;
        final child = RepaintBoundary(
          child: IgnorePointer(
            ignoring: removing,
            child: widget.itemBuilder(context, song),
          ),
        );
        return AnimatedBuilder(
          key: ValueKey(song.id),
          animation: _progress,
          child: child,
          builder: (context, child) {
            final progress = _reduceMotion ? 1.0 : _progress.value;
            final dy = removing
                ? 0.0
                : (entering ? AppMotion.songEntryDistance : offset) *
                      (1 - progress);
            return Transform.translate(
              offset: Offset(
                removing ? AppMotion.songExitDistance * progress : 0,
                dy,
              ),
              child: FadeTransition(
                opacity: _reduceMotion
                    ? kAlwaysCompleteAnimation
                    : removing
                    ? _reverseProgress
                    : (entering ? _progress : kAlwaysCompleteAnimation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
