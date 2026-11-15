import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../library/domain/entities/song.dart';

/// Full-width destructive action using Flutter's standard 500ms long press.
/// Shared by the player screen and the lock-screen player.
class DeleteCurrentButton extends ConsumerStatefulWidget {
  const DeleteCurrentButton({super.key, required this.song});

  final Song song;

  @override
  ConsumerState<DeleteCurrentButton> createState() =>
      _DeleteCurrentButtonState();
}

class _DeleteCurrentButtonState extends ConsumerState<DeleteCurrentButton>
    with SingleTickerProviderStateMixin {
  bool _deleting = false;
  late final AnimationController _hold;
  int? _pointer;
  Offset? _origin;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: AppMotion.holdToDelete);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) _cancelHold();
  }

  void _startHold(PointerDownEvent event) {
    if (!mounted || _deleting || _pointer != null) return;
    _pointer = event.pointer;
    _origin = event.position;
    if (MediaQuery.disableAnimationsOf(context)) {
      _hold.value = 0.5;
    } else {
      _hold.forward(from: 0);
    }
  }

  void _moveHold(PointerMoveEvent event) {
    if (event.pointer != _pointer || _origin == null) return;
    if ((event.position - _origin!).distance > kTouchSlop) _cancelHold();
  }

  void _endHold(PointerEvent event) {
    if (event.pointer == _pointer) _cancelHold();
  }

  void _cancelHold() {
    if (!mounted) return;
    _pointer = null;
    _origin = null;
    if (!_deleting) _hold.reset();
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!mounted ||
        _deleting ||
        !TickerMode.valuesOf(context).enabled ||
        !(ModalRoute.isCurrentOf(context) ?? true)) {
      return;
    }
    setState(() => _deleting = true);
    _hold.value = 1;
    try {
      await deleteSongFlow(context, ref, widget.song, useTrash: false);
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
        _cancelHold();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: Listener(
          onPointerDown: _startHold,
          onPointerMove: _moveHold,
          onPointerUp: _endHold,
          onPointerCancel: _endHold,
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.md,
                    child: AnimatedBuilder(
                      animation: _hold,
                      child: ColoredBox(
                        color: colors.primary.withValues(alpha: 0.28),
                      ),
                      builder: (_, child) => Transform.scale(
                        scaleX: _hold.value,
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      foregroundColor: colors.primary,
                      disabledBackgroundColor: colors.primary.withValues(
                        alpha: 0.12,
                      ),
                      disabledForegroundColor: colors.primary.withValues(
                        alpha: 0.65,
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.45),
                      ),
                      textStyle: AppTypography.emphasisTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // No tap action: the framework cancels a hold on release or drag.
                    onPressed: null,
                    onLongPress: _deleting ? null : _delete,
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      size: AppPlayerMetrics.icon,
                    ),
                    label: Text(l10n.holdToDeleteAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
