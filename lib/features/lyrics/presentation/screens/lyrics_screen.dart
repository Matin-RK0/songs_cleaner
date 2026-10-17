import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../library/domain/entities/song.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/providers/lyrics_provider.dart';
import '../../domain/entities/lyric_line.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key, required this.song});

  final Song song;

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(lyricsProvider(widget.song));
    final position = ref.watch(
      playerProvider.select((state) => state.position),
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.lyricsTitle)),
      body: lines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _empty(context),
        data: (items) {
          if (items.isEmpty) return _empty(context);
          final activeIndex = _findActiveIndex(items, position);
          if (activeIndex != _activeIndex) {
            _activeIndex = activeIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_scrollController.hasClients) return;
              final target = (activeIndex * 64.0).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              );
              _scrollController.animateTo(
                target,
                duration: AppMotion.normal,
                curve: AppMotion.standard,
              );
            });
          }
          return ListView.builder(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _LyricLineTile(
              line: items[index],
              active: index == activeIndex,
            ),
          );
        },
      ),
    );
  }

  int _findActiveIndex(List<LyricLine> lines, Duration position) {
    var active = -1;
    for (var index = 0; index < lines.length; index++) {
      if (lines[index].timestamp <= position) {
        active = index;
      } else {
        break;
      }
    }
    return active;
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lyrics_outlined, size: 48, color: context.colors.textLow),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.lyricsUnavailable,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: context.colors.textMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LyricLineTile extends StatelessWidget {
  const _LyricLineTile({required this.line, required this.active});

  final LyricLine line;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(
      line.text.isEmpty ? '…' : line.text,
      textAlign: TextAlign.center,
      style: (active ? AppTypography.playerTitle : AppTypography.body).copyWith(
        color: active ? context.colors.primary : context.colors.textMedium,
        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
      ),
    ),
  );
}
