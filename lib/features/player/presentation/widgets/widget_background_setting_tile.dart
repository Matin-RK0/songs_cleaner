import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/providers/widget_background_controller.dart';

class WidgetBackgroundSettingTile extends ConsumerWidget {
  const WidgetBackgroundSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final value = ref.watch(widgetBackgroundColorProvider);
    final colors = context.colors;
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(Icons.widgets_outlined, color: colors.primary),
      title: Text(
        l10n.widgetBackgroundTitle,
        style: AppTypography.emphasisTitle.copyWith(color: colors.textHigh),
      ),
      subtitle: Text(
        value == null
            ? l10n.widgetBackgroundDynamic
            : l10n.widgetBackgroundCustom,
        style: AppTypography.songSubtitle.copyWith(color: colors.textMedium),
      ),
      trailing: value == null
          ? Icon(Icons.auto_awesome_outlined, color: colors.textLow)
          : SizedBox.square(
              dimension: AppSpacing.lg,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: Color(value),
                  shape: CircleBorder(side: BorderSide(color: colors.outline)),
                ),
              ),
            ),
      onTap: () {
        final controller = ref.read(widgetBackgroundColorProvider.notifier);
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: colors.surfaceHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
          ),
          builder: (_) => _WidgetBackgroundSheet(
            initialColor: value ?? AppColorTokens.dark.surfaceHigh.toARGB32(),
            onSave: controller.setColor,
          ),
        );
      },
    );
  }
}

class _WidgetBackgroundSheet extends StatefulWidget {
  const _WidgetBackgroundSheet({
    required this.initialColor,
    required this.onSave,
  });

  final int initialColor;
  final Future<void> Function(int?) onSave;

  @override
  State<_WidgetBackgroundSheet> createState() => _WidgetBackgroundSheetState();
}

class _WidgetBackgroundSheetState extends State<_WidgetBackgroundSheet> {
  late int _red;
  late int _green;
  late int _blue;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _red = (widget.initialColor >> 16) & 0xff;
    _green = (widget.initialColor >> 8) & 0xff;
    _blue = widget.initialColor & 0xff;
  }

  Color get _color => Color.fromARGB(255, _red, _green, _blue);

  Future<void> _submit(int? value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(value);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.widgetBackgroundTitle,
                style: AppTypography.sectionTitle.copyWith(
                  color: colors.textHigh,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSpacing.xl,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: _color,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                      side: BorderSide(color: colors.outline),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _channel(l10n.colorRed, _red, (value) => _red = value),
              _channel(l10n.colorGreen, _green, (value) => _green = value),
              _channel(l10n.colorBlue, _blue, (value) => _blue = value),
              if (_failed) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.errorLoadFailedMessage,
                    style: AppTypography.body.copyWith(color: colors.danger),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => _submit(null),
                    child: Text(l10n.widgetBackgroundUseDynamic),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () => _submit(_color.toARGB32()),
                    child: Text(l10n.saveAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channel(String label, int value, ValueChanged<int> onChanged) {
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$label: ${localizations.formatDecimal(value)}',
          style: AppTypography.body.copyWith(color: context.colors.textHigh),
        ),
        Semantics(
          label: label,
          child: Slider(
            value: value.toDouble(),
            max: 255,
            divisions: 255,
            label: localizations.formatDecimal(value),
            semanticFormatterCallback: (value) =>
                localizations.formatDecimal(value.round()),
            onChanged: _saving
                ? null
                : (value) => setState(() => onChanged(value.round())),
          ),
        ),
      ],
    );
  }
}
