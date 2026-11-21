/// Maps each visible initial to its first row, in the list's display order.
Map<String, int> buildAlphabetIndex(Iterable<String> sortedLabels) {
  final initials = <String, int>{};
  var index = 0;
  for (final label in sortedLabels) {
    final trimmed = label.trimLeft();
    final first = trimmed.isEmpty
        ? ''
        : String.fromCharCode(trimmed.runes.first);
    final letter = switch (first) {
      'آ' || 'أ' || 'إ' || 'ٱ' => 'ا',
      'ي' || 'ى' => 'ی',
      'ك' => 'ک',
      _ when _letter.hasMatch(first) => first.toUpperCase(),
      _ => '#',
    };
    initials.putIfAbsent(letter, () => index);
    index++;
  }
  return Map.unmodifiable(initials);
}

final _letter = RegExp(r'^\p{L}$', unicode: true);
