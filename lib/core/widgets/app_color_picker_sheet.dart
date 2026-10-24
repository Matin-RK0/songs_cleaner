import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppColorPickerSheet extends StatefulWidget {
  const AppColorPickerSheet({
    super.key,
    required this.initialColor,
    required this.title,
    required this.onSave,
    this.resetLabel,
    this.onReset,
  });

  final Color initialColor;
  final String title;
  final Future<void> Function(Color) onSave;
  final String? resetLabel;
  final Future<void> Function()? onReset;

  @override
  State<AppColorPickerSheet> createState() => _AppColorPickerSheetState();
}

class _AppColorPickerSheetState extends State<AppColorPickerSheet> {
  late int _red;
  late int _green;
  late int _blue;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final argb = widget.initialColor.toARGB32();
    _red = (argb >> 16) & 0xff;
    _green = (argb >> 8) & 0xff;
    _blue = argb & 0xff;
  }

  Color get _color => Color.fromARGB(255, _red, _green, _blue);

  Future<void> _submit(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await action();
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
                widget.title,
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
                  if (widget.resetLabel != null && widget.onReset != null)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(widget.onReset!),
                      child: Text(widget.resetLabel!),
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
                        : () => _submit(() => widget.onSave(_color)),
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
