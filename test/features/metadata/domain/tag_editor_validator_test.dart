import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/metadata/domain/entities/tag_draft.dart';
import 'package:songs_cleaner/features/metadata/domain/services/tag_editor_validator.dart';

void main() {
  TagDraft draft({String title = 'Song', int track = 1}) => TagDraft(
    title: title,
    artist: 'Artist',
    album: 'Album',
    genre: 'Rock',
    composer: '',
    trackNumber: track,
    lyrics: '',
  );

  test('requires a non-empty title', () {
    expect(TagEditorValidator.validate(draft(title: '')), 'titleRequired');
  });

  test('rejects an invalid track number', () {
    expect(
      TagEditorValidator.validate(draft(track: 1000)),
      'trackNumberInvalid',
    );
  });

  test('accepts a valid draft', () {
    expect(TagEditorValidator.validate(draft()), isNull);
  });
}
