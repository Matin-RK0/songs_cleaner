import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FolderPickerScreen extends StatefulWidget {
  const FolderPickerScreen({super.key, required this.initialPath});

  final String initialPath;

  @override
  State<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends State<FolderPickerScreen> {
  late Directory _directory;
  List<Directory> _children = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _directory = Directory(widget.initialPath);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final directories = await _directory
          .list(followLinks: false)
          .where((entity) => entity is Directory)
          .map((entity) => entity as Directory)
          .toList();
      directories.sort(
        (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _children = directories;
        _loading = false;
      });
    } on FileSystemException {
      if (!mounted) return;
      setState(() {
        _children = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.chooseFolderTitle),
      actions: [
        IconButton(
          tooltip: context.l10n.chooseThisFolder,
          icon: const Icon(Icons.check_rounded),
          onPressed: () => Navigator.of(context).pop(_directory.path),
        ),
      ],
    ),
    body: Stack(
      children: [
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: _loading
              ? const Center(
                  key: ValueKey('folder-loading'),
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  key: const ValueKey('folder-list'),
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: _children.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: context.colors.surfaceHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.lg,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.folder_open_rounded,
                              color: context.colors.primary,
                            ),
                            title: Text(
                              _directory.path.split(RegExp(r'[/\\]')).last,
                              style: AppTypography.listTitle.copyWith(
                                color: context.colors.textHigh,
                              ),
                            ),
                            subtitle: Text(_directory.path),
                          ),
                        ),
                      );
                    }
                    if (index == 1) {
                      final parent = _directory.parent;
                      return ListTile(
                        leading: const Icon(Icons.arrow_upward_rounded),
                        title: Text(context.l10n.parentFolder),
                        subtitle: Text(parent.path),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        onTap: () {
                          if (parent.path == _directory.path) return;
                          _directory = parent;
                          _load();
                        },
                      );
                    }
                    final child = _children[index - 2];
                    return ListTile(
                      leading: Icon(
                        Icons.folder_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(
                        child.path.split(RegExp(r'[/\\]')).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        child.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _directory = child;
                        _load();
                      },
                    );
                  },
                ),
        ),
        PositionedDirectional(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: AppSpacing.md,
          child: SafeArea(
            top: false,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pop(_directory.path),
              icon: const Icon(Icons.check_rounded),
              label: Text(context.l10n.chooseThisFolder),
            ),
          ),
        ),
      ],
    ),
  );
}
