import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings_repository.dart';
import '../../library/domain/entities/song.dart';
import '../domain/entities/trash_entry.dart';
import '../infrastructure/trash_repository.dart';

final trashRepositoryProvider = Provider<TrashRepository>(
  (ref) => TrashRepository(ref.watch(sharedPreferencesProvider)),
);

final trashServiceProvider = Provider<TrashService>(
  (ref) => TrashService(ref.watch(trashRepositoryProvider)),
);

class TrashService {
  TrashService(this._repository);

  final TrashRepository _repository;

  List<TrashEntry> load() => _repository.load();

  Future<TrashEntry> moveToTrash(Song song) async {
    final source = File(song.path);
    if (!await source.exists()) throw const TrashOperationException();
    final directory = Directory(
      '${source.parent.path}${Platform.pathSeparator}.songs_cleaner_trash',
    );
    await directory.create(recursive: true);
    final id = '${song.id}_${DateTime.now().microsecondsSinceEpoch}';
    final trashPath = '${directory.path}${Platform.pathSeparator}$id';
    try {
      await source.rename(trashPath);
    } on FileSystemException {
      throw const TrashOperationException();
    }
    final entry = TrashEntry(
      id: id,
      songId: song.id,
      title: song.title,
      artist: song.artist,
      originalPath: song.path,
      trashPath: trashPath,
      deletedAt: DateTime.now(),
      sizeBytes: song.sizeBytes,
    );
    final entries = [..._repository.load(), entry];
    await _repository.save(entries);
    return entry;
  }

  Future<void> restore(TrashEntry entry) async {
    final source = File(entry.trashPath);
    final target = File(entry.originalPath);
    if (!await source.exists() || await target.exists()) {
      throw const TrashOperationException();
    }
    try {
      await source.rename(target.path);
    } on FileSystemException {
      throw const TrashOperationException();
    }
    await _removeEntry(entry.id);
  }

  Future<void> deletePermanently(TrashEntry entry) async {
    try {
      final file = File(entry.trashPath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      throw const TrashOperationException();
    }
    await _removeEntry(entry.id);
  }

  Future<void> empty() async {
    for (final entry in _repository.load()) {
      final file = File(entry.trashPath);
      if (await file.exists()) await file.delete();
    }
    await _repository.save(const []);
  }

  Future<void> _removeEntry(String id) async {
    await _repository.save(
      _repository.load().where((entry) => entry.id != id).toList(),
    );
  }
}

class TrashOperationException implements Exception {
  const TrashOperationException();
}
