import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_motion.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedStateIcon(icon: icon),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle.copyWith(
                color: colors.textHigh,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.textMedium),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : PrimaryActionButton(
              label: context.l10n.retry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
    );
  }
}

class _AnimatedStateIcon extends StatefulWidget {
  const _AnimatedStateIcon({required this.icon});

  final IconData icon;

  @override
  State<_AnimatedStateIcon> createState() => _AnimatedStateIconState();
}

class _AnimatedStateIconState extends State<_AnimatedStateIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(_fade);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: ShapeDecoration(
            color: context.colors.surfaceHigh,
            shape: const CircleBorder(),
          ),
          child: Icon(widget.icon, size: 32, color: context.colors.textLow),
        ),
      ),
    ),
  );
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final background = destructive
        ? context.colors.danger
        : context.colors.primary;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: context.colors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        elevation: 0,
        textStyle: AppTypography.buttonLabel,
      ),
    );
  }
}
