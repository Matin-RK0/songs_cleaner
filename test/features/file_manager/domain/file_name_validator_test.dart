import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/file_manager/domain/services/file_name_validator.dart';

void main() {
  test('keeps the original extension when omitted', () {
    expect(FileNameValidator.withExtension('New name', 'mp3'), 'New name.mp3');
    expect(
      FileNameValidator.withExtension('New name.MP3', 'mp3'),
      'New name.MP3',
    );
  });

  test('rejects invalid names and extension changes', () {
    expect(
      FileNameValidator.validate('bad/name', extension: 'mp3'),
      'fileNameInvalid',
    );
    expect(
      FileNameValidator.validate('song.flac', extension: 'mp3'),
      'fileExtensionCannotChange',
    );
  });

  test('accepts a clean base filename', () {
    expect(FileNameValidator.validate('New song', extension: 'mp3'), isNull);
  });
}
