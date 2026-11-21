import 'package:material_ui/material_ui.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

void jumpToListRow(ScrollController controller, double offset) {
  if (controller.positions.length != 1 ||
      !controller.position.hasContentDimensions) {
    return;
  }
  final position = controller.position;
  controller.jumpTo(
    offset.clamp(position.minScrollExtent, position.maxScrollExtent),
  );
}

/// Touch or drag along the index to jump across a fixed-extent list.
class AlphabetIndexRail extends StatefulWidget {
  const AlphabetIndexRail({
    super.key,
    required this.index,
    required this.onJump,
    this.bottomInset = 0,
  });

  static const width = AppSpacing.xl + AppSpacing.xs * 2;

  final Map<String, int> index;
  final ValueChanged<int> onJump;
  final double bottomInset;

  @override
  State<AlphabetIndexRail> createState() => _AlphabetIndexRailState();
}

class _AlphabetIndexRailState extends State<AlphabetIndexRail> {
  String? _active;

  void _jump(String label) {
    if (_active == label) return;
    setState(() => _active = label);
    widget.onJump(widget.index[label]!);
  }

  void _release() {
    if (_active != null) setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index.length < 2) return const SizedBox.shrink();
    final labels = widget.index.keys.toList(growable: false);
    final colors = context.colors;
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          end: AppSpacing.xs,
          bottom: widget.bottomInset,
        ),
        child: SizedBox(
          width: AlphabetIndexRail.width - AppSpacing.xs,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = (labels.length * AppSpacing.lg).clamp(
                  0.0,
                  constraints.maxHeight,
                );
                if (height <= 0) return const SizedBox.shrink();
                void jumpAt(double y) => _jump(
                  labels[(y / height * labels.length).floor().clamp(
                    0,
                    labels.length - 1,
                  )],
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onVerticalDragDown: (event) => jumpAt(event.localPosition.dy),
                  onVerticalDragUpdate: (event) =>
                      jumpAt(event.localPosition.dy),
                  onVerticalDragEnd: (_) => _release(),
                  onVerticalDragCancel: _release,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: colors.surfaceHigh,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final label in labels)
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: context.l10n.alphabetJumpTo(label),
                              onTap: () {
                                _jump(label);
                                _release();
                              },
                              child: ExcludeSemantics(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _active == label
                                        ? colors.primary.withValues(alpha: 0.18)
                                        : null,
                                    borderRadius: AppRadius.pill,
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        label,
                                        style: AppTypography.captionSmall
                                            .copyWith(
                                              color: _active == label
                                                  ? colors.primary
                                                  : colors.textMedium,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
