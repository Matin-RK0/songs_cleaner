import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/appearance_preferences.dart';
import '../../../../core/settings/photo_framing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/appearance_backdrop.dart';

Future<double?> showPhotoDimmingSheet(
  BuildContext context,
  String path,
  double initial,
  PhotoFraming framing,
) => showModalBottomSheet<double>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  backgroundColor: context.colors.surfaceHigh,
  builder: (_) => _PhotoDimmingSheet(
    path: path,
    initial: initial,
    framing: framing,
    aspectRatio: MediaQuery.sizeOf(context).aspectRatio,
  ),
);

class _PhotoDimmingSheet extends StatefulWidget {
  const _PhotoDimmingSheet({
    required this.path,
    required this.initial,
    required this.framing,
    required this.aspectRatio,
  });

  final String path;
  final double initial;
  final PhotoFraming framing;
  final double aspectRatio;

  @override
  State<_PhotoDimmingSheet> createState() => _PhotoDimmingSheetState();
}

class _PhotoDimmingSheetState extends State<_PhotoDimmingSheet> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: AppSpacing.allMd,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.appBackgroundDimming,
                  style: AppTypography.sheetTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.appBackgroundDimmingSubtitle),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: ClipRRect(
                    borderRadius: AppRadius.md,
                    child: SizedBox(
                      height: AppSpacing.iconHero * 2,
                      width: AppSpacing.iconHero * 2 * widget.aspectRatio,
                      child: AppearanceBackdrop(
                        path: widget.path,
                        dimming: _value,
                        framing: widget.framing,
                      ),
                    ),
                  ),
                ),
                Slider(
                  min: AppearancePreferences.minDimming,
                  max: 1,
                  value: _value,
                  label: number.format(_value),
                  semanticFormatterCallback: number.format,
                  onChanged: (value) => setState(() => _value = value),
                ),
                Text(number.format(_value), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: Text(l10n.saveAction),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
