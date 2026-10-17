import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/domain/entities/song.dart';
import '../domain/entities/tag_draft.dart';
import '../domain/services/tag_editor_validator.dart';

class TagEditorService {
  TagEditorService(this._channel);

  final MethodChannel _channel;

  Future<void> save(Song song, TagDraft draft) async {
    final validationError = TagEditorValidator.validate(draft);
    if (validationError != null) {
      throw TagEditorValidationException(validationError);
    }
    final updated = await _channel.invokeMethod<bool>('updateSongTags', {
      'songId': song.id,
      ...draft.toJson(),
    });
    if (updated != true) throw const TagEditorSaveException();
    if (draft.lyrics.trim().isNotEmpty) {
      await _writeLyricsSidecar(song.path, draft.lyrics.trim());
    }
  }

  Future<void> _writeLyricsSidecar(String audioPath, String lyrics) async {
    final dot = audioPath.lastIndexOf('.');
    final base = dot > 0 ? audioPath.substring(0, dot) : audioPath;
    try {
      await File('$base.lrc').writeAsString(lyrics);
    } on FileSystemException catch (error) {
      throw TagEditorSaveException(error.toString());
    }
  }
}

class TagEditorValidationException implements Exception {
  const TagEditorValidationException(this.code);

  final String code;
}

class TagEditorSaveException implements Exception {
  const TagEditorSaveException([this.message]);

  final String? message;
}

final tagEditorServiceProvider = Provider<TagEditorService>(
  (ref) => TagEditorService(
    const MethodChannel('com.example.songs_cleaner/tag_editor'),
  ),
);
