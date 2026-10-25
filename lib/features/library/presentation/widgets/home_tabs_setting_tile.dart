import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/home_tab_settings.dart';
import '../../../../core/settings/home_tab_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../models/home_tab_presentation.dart';

class HomeTabsSettingTile extends ConsumerWidget {
  const HomeTabsSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(homeTabSettingsProvider);
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(Icons.tab_rounded, color: context.colors.primary),
      title: Text(l10n.homeTabsTitle),
      subtitle: Text(
        l10n.homeTabsDefaultSummary(settings.defaultTab.label(l10n)),
      ),
      trailing: const Icon(Icons.arrow_forward_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: context.colors.surfaceHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
        ),
        builder: (_) => const _HomeTabsSheet(),
      ),
    );
  }
}

class _HomeTabsSheet extends ConsumerStatefulWidget {
  const _HomeTabsSheet();

  @override
  ConsumerState<_HomeTabsSheet> createState() => _HomeTabsSheetState();
}

class _HomeTabsSheetState extends ConsumerState<_HomeTabsSheet> {
  late HomeTabSettings _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(homeTabSettingsProvider);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(homeTabSettingsProvider.notifier).save(_draft);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, context.l10n.actionFailedGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height:
              MediaQuery.sizeOf(context).height * AppSpacing.sheetHeightFactor,
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeTabsTitle, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.homeTabsDescription,
                  style: AppTypography.body.copyWith(color: colors.textMedium),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: RadioGroup<HomeTab>(
                    groupValue: _draft.defaultTab,
                    onChanged: (tab) {
                      if (!_saving && tab != null) {
                        setState(() => _draft = _draft.withDefault(tab));
                      }
                    },
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      itemCount: _draft.order.length,
                      onReorderItem: (oldIndex, newIndex) {
                        if (!_saving) {
                          setState(
                            () => _draft = _draft.reordered(oldIndex, newIndex),
                          );
                        }
                      },
                      itemBuilder: (context, index) {
                        final tab = _draft.order[index];
                        final selected = tab == _draft.defaultTab;
                        return Padding(
                          key: ValueKey(tab),
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material(
                            color: selected
                                ? colors.primary.withValues(alpha: 0.12)
                                : colors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.md,
                              side: BorderSide(
                                color: selected
                                    ? colors.primary
                                    : colors.outline,
                              ),
                            ),
                            child: ListTile(
                              enabled: !_saving,
                              contentPadding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.sm,
                                end: AppSpacing.sm,
                              ),
                              leading: Radio<HomeTab>(
                                value: tab,
                                enabled: !_saving,
                              ),
                              title: Row(
                                children: [
                                  Icon(tab.icon, color: colors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(child: Text(tab.label(l10n))),
                                ],
                              ),
                              subtitle: selected
                                  ? Text(l10n.homeTabsDefaultBadge)
                                  : null,
                              onTap: () => setState(
                                () => _draft = _draft.withDefault(tab),
                              ),
                              trailing: ReorderableDragStartListener(
                                index: index,
                                enabled: !_saving,
                                child: Tooltip(
                                  message: l10n.homeTabsDragHint,
                                  child: const SizedBox.square(
                                    dimension: AppSpacing.avatarSize,
                                    child: Icon(Icons.drag_handle_rounded),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(
                              () => _draft = const HomeTabSettings(),
                            ),
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(l10n.homeTabsReset),
                    ),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        _saving ? l10n.homeTabsSaving : l10n.saveAction,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
