import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../application/providers/lock_screen_controller.dart';
import '../../infrastructure/lock_screen_service.dart';

/// A separate hit-test layer keeps double-taps on controls out of this gesture.
class LockScreenBackground extends ConsumerStatefulWidget {
  const LockScreenBackground({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockScreenBackground> createState() =>
      _LockScreenBackgroundState();
}

class _LockScreenBackgroundState extends ConsumerState<LockScreenBackground> {
  bool _handling = false;

  Future<void> _onDoubleTap() async {
    if (_handling) return;
    _handling = true;
    try {
      final service = ref.read(lockScreenServiceProvider);
      final result = await service.lockScreen();
      if (!mounted) return;
      final l10n = context.l10n;
      switch (result) {
        case ScreenLockResult.locked:
          return;
        case ScreenLockResult.permissionRequired:
          final approved = await showAppConfirmDialog(
            context: context,
            title: l10n.screenLockAccessTitle,
            message: l10n.screenLockAccessMessage,
            confirmLabel: l10n.lockScreenPermissionAllow,
            cancelLabel: l10n.lockScreenPermissionNotNow,
          );
          if (!mounted || !approved) return;
          final opened = await service.requestScreenLockAccess();
          if (mounted && !opened) {
            showAppSnackBar(context, l10n.screenLockFailed, error: true);
          }
        case ScreenLockResult.unsupported:
          showAppSnackBar(context, l10n.screenLockUnsupported, error: true);
        case ScreenLockResult.failed:
          showAppSnackBar(context, l10n.screenLockFailed, error: true);
      }
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onDoubleTap: _onDoubleTap,
        ),
      ),
      widget.child,
    ],
  );
}
