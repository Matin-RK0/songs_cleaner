import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
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

class _DeleteCurrentButtonState extends ConsumerState<DeleteCurrentButton> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await deleteSongFlow(context, ref, widget.song, useTrash: false);
    } finally {
      if (mounted) setState(() => _deleting = false);
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
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger.withValues(alpha: 0.16),
            foregroundColor: colors.danger,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            side: BorderSide(color: colors.danger.withValues(alpha: 0.45)),
            textStyle: AppTypography.emphasisTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          // No tap action: the framework cancels a hold on release or drag.
          onPressed: null,
          onLongPress: _deleting ? null : _delete,
          icon: const Icon(Icons.delete_forever_rounded, size: 22),
          label: Text(l10n.holdToDeleteAction),
        ),
      ),
    );
  }
}
