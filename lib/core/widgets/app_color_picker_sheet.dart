import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_color_picker_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_color_picker_editor.dart';

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
  late Color _draft;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _draft = Color(widget.initialColor.toARGB32() | 0xff000000);
  }

  Future<void> _submit(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _saving = false);
      // PopScope must rebuild before the successful programmatic pop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
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
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppColorPickerTokens.maxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: AppTypography.sheetTitle.copyWith(
                          color: colors.textHigh,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: AppColorPickerEditor(
                        initialColor: _draft,
                        enabled: !_saving,
                        onChanged: (color) => _draft = color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_failed) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l10n.errorLoadFailedMessage,
                              style: AppTypography.body.copyWith(
                                color: colors.danger,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    AppColorPickerTokens.actionMinHeight,
                                  ),
                                ),
                                onPressed: _saving
                                    ? null
                                    : () =>
                                          _submit(() => widget.onSave(_draft)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_saving) ...[
                                      SizedBox.square(
                                        dimension:
                                            AppColorPickerTokens.progressSize,
                                        child: CircularProgressIndicator(
                                          color: colors.onPrimary,
                                          strokeWidth: AppColorPickerTokens
                                              .progressStroke,
                                          semanticsLabel: l10n.saveAction,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                    Flexible(child: Text(l10n.saveAction)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.textHigh,
                                  backgroundColor: colors.surfaceHigh,
                                  minimumSize: const Size.fromHeight(
                                    AppColorPickerTokens.actionMinHeight,
                                  ),
                                  padding: AppSpacing.hMdVSm,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.md,
                                  ),
                                  textStyle: AppTypography.buttonLabel,
                                ),
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(l10n.cancel),
                              ),
                            ),
                          ],
                        ),
                        if (widget.resetLabel != null &&
                            widget.onReset != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textMedium,
                              minimumSize: const Size.fromHeight(
                                AppColorPickerTokens.actionMinHeight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md,
                              ),
                              textStyle: AppTypography.buttonLabel,
                            ),
                            onPressed: _saving
                                ? null
                                : () => _submit(widget.onReset!),
                            child: Text(widget.resetLabel!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
