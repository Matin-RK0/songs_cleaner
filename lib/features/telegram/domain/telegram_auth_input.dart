/// Converts common localized input without hiding invalid letters or symbols.
abstract final class TelegramAuthInput {
  static String phone(String value) => _digits(
    value,
  ).replaceAll(RegExp(r'[\s\u00a0\u200e\u200f\u202a\u202c()\-]'), '');

  static String code(String value) => _digits(value).trim();

  static String _digits(String value) => String.fromCharCodes(
    value.runes.map((rune) {
      if (rune >= 0x06f0 && rune <= 0x06f9) return rune - 0x06f0 + 0x30;
      if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
      return rune;
    }),
  );
}
