import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_format.dart';
import '../../application/providers/player_controller.dart';

/// Seek slider with elapsed/total labels. Dragging is kept in local state so
/// stream updates never fight the user's finger.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key});

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(
      playerProvider.select((state) => state.position),
    );
    final duration = ref.watch(
      playerProvider.select((state) => state.duration),
    );

    final maxMs = duration.inMilliseconds.toDouble();
    final value = _dragValueMs ??
        position.inMilliseconds.toDouble().clamp(0.0, maxMs == 0 ? 1 : maxMs);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.outline,
            thumbColor: AppColors.primary,
          ),
          child: Slider(
            value: value,
            max: maxMs <= 0 ? 1 : maxMs,
            onChanged: maxMs <= 0
                ? null
                : (newValue) => setState(() => _dragValueMs = newValue),
            onChangeEnd: (newValue) {
              ref
                  .read(playerProvider.notifier)
                  .seek(Duration(milliseconds: newValue.round()));
              setState(() => _dragValueMs = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Duration(milliseconds: value.round()).mmss,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                duration.mmss,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
