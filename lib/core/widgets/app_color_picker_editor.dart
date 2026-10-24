import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_color_picker_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_color_picker_sv_field.dart';

class AppColorPickerEditor extends StatefulWidget {
  const AppColorPickerEditor({
    super.key,
    required this.initialColor,
    required this.enabled,
    required this.onChanged,
  });

  final Color initialColor;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  @override
  State<AppColorPickerEditor> createState() => _AppColorPickerEditorState();
}

class _AppColorPickerEditorState extends State<AppColorPickerEditor> {
  late final Color _before;
  late Color _color;
  late HSVColor _hsv;
  bool _fineAdjustments = false;

  @override
  void initState() {
    super.initState();
    _before = _color = widget.initialColor;
    _hsv = HSVColor.fromColor(_color);
  }

  void _adjust(HSVColor hsv) {
    if (!widget.enabled || hsv == _hsv) return;
    setState(() {
      _hsv = hsv;
      _color = hsv.toColor();
    });
    widget.onChanged(_color);
  }

  void _select(Color color) {
    if (!widget.enabled) return;
    final hsv = HSVColor.fromColor(color);
    setState(() {
      // Achromatic swatches have no hue; retain the user's chosen hue.
      _hsv = hsv.saturation == 0 ? hsv.withHue(_hsv.hue) : hsv;
      _color = color;
    });
    widget.onChanged(_color);
  }

  String _hex(Color color) =>
      '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _preview(l10n.colorBefore, _before)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _preview(l10n.colorAfter, _color)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _hex(_color),
          key: const ValueKey('color-picker-hex'),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: AppTypography.sectionTitle.copyWith(color: colors.textHigh),
        ),
        const SizedBox(height: AppSpacing.md),
        AppColorPickerSvField(
          hsv: _hsv,
          color: _color,
          enabled: widget.enabled,
          onChanged: _adjust,
        ),
        const SizedBox(height: AppSpacing.md),
        _slider(
          label: l10n.colorHue,
          value: _hsv.hue,
          max: 360,
          onChanged: (value) => _adjust(_hsv.withHue(value)),
          hue: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.colorSuggested,
          style: AppTypography.sectionTitle.copyWith(color: colors.textHigh),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final color in AppColorPickerTokens.palette) _swatch(color),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            expanded: _fineAdjustments,
            child: TextButton.icon(
              key: const ValueKey('color-picker-fine-adjustments'),
              onPressed: widget.enabled
                  ? () => setState(() => _fineAdjustments = !_fineAdjustments)
                  : null,
              icon: Icon(
                _fineAdjustments ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(l10n.colorFineAdjustments),
            ),
          ),
        ),
        if (_fineAdjustments) ...[
          _slider(
            key: const ValueKey('color-picker-saturation'),
            label: l10n.colorSaturation,
            value: _hsv.saturation * 100,
            max: 100,
            onChanged: (value) => _adjust(_hsv.withSaturation(value / 100)),
          ),
          _slider(
            key: const ValueKey('color-picker-brightness'),
            label: l10n.colorBrightness,
            value: _hsv.value * 100,
            max: 100,
            onChanged: (value) => _adjust(_hsv.withValue(value / 100)),
          ),
        ],
      ],
    );
  }

  Widget _preview(String label, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: AppTypography.caption.copyWith(color: context.colors.textMedium),
      ),
      const SizedBox(height: AppSpacing.xs),
      Semantics(
        label: '$label ${_hex(color)}',
        child: Container(
          height: AppColorPickerTokens.previewHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.md,
            border: Border.all(color: context.colors.outline),
          ),
        ),
      ),
    ],
  );

  Widget _swatch(Color color) {
    final selected = color.toARGB32() == _color.toARGB32();
    final ink = color.computeLuminance() > 0.5
        ? AppColorPickerTokens.black
        : AppColorPickerTokens.white;
    return Semantics(
      selected: selected,
      label: context.l10n.colorChoice(_hex(color)),
      child: IconButton(
        key: ValueKey(
          'color-picker-swatch-${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
        ),
        tooltip: context.l10n.colorChoice(_hex(color)),
        onPressed: widget.enabled ? () => _select(color) : null,
        style: IconButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: ink,
          minimumSize: const Size.square(AppColorPickerTokens.swatchSize),
          side: BorderSide(color: context.colors.outline),
        ),
        icon: Icon(selected ? Icons.check_rounded : null),
      ),
    );
  }

  Widget _slider({
    Key? key,
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    bool hue = false,
  }) {
    final number = MaterialLocalizations.of(
      context,
    ).formatDecimal(value.round());
    final display = hue
        ? context.l10n.colorDegrees(number)
        : context.l10n.colorPercent(number);
    final slider = Semantics(
      label: label,
      child: Slider(
        key: hue ? const ValueKey('color-picker-hue') : key,
        value: value,
        max: max,
        divisions: max.toInt(),
        label: display,
        semanticFormatterCallback: (value) {
          final number = MaterialLocalizations.of(
            context,
          ).formatDecimal(value.round());
          return hue
              ? context.l10n.colorDegrees(number)
              : context.l10n.colorPercent(number);
        },
        onChanged: widget.enabled ? onChanged : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$label: $display',
          style: AppTypography.body.copyWith(color: context.colors.textHigh),
        ),
        if (hue)
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColorPickerTokens.hueTrackInset,
                ),
                child: Container(
                  height: AppColorPickerTokens.hueTrackHeight,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.md,
                    gradient: LinearGradient(
                      colors: Directionality.of(context) == TextDirection.rtl
                          ? AppColorPickerTokens.rainbow.reversed.toList()
                          : AppColorPickerTokens.rainbow,
                    ),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColorPickerTokens.hueTrackInset,
                    vertical: AppSpacing.md,
                  ),
                  activeTrackColor: AppColorPickerTokens.transparent,
                  inactiveTrackColor: AppColorPickerTokens.transparent,
                  disabledActiveTrackColor: AppColorPickerTokens.transparent,
                  disabledInactiveTrackColor: AppColorPickerTokens.transparent,
                  secondaryActiveTrackColor: AppColorPickerTokens.transparent,
                  activeTickMarkColor: AppColorPickerTokens.transparent,
                  inactiveTickMarkColor: AppColorPickerTokens.transparent,
                  disabledActiveTickMarkColor: AppColorPickerTokens.transparent,
                  disabledInactiveTickMarkColor:
                      AppColorPickerTokens.transparent,
                  trackGap: 0,
                ),
                child: slider,
              ),
            ],
          )
        else
          slider,
      ],
    );
  }
}
