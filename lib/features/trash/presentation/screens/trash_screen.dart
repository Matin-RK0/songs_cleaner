import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../library/application/providers/library_controller.dart';
import '../../application/trash_service.dart';
import '../../domain/entities/trash_entry.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  late List<TrashEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = ref.read(trashServiceProvider).load().reversed.toList();
  }

  Future<void> _restore(TrashEntry entry) async {
    try {
      await ref.read(trashServiceProvider).restore(entry);
      await ref.read(libraryProvider.notifier).refresh();
      if (!mounted) return;
      setState(() => _entries.removeWhere((item) => item.id == entry.id));
      showAppSnackBar(context, context.l10n.trashRestoredToast);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, context.l10n.trashRestoreFailed, error: true);
      }
    }
  }

  Future<void> _deletePermanently(TrashEntry entry) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.deletePermanentlyAction,
      message: context.l10n.trashPermanentDeleteWarning,
      confirmLabel: context.l10n.deletePermanentlyAction,
      cancelLabel: context.l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(trashServiceProvider).deletePermanently(entry);
      if (!mounted) return;
      setState(() => _entries.removeWhere((item) => item.id == entry.id));
      showAppSnackBar(context, context.l10n.trashDeletedToast);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          context.l10n.songDeleteFailedGeneric,
          error: true,
        );
      }
    }
  }

  Future<void> _empty() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.emptyTrashAction,
      message: context.l10n.trashEmptyWarning,
      confirmLabel: context.l10n.emptyTrashAction,
      cancelLabel: context.l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(trashServiceProvider).empty();
      if (mounted) setState(() => _entries.clear());
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          context.l10n.songDeleteFailedGeneric,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trashTitle),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              tooltip: l10n.emptyTrashAction,
              onPressed: _empty,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(child: Text(l10n.trashEmpty))
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  title: Text(entry.title),
                  subtitle: Text(entry.artist),
                  leading: const Icon(Icons.delete_sweep_outlined),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => value == 'restore'
                        ? _restore(entry)
                        : _deletePermanently(entry),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(l10n.restoreAction),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deletePermanentlyAction),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
