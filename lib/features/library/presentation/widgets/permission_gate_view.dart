import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_views.dart';

/// Explains the required media permission and offers to grant it.
class PermissionGateView extends ConsumerWidget {
  const PermissionGateView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyState(
              icon: Icons.folder_shared_outlined,
              title: l10n.permissionTitle,
              message: l10n.permissionAudioMessage,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryActionButton(
              label: l10n.grantPermission,
              icon: Icons.key_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
