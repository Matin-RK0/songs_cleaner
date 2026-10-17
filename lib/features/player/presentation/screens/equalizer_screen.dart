import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/models/equalizer_state.dart';
import '../../application/providers/equalizer_controller.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equalizer = ref.watch(equalizerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.equalizerTitle)),
      body: equalizer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(context.l10n.equalizerUnavailable)),
        data: (state) => state.supported
            ? _EqualizerBody(state: state)
            : Center(child: Text(context.l10n.equalizerUnavailable)),
      ),
    );
  }
}

class _EqualizerBody extends ConsumerWidget {
  const _EqualizerBody({required this.state});

  final EqualizerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(equalizerProvider.notifier);
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: context.colors.surfaceHigh,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          ),
          child: SwitchListTile(
            secondary: Icon(
              Icons.equalizer_rounded,
              color: state.enabled
                  ? context.colors.primary
                  : context.colors.textLow,
            ),
            value: state.enabled,
            onChanged: controller.setEnabled,
            title: Text(context.l10n.equalizerEnabled),
            subtitle: Text(context.l10n.equalizerSubtitle),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ActionChip(
              label: Text(context.l10n.equalizerFlat),
              onPressed: controller.reset,
            ),
            ActionChip(
              label: Text(context.l10n.equalizerBassBoost),
              onPressed: () async {
                for (var index = 0; index < state.bands.length; index++) {
                  final gain = index < state.bands.length / 3 ? 5.0 : 0.0;
                  await controller.setGain(index, gain);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: state.enabled ? 1 : 0.48,
          child: IgnorePointer(
            ignoring: !state.enabled,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: context.colors.surfaceHigh,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  height: 250,
                  child: RepaintBoundary(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0; index < state.bands.length; index++)
                          Expanded(
                            child: _BandSlider(
                              band: state.bands[index],
                              minGain: state.minGain,
                              maxGain: state.maxGain,
                              onChanged: (gain) =>
                                  controller.setGain(index, gain),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.equalizerRange(
            state.minGain.toStringAsFixed(0),
            state.maxGain.toStringAsFixed(0),
          ),
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: context.colors.textLow),
        ),
      ],
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.band,
    required this.minGain,
    required this.maxGain,
    required this.onChanged,
  });

  final EqualizerBandState band;
  final double minGain;
  final double maxGain;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primary,
              inactiveTrackColor: context.colors.outline,
              thumbColor: context.colors.primary,
              overlayColor: context.colors.primary.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: band.gain.clamp(minGain, maxGain),
              min: minGain,
              max: maxGain,
              semanticFormatterCallback: (value) =>
                  '${_frequencyLabel(band.frequency)} ${value.toStringAsFixed(1)} dB',
              onChanged: onChanged,
            ),
          ),
        ),
      ),
      Text(
        _frequencyLabel(band.frequency),
        style: AppTypography.captionSmall.copyWith(
          color: context.colors.textMedium,
        ),
      ),
    ],
  );

  String _frequencyLabel(double frequency) {
    if (frequency >= 1000) return '${(frequency / 1000).toStringAsFixed(1)}k';
    return frequency.toStringAsFixed(0);
  }
}
