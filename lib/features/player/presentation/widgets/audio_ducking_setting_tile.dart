import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/providers/audio_focus_controller.dart';

/// Keeps drag previews local and writes the setting only when dragging ends.
class AudioDuckingSettingTile extends ConsumerStatefulWidget {
  const AudioDuckingSettingTile({super.key});

  @override
  ConsumerState<AudioDuckingSettingTile> createState() =>
      _AudioDuckingSettingTileState();
}

class _AudioDuckingSettingTileState
    extends ConsumerState<AudioDuckingSettingTile> {
  int? _preview;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(audioDuckingPercentProvider);
    final percent = _preview ?? saved;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            Icons.volume_down_rounded,
            color: context.colors.primary,
          ),
          title: Text(l10n.audioDuckingVolumeTitle),
          subtitle: Text(l10n.audioDuckingVolumeHint),
          trailing: Text(l10n.audioDuckingPercent(percent)),
        ),
        Slider(
          value: percent.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: l10n.audioDuckingPercent(percent),
          semanticFormatterCallback: (value) =>
              l10n.audioDuckingPercent(value.round()),
          onChanged: (value) => setState(() => _preview = value.round()),
          onChangeEnd: (value) async {
            await ref
                .read(audioDuckingPercentProvider.notifier)
                .setPercent(value.round());
            if (mounted) setState(() => _preview = null);
          },
        ),
      ],
    );
  }
}
