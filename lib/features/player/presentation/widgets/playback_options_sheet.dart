import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../app/router/route_names.dart';
import '../../application/providers/player_controller.dart';

Future<void> showPlaybackOptionsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final colors = context.colors;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: colors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
    ),
    builder: (_) => const _PlaybackOptionsSheet(),
  );
}

class _PlaybackOptionsSheet extends ConsumerWidget {
  const _PlaybackOptionsSheet();

  static const _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2, 3];
  static const _timers = <Duration?>[
    null,
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final speed = ref.watch(playerProvider.select((state) => state.speed));
    final timer = ref.watch(
      playerProvider.select((state) => state.sleepTimerRemaining),
    );
    final gapless = ref.watch(playerProvider.select((state) => state.gapless));

    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Text(
            l10n.playbackOptionsTitle,
            style: AppTypography.sheetTitleSmall.copyWith(
              color: colors.textHigh,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.equalizer_rounded),
            title: Text(l10n.equalizerTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteNames.equalizer);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: gapless,
            title: Text(l10n.gaplessPlaybackTitle),
            subtitle: Text(l10n.gaplessPlaybackSubtitle),
            onChanged: (value) =>
                ref.read(playerProvider.notifier).setGaplessPlayback(value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.playbackSpeed,
            style: AppTypography.sectionLabel.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _speeds)
                ChoiceChip(
                  label: Text('${option}x'),
                  selected: speed == option,
                  onSelected: (_) =>
                      ref.read(playerProvider.notifier).setSpeed(option),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.sleepTimer,
            style: AppTypography.sectionLabel.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final option in _timers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                option == _timerChoice(timer)
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: option == _timerChoice(timer)
                    ? colors.primary
                    : colors.textLow,
              ),
              title: Text(_timerLabel(l10n, option, timer)),
              onTap: () {
                ref.read(playerProvider.notifier).setSleepTimer(option);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Duration? _timerChoice(Duration? timer) {
    if (timer == null) return null;
    for (final option in _timers.skip(1)) {
      if (timer.inSeconds == option!.inSeconds) return option;
    }
    return timer;
  }

  String _timerLabel(
    AppLocalizations l10n,
    Duration? option,
    Duration? current,
  ) {
    if (option == null) return l10n.sleepTimerOff;
    if (current != null && option == current) {
      return l10n.sleepTimerRemaining(current.mmss);
    }
    if (option == const Duration(hours: 1)) return l10n.sleepTimerMinutes(60);
    return l10n.sleepTimerMinutes(option.inMinutes);
  }
}
