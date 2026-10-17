import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/library/domain/entities/song.dart';
import '../domain/services/file_name_validator.dart';

final fileManagerServiceProvider = Provider<FileManagerService>(
  (ref) => FileManagerService(),
);

class FileManagerService {
  Future<void> rename(Song song, String requestedName) async {
    final extension = _extension(song.path);
    final validation = FileNameValidator.validate(
      requestedName,
      extension: extension,
    );
    if (validation != null) throw FileManagerValidationException(validation);

    final directory = File(song.path).parent.path;
    final targetName = FileNameValidator.withExtension(
      requestedName,
      extension,
    );
    final target = File('$directory${Platform.pathSeparator}$targetName');
    if (target.path != song.path && await target.exists()) {
      throw const FileManagerValidationException('fileAlreadyExists');
    }
    try {
      await File(song.path).rename(target.path);
    } on FileSystemException catch (_) {
      throw const FileManagerOperationException();
    }
  }

  Future<void> copy(Song song, String destinationDirectory) async {
    final target = await _target(song, destinationDirectory);
    try {
      await File(song.path).copy(target.path);
    } on FileSystemException {
      throw const FileManagerOperationException();
    }
  }

  Future<void> move(Song song, String destinationDirectory) async {
    final target = await _target(song, destinationDirectory);
    try {
      await File(song.path).rename(target.path);
    } on FileSystemException {
      throw const FileManagerOperationException();
    }
  }

  Future<File> _target(Song song, String destinationDirectory) async {
    final directory = Directory(destinationDirectory);
    if (!await directory.exists()) {
      throw const FileManagerOperationException();
    }
    final fileName = song.path.split(RegExp(r'[/\\]')).last;
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');
    if (target.path == song.path || await target.exists()) {
      throw const FileManagerValidationException('fileAlreadyExists');
    }
    return target;
  }

  String _extension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }
}

class FileManagerValidationException implements Exception {
  const FileManagerValidationException(this.code);

  final String code;
}

class FileManagerOperationException implements Exception {
  const FileManagerOperationException();
}
