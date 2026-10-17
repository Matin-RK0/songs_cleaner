import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';

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
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: _children.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
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
              final child = _children[index - 1];
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(child.path.split(RegExp(r'[/\\]')).last),
                subtitle: Text(child.path),
                onTap: () {
                  _directory = child;
                  _load();
                },
              );
            },
          ),
  );
}
