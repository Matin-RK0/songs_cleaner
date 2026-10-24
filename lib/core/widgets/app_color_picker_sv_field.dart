import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_color_picker_tokens.dart';
import '../theme/app_radius.dart';

/// Pointer editing is complemented by the editor's accessible S/V sliders.
class AppColorPickerSvField extends StatelessWidget {
  const AppColorPickerSvField({
    super.key,
    required this.hsv,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color color;
  final bool enabled;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.colorFieldHint,
      image: true,
      // Mathematical x is saturation, intentionally LTR in every locale.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = (width / AppColorPickerTokens.fieldAspectRatio)
                .clamp(0.0, AppColorPickerTokens.fieldMaxHeight);
            final radius = AppColorPickerTokens.indicatorSize / 2;
            // Keep the entire indicator visible, including at S/V endpoints.
            final fieldWidth = (width - radius * 2).clamp(1.0, double.infinity);
            final fieldHeight = (height - radius * 2).clamp(
              1.0,
              double.infinity,
            );
            void update(Offset point) {
              onChanged(
                hsv
                    .withSaturation(
                      ((point.dx - radius) / fieldWidth).clamp(0.0, 1.0),
                    )
                    .withValue(
                      (1 - (point.dy - radius) / fieldHeight).clamp(0.0, 1.0),
                    ),
              );
            }

            return RepaintBoundary(
              child: GestureDetector(
                key: const ValueKey('color-picker-sv-field'),
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapUp: enabled
                    ? (details) => update(details.localPosition)
                    : null,
                onPanStart: enabled
                    ? (details) => update(details.localPosition)
                    : null,
                onPanUpdate: enabled
                    ? (details) => update(details.localPosition)
                    : null,
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        left: radius,
                        right: radius,
                        top: radius,
                        bottom: radius,
                        child: RepaintBoundary(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.md,
                              gradient: LinearGradient(
                                colors: [
                                  AppColorPickerTokens.white,
                                  HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                                ],
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.md,
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColorPickerTokens.transparent,
                                    AppColorPickerTokens.black,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: hsv.saturation * fieldWidth,
                        top: (1 - hsv.value) * fieldHeight,
                        child: IgnorePointer(
                          child: Container(
                            width: AppColorPickerTokens.indicatorSize,
                            height: AppColorPickerTokens.indicatorSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: AppColorPickerTokens.white,
                                width: AppColorPickerTokens.indicatorBorder,
                              ),
                            ),
                            foregroundDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColorPickerTokens.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
