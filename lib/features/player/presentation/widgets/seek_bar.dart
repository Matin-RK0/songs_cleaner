import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../application/providers/player_controller.dart';

/// Seek slider with elapsed/total labels. Dragging is kept in local state so
/// stream updates never fight the user's finger.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key});

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar>
    with SingleTickerProviderStateMixin {
  double? _dragValueMs;
  late final AnimationController _entryController;
  late final CurvedAnimation _entryOpacity;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryController,
      curve: AppMotion.standard,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entryController.value = 1;
      } else {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryOpacity.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(
      playerProvider.select((state) => state.position),
    );
    final duration = ref.watch(
      playerProvider.select((state) => state.duration),
    );
    final isBuffering = ref.watch(
      playerProvider.select((state) => state.isBuffering),
    );

    final maxMs = duration.inMilliseconds.toDouble();
    final value = (_dragValueMs ?? position.inMilliseconds.toDouble()).clamp(
      0.0,
      maxMs <= 0 ? 1.0 : maxMs,
    );
    final colors = context.colors;

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _entryOpacity,
        child: Directionality(
          // Audio timelines always advance from the physical left edge.
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: colors.outline,
                  thumbColor: colors.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 18,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Slider(
                    value: value,
                    max: maxMs <= 0 ? 1 : maxMs,
                    onChanged: maxMs <= 0 || isBuffering
                        ? null
                        : (newValue) => setState(() => _dragValueMs = newValue),
                    onChangeEnd: (newValue) async {
                      await ref
                          .read(playerProvider.notifier)
                          .seek(Duration(milliseconds: newValue.round()));
                      if (mounted) setState(() => _dragValueMs = null);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Duration(milliseconds: value.round()).mmss,
                      style: AppTypography.caption.copyWith(
                        color: colors.textMedium,
                      ),
                    ),
                    Text(
                      duration.mmss,
                      style: AppTypography.caption.copyWith(
                        color: colors.textLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
