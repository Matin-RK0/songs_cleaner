import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/lyrics/domain/services/lrc_parser.dart';

void main() {
  test('parses and sorts millisecond timestamps', () {
    final lines = LrcParser.parse(
      '[00:10.50]Second\n[00:01.250]First\n[bad]Ignored',
    );

    expect(lines, hasLength(2));
    expect(lines.first.text, 'First');
    expect(
      lines.first.timestamp,
      const Duration(seconds: 1, milliseconds: 250),
    );
    expect(
      lines.last.timestamp,
      const Duration(seconds: 10, milliseconds: 500),
    );
  });

  test('supports multiple timestamp tags on one lyric line', () {
    final lines = LrcParser.parse('[00:01.00][00:03.00]Shared');

    expect(lines.map((line) => line.timestamp.inSeconds), [1, 3]);
    expect(lines.every((line) => line.text == 'Shared'), isTrue);
  });
}
