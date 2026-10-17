abstract final class FileNameValidator {
  static String? validate(String value, {required String extension}) {
    final name = value.trim();
    if (name.isEmpty) return 'fileNameRequired';
    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) return 'fileNameInvalid';
    if (name == '.' || name == '..') return 'fileNameInvalid';
    final lower = name.toLowerCase();
    if (lower.endsWith('.$extension'.toLowerCase())) return null;
    if (name.contains('.')) return 'fileExtensionCannotChange';
    return null;
  }

  static String withExtension(String value, String extension) {
    final name = value.trim();
    return name.toLowerCase().endsWith('.${extension.toLowerCase()}')
        ? name
        : '$name.$extension';
  }
}
